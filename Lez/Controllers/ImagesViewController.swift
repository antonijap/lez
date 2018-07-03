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
import Photos
import SnapKit

final class ImagesViewController: UIViewController {
    private var didSetupConstraints = false

    let imageViews = [UIImageView(frame: .zero), UIImageView(frame: .zero), UIImageView(frame: .zero), UIImageView(frame: .zero)] // Make me sad
    var images = [UIImage?](repeating: nil, count: 4)
    var imageNames = [String?](repeating: nil, count: 4)

    let doneButton = CustomButton(frame: .zero)

    let storage = Storage.storage()
    let hud = JGProgressHUD(style: .dark)
    var dataForNewUser: [String: Any]?
    var user: User?
    var profileViewControllerDelegate: ProfileViewControllerDelegate?
    var matchViewControllerDelegate: MatchViewControllerDelegate?
    var data: [String : Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Image Gallery"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        for (index, imageView) in imageViews.enumerated() { // Doing this is not pretty. I would advise using a collectionView here
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            imageView.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
            imageView.clipsToBounds = true
            imageView.contentMode = .center
            imageView.image = #imageLiteral(resourceName: "Empty_Image")
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openImageGallery(_:))))
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
        }

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        doneButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(finishTapped)))

        guard let user = user else { return }

        // Now in editing mode
        // Load all images
        self.user = user
        let userImages = user.images

        for (index, imageView) in imageViews.enumerated() { // This is incredibly unsafe. Using a collectionView here will help a lot
            guard userImages.count > index else { break }
            imageView.sd_setImage(with: URL(string: userImages[index].url), placeholderImage: #imageLiteral(resourceName: "Empty_Image"), options: [.highPriority]) { [weak self, imageView] (image, _, _, _) in
                self?.images[index] = image
                imageView.contentMode = .scaleAspectFill // Don't do this. Keep the same content mode for all images, re-do placeholder images instead
            }
        }
    }

    override func updateViewConstraints() {
        defer { didSetupConstraints = true; super.updateViewConstraints() }
        guard didSetupConstraints == false else { return }

        let width = 2.4
        imageViews[0].snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(24)
            make.leading.equalToSuperview().inset(24)
        }
        imageViews[1].snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViews[0].snp.top)
            make.trailing.equalToSuperview().offset(-24)
        }
        imageViews[2].snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViews[0].snp.bottom).offset(16)
            make.leading.equalTo(imageViews[0].snp.leading)
        }
        imageViews[3].snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViews[2].snp.top)
            make.trailing.equalTo(imageViews[1].snp.trailing)
        }
        doneButton.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(32)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(24)
            make.centerX.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for imageView in imageViews { imageView.layer.cornerRadius = 8 }
    }

    private func uploadImages() {
        guard !images.isEmpty else {
            let alertController = UIAlertController(title: "No images", message: "Every profile has at least one image. It's mandatory.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
            present(alertController, animated: true)
            stopSpinner()
            return
        }

        let group = DispatchGroup()

        guard let user = self.user else { // If there is no user, add new, that means we are in onboarding
            guard let user = Auth.auth().currentUser else { return }
            guard let data = self.data else { return }
            FirestoreManager.shared.addUser(uid: user.uid, data: data).then({ [weak self] success in
                guard success else { return }
                guard let strongSelf = self else { return }

                strongSelf.startSpinner()

                for (index, image) in strongSelf.images.enumerated() {
                    guard let image = image else { continue }
                    group.enter()
                    strongSelf.uploadImage(image: image).then { name in
                        strongSelf.imageNames[index] = name
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

        // Existing users, while editing
        // Delete images and then upload new
        deleteImages(url: user.images).then { [weak self] success in
            guard let strongSelf = self else { return }
            if success {
                for (index, image) in strongSelf.images.enumerated() {
                    guard let image = image else { return }
                    group.enter()
                    strongSelf.uploadImage(image: image).then { name in
                        strongSelf.imageNames[index] = name
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

    func compressImage(image: UIImage) -> Data? { // Reducing file size to a 10th
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

    private func presentImagePicker(for index: Int) {
        guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return }

        let galleryAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        guard galleryAuthorizationStatus != .notDetermined else {
            PHPhotoLibrary.requestAuthorization { status in DispatchQueue.main.async { self.presentImagePicker(for: index) } }
            return
        }
        guard let viewController = galleryPickerViewController(forAuthorizationStatus: galleryAuthorizationStatus) else {
            return
        }

        if let viewController = viewController as? UIImagePickerController { viewController.delegate = self }
        viewController.view.tag = index // This is a hacky way of doing things.
        present(viewController, animated: true)
    }

    @objc private func openImageGallery(_ sender: UITapGestureRecognizer) {
        guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return }
        guard let tag = sender.view?.tag else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        defer { present(alertController, animated: true) }
        alertController.addAction(UIAlertAction(title: "Choose Image", style: .default) { [weak self] _ in
            self?.presentImagePicker(for: tag)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        guard images[tag] != nil else { return }

        alertController.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.images[tag] = nil
            self?.imageViews[tag].contentMode = .center
        })
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
            print("Something went wrong."); picker.dismiss(animated: true); return
        }
        images[picker.view.tag] = image
        imageViews[picker.view.tag].image = image
        imageViews[picker.view.tag].contentMode = .scaleAspectFill
        picker.dismiss(animated: true)
    }
}

extension ImagesViewController {
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
