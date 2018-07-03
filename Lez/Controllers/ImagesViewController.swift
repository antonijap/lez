//
//  ImagesViewController.swift
//  Lez
//
//  Created by Antonija on 12/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Alertift
import Firebase
import Promises
import JGProgressHUD
import Alamofire

final class ImagesViewController: UIViewController {

    let imageViewOne = UIImageView()
    let imageViewTwo = UIImageView()
    let imageViewThree = UIImageView()
    let imageViewFour = UIImageView()
    let imagePickerOne = UIImagePickerController()
    let imagePickerTwo = UIImagePickerController()
    let imagePickerThree = UIImagePickerController()
    let imagePickerFour = UIImagePickerController()
    let storage = Storage.storage()
    let hud = JGProgressHUD(style: .dark)
    var imageViews: [UIImageView] = []
    var imageNames: [String] = []
    var activeImage = ""
    var dataForNewUser: [String: Any]?
    var user: User?
    var profileViewControllerDelegate: ProfileViewControllerDelegate?
    var matchViewControllerDelegate: MatchViewControllerDelegate?
    var data: [String : Any]?
    private var selectedImages: [UIImage] = []
    private var selectedImagesDict: Dictionary<Int, UIImage> = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        view.backgroundColor = .white
        navigationItem.title = "Image Gallery"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()

        if let user = user {
            // Now in editing mode
            // Load all images
            self.user = user
            let images = user.images
            for image in images {
                for imageView in imageViews {
                    if imageView.image == #imageLiteral(resourceName: "Empty_Image") {
                        imageView.sd_setImage(with: URL(string: image.url)) { downloadedImage, error, cacheYype, url in
                            guard let downloadedImage = downloadedImage else { return }
                            self.selectedImages.append(downloadedImage)
                        }
                        imageView.contentMode = .scaleAspectFill
                        break
                    }
                }
            }
        }
    }

    private func getAllImages() -> [UIImageView] {
        var filledImageViews: [UIImageView] = []
        for imageView in imageViews {
            if imageView.image != #imageLiteral(resourceName: "Empty_Image") { filledImageViews.append(imageView) }
        }
        return filledImageViews
    }

    private func uploadImages() {
        guard !selectedImagesDict.isEmpty else {
            Alertift.alert(title: "No images", message: "Every profile has at least one image. It's mandatory.")
                .action(.default("Okay"))
                .show(on: self) { self.stopSpinner(); return }
            return
        }
        guard let user = self.user else {
            // If there is no user, add new, that means we are in onboarding
            guard let user = Auth.auth().currentUser else { return }
            guard let data = self.data else { return }
            FirestoreManager.shared.addUser(uid: user.uid, data: data).then({ [weak self] success in
                guard success else { return }
                guard let strongSelf = self else { return }

                strongSelf.startSpinner()
                let group = DispatchGroup()

                for (_, image) in strongSelf.selectedImagesDict {
                    group.enter()
                    strongSelf.uploadImage(image: image).then { name in
                        strongSelf.imageNames.append(name)
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": strongSelf.imageNames, "isOnboarded": true]).then({ _ in
                        strongSelf.stopSpinner()
                        strongSelf.showOkayModal(messageTitle: "Profile Setup Completed", messageAlert: "Enjoy Lez and remember to report users who don't belong here.", messageBoxStyle: .alert, alertActionStyle: .default) {
                            strongSelf.matchViewControllerDelegate?.fetchUsers(for: user.uid)
                            strongSelf.dismiss(animated: true) {
                                NotificationCenter.default.post(name: Notification.Name("RefreshTableView"), object: nil)
                                FirestoreManager.shared.fetchUser(uid: user.uid).then({ user in
                                    AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userRegistered, user: user)
                                })
                            }
                        }
                    })
                }
            })
            return
        }

        startSpinner()
        let group = DispatchGroup()

        // Existing users, while editing
        // Delete images and then upload new
        deleteImages(url: user.images).then { [weak self] success in
            guard let strongSelf = self else { return }
            if success {
                for (_, image) in strongSelf.selectedImagesDict {
                    group.enter()
                    strongSelf.uploadImage(image: image).then { name in
                        strongSelf.imageNames.append(name)
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": strongSelf.imageNames]).then({ success in
                        strongSelf.stopSpinner()
                        strongSelf.profileViewControllerDelegate?.refreshProfile()
                        strongSelf.navigationController?.popToRootViewController(animated: true)
                    })
                }
            }
        }
    }

    func compressImage(image: UIImage) -> Data? {
        // Reducing file size to a 10th
        var actualHeight: CGFloat = image.size.height
        var actualWidth: CGFloat = image.size.width
        let maxHeight: CGFloat = 1136.0
        let maxWidth: CGFloat = 640.0
        var imgRatio: CGFloat = actualWidth/actualHeight
        let maxRatio: CGFloat = maxWidth/maxHeight
        var compressionQuality: CGFloat = 0.5
        
        if (actualHeight > maxHeight || actualWidth > maxWidth) {
            if imgRatio < maxRatio { //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if imgRatio > maxRatio { //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }

        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        guard let imageData = UIImageJPEGRepresentation(img, compressionQuality) else { return nil }
        return imageData
    }

    private func uploadImage(image: UIImage) -> Promise<String> {
        return Promise { fulfill, reject in
            guard let user = Auth.auth().currentUser else { return }
            let ref = self.storage.reference().child("images").child(user.uid).child("\(String.random()).jpg")
            let optimisedImage = self.compressImage(image: image)
            guard let data = optimisedImage else { print("Error with optimising image."); return }
            ref.putData(data, metadata: nil) { metadata, error in
                if let error = error { print(error) }
                guard let metadata = metadata else { print("Problem with metadata."); return }
                fulfill(metadata.name!)
            }
        }
    }

    private func deleteImages(url: [LezImage]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            if let user = self.user {
                let group = DispatchGroup()
                for image in user.images {
                    group.enter()
                    let ref = self.storage.reference().child("images").child(user.uid).child(image.name)
                    print(ref.fullPath)
                    ref.delete { error in
                        if let error = error {
                            print(error.localizedDescription)
                            reject(error)
                        } else {
                            print("Image deleted succesfully.")
                            group.leave()
                        }
                    }
                }
                group.notify(queue: .main) { fulfill(true) }
            } else {
                fulfill(false)
            }
        }
    }

    @objc private func openImageGallery(_ sender: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            Alertift.actionSheet(message: nil)
                .actions(["Choose Image", "Remove"])
                .action(.cancel("Cancel"))
                .finally { action, index in
                    if action.style == .cancel { return }
                    if index == 0 {
                        guard let view = sender.view else { return }
                        if view.tag == 0 {
                            self.present(self.imagePickerOne, animated: true) { self.activeImage = "imageViewOne" }
                        } else if view.tag == 1 {
                            self.present(self.imagePickerTwo, animated: true) { self.activeImage = "imageViewTwo" }
                        } else if view.tag == 2 {
                            self.present(self.imagePickerThree, animated: true) { self.activeImage = "imageViewThree" }
                        } else if view.tag == 3 {
                            self.present(self.imagePickerFour, animated: true) { self.activeImage = "imageViewFour" }
                        }
                    }
                    if index == 1 {
                        guard let view = sender.view else { return }
                        if view.tag == 0 {
                            self.imageViewOne.image = #imageLiteral(resourceName: "Empty_Image")
                            self.imageViewOne.contentMode = .center
//                            self.selectedImages.remove(at: 0)
                            self.selectedImagesDict.removeValue(forKey: 1)
                        } else if view.tag == 1 {
                            self.imageViewTwo.image = #imageLiteral(resourceName: "Empty_Image")
                            self.imageViewTwo.contentMode = .center
//                            self.selectedImages.remove(at: 1)
                            self.selectedImagesDict.removeValue(forKey: 2)
                        } else if view.tag == 2 {
                            self.imageViewThree.image = #imageLiteral(resourceName: "Empty_Image")
                            self.imageViewThree.contentMode = .center
//                            self.selectedImages.remove(at: 2)
                            self.selectedImagesDict.removeValue(forKey: 3)
                        } else if view.tag == 3 {
                            self.imageViewFour.image = #imageLiteral(resourceName: "Empty_Image")
                            self.imageViewFour.contentMode = .center
//                            self.selectedImages.remove(at: 3)
                            self.selectedImagesDict.removeValue(forKey: 4)
                        }
                    }
                }
                .show(on: self)
        }
    }

    @objc private func finishTapped() {
        uploadImages()
    }
}

extension ImagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            print("Something went wrong."); self.dismiss(animated: true) ;return
        }
        if activeImage == "imageViewOne" {
            imageViewOne.image = image
            imageViewOne.contentMode = .scaleAspectFill
            selectedImagesDict[1] = image
        }
        if activeImage == "imageViewTwo" {
            imageViewTwo.image = image
            imageViewTwo.contentMode = .scaleAspectFill
            selectedImagesDict[2] = image
        }
        if activeImage == "imageViewThree" {
            imageViewThree.image = image
            imageViewThree.contentMode = .scaleAspectFill
            selectedImagesDict[3] = image
        }
        if activeImage == "imageViewFour" {
            imageViewFour.image = image
            imageViewFour.contentMode = .scaleAspectFill
            selectedImagesDict[4] = image
        }
        selectedImages.append(image)
        self.dismiss(animated: true)
    }
}

extension ImagesViewController {
    private func setupInterface() {
        let width = 2.4
        view.addSubview(imageViewOne)
        imageViewOne.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(24)
            make.leading.equalToSuperview().inset(24)
        }
        imageViewOne.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewOne.clipsToBounds = true
        imageViewOne.layer.cornerRadius = 8
        imageViewOne.contentMode = .center
        imageViewOne.image = #imageLiteral(resourceName: "Empty_Image")
        
        view.addSubview(imageViewTwo)
        imageViewTwo.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViewOne.snp.top)
            make.trailing.equalToSuperview().offset(-24)
        }
        imageViewTwo.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewTwo.clipsToBounds = true
        imageViewTwo.layer.cornerRadius = 8
        imageViewTwo.contentMode = .center
        imageViewTwo.image = #imageLiteral(resourceName: "Empty_Image")

        view.addSubview(imageViewThree)
        imageViewThree.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViewOne.snp.bottom).offset(16)
            make.leading.equalTo(imageViewOne.snp.leading)
        }
        imageViewThree.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewThree.clipsToBounds = true
        imageViewThree.layer.cornerRadius = 8
        imageViewThree.contentMode = .center
        imageViewThree.image = #imageLiteral(resourceName: "Empty_Image")

        view.addSubview(imageViewFour)
        imageViewFour.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViewThree.snp.top)
            make.trailing.equalTo(imageViewTwo.snp.trailing)
        }
        imageViewFour.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewFour.clipsToBounds = true
        imageViewFour.layer.cornerRadius = 8
        imageViewFour.contentMode = .center
        imageViewFour.image = #imageLiteral(resourceName: "Empty_Image")

        imageViews.append(imageViewOne)
        imageViews.append(imageViewTwo)
        imageViews.append(imageViewThree)
        imageViews.append(imageViewFour)

        var index = 0
        for imageView in imageViews {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openImageGallery(_:)))
            imageView.addGestureRecognizer(tapGestureRecognizer)
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            index = index + 1
        }

        imagePickerOne.delegate = self
        imagePickerOne.sourceType = .savedPhotosAlbum
        imagePickerOne.allowsEditing = false

        imagePickerTwo.delegate = self
        imagePickerTwo.sourceType = .savedPhotosAlbum
        imagePickerTwo.allowsEditing = false

        imagePickerThree.delegate = self
        imagePickerThree.sourceType = .savedPhotosAlbum
        imagePickerThree.allowsEditing = false

        imagePickerFour.delegate = self
        imagePickerFour.sourceType = .savedPhotosAlbum
        imagePickerFour.allowsEditing = false

        let button = CustomButton()
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.finishTapped))
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(32)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(24)
            make.centerX.equalToSuperview()
        }
        button.setTitle("Done", for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        button.addGestureRecognizer(buttonTap)
    }

    private func startSpinner() {
        hud.textLabel.text = "Uploading. Please wait."
        hud.vibrancyEnabled = true
        hud.interactionType = .blockAllTouches
        hud.show(in: view)
    }

    private func stopSpinner() {
        hud.dismiss(animated: true)
    }
}
