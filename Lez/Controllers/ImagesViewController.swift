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

class ImagesViewController: UIViewController {
    
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
                    if imageView.image == UIImage(named: "Empty_Image") || imageView.image == UIImage(named: "Empty_Image_Profile") {
                        imageView.sd_setImage(with: URL(string: image.url), completed: nil)
                        imageView.contentMode = .scaleAspectFill
                        break
                    }
                }
            }
        }
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

    
    private func setupInterface() {
        let width = 2.4
        view.addSubview(imageViewOne)
        imageViewOne.snp.makeConstraints { (make) in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(24)
            make.left.equalToSuperview().inset(24)
        }
        imageViewOne.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewOne.clipsToBounds = true
        imageViewOne.layer.cornerRadius = 8
        imageViewOne.contentMode = .center
        imageViewOne.image = UIImage(named: "Empty_Image_Profile")
        
        view.addSubview(imageViewTwo)
        imageViewTwo.snp.makeConstraints { (make) in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViewOne.snp.top)
            make.right.equalToSuperview().offset(-24)
        }
        imageViewTwo.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewTwo.clipsToBounds = true
        imageViewTwo.layer.cornerRadius = 8
        imageViewTwo.contentMode = .center
        imageViewTwo.image = UIImage(named: "Empty_Image")
        
        view.addSubview(imageViewThree)
        imageViewThree.snp.makeConstraints { (make) in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViewOne.snp.bottom).offset(16)
            make.left.equalTo(imageViewOne.snp.left)
        }
        imageViewThree.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewThree.clipsToBounds = true
        imageViewThree.layer.cornerRadius = 8
        imageViewThree.contentMode = .center
        imageViewThree.image = UIImage(named: "Empty_Image")
        
        view.addSubview(imageViewFour)
        imageViewFour.snp.makeConstraints { (make) in
            make.width.equalToSuperview().dividedBy(width)
            make.height.equalToSuperview().dividedBy(2.8)
            make.top.equalTo(imageViewThree.snp.top)
            make.right.equalTo(imageViewTwo.snp.right)
        }
        imageViewFour.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        imageViewFour.clipsToBounds = true
        imageViewFour.layer.cornerRadius = 8
        imageViewFour.contentMode = .center
        imageViewFour.image = UIImage(named: "Empty_Image")
        
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
        imagePickerOne.sourceType = .savedPhotosAlbum;
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
        button.snp.makeConstraints { (make) in
            make.width.equalToSuperview().inset(32)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(24)
            make.centerX.equalToSuperview()
        }
        button.setTitle("Done", for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        button.addGestureRecognizer(buttonTap)
    }
    
    private func getAllImageViews() -> [UIImageView] {
        var filledImageViews: [UIImageView] = []
        for imageView in imageViews {
            if imageView.image != UIImage(named: "Empty_Image") && imageView.image != UIImage(named: "Empty_Image_Profile") {
                filledImageViews.append(imageView)
            }
        }
        return filledImageViews
    }
    
    private func uploadImages() {
        startSpinner()
        let group = DispatchGroup()
        if getAllImageViews().isEmpty {
            Alertift.alert(title: "No images", message: "Every profile has at least one image. It's mandatory.")
                .action(.default("Okay"))
                .show(on: self, completion: {
                    self.stopSpinner()
                })
        } else {
//            if let user = self.user {
//                for imageView in self.getAllImageViews() {
//                    group.enter()
//                    self.uploadImage(image: imageView.image!).then { (url) in
//                        self.imageURLs.append(url)
//                        group.leave()
//                    }
//                }
//                group.notify(queue: .main) {
//                    FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": self.imageURLs]).then({ (success) in
//                        self.stopSpinner()
//                        self.profileViewControllerDelegate?.refreshProfile()
//                        self.navigationController?.popToRootViewController(animated: true)
//                    })
//                }
//            } else {
//                for imageView in self.getAllImageViews() {
//                    group.enter()
//                    self.uploadImage(image: imageView.image!).then { (url) in
//                        self.imageURLs.append(url)
//                        group.leave()
//                    }
//                }
//                group.notify(queue: .main) {
//                    guard let user = Auth.auth().currentUser else { return }
//                    FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": self.imageURLs, "isOnboarded": true]).then({ (success) in
//                        self.stopSpinner()
//                        self.showOkayModal(messageTitle: "Profile Setup Completed", messageAlert: "Enjoy Lez and remember to report users who don't belong here.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
//                            self.matchViewControllerDelegate?.fetchUsers(for: user.uid)
//                            self.dismiss(animated: true, completion: nil)
//                        })
//                    })
//                }
//            }
            
            if let user = self.user {
                deleteImages(url: user.images).then { success in
                    if success {
                        for imageView in self.getAllImageViews() {
                            group.enter()
                            self.uploadImage(image: imageView.image!).then { (name) in
                                self.imageNames.append(name)
                                group.leave()
                            }
                        }
                        group.notify(queue: .main) {
                            FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": self.imageNames]).then({ (success) in
                                self.stopSpinner()
                                self.profileViewControllerDelegate?.refreshProfile()
                                self.navigationController?.popToRootViewController(animated: true)
                            })
                        }
                    }
                }
                group.notify(queue: .main) {
                    FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": self.imageNames]).then({ (success) in
                        self.stopSpinner()
                        self.profileViewControllerDelegate?.refreshProfile()
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            } else {
                for imageView in self.getAllImageViews() {
                    group.enter()
                    self.uploadImage(image: imageView.image!).then { (url) in
                        self.imageNames.append(url)
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    guard let user = Auth.auth().currentUser else { return }
                    FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": self.imageNames, "isOnboarded": true]).then({ (success) in
                        self.stopSpinner()
                        self.showOkayModal(messageTitle: "Profile Setup Completed", messageAlert: "Enjoy Lez and remember to report users who don't belong here.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                            self.matchViewControllerDelegate?.fetchUsers(for: user.uid)
                            self.dismiss(animated: true, completion: nil)
                        })
                    })
                }
            }
        }
    }
    
    func compressImage(image: UIImage) -> Data? {
        // Reducing file size to a 10th
        var actualHeight : CGFloat = image.size.height
        var actualWidth : CGFloat = image.size.width
        let maxHeight : CGFloat = 1136.0
        let maxWidth : CGFloat = 640.0
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        var compressionQuality : CGFloat = 0.5
        
        if (actualHeight > maxHeight || actualWidth > maxWidth){
            if(imgRatio < maxRatio){
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if(imgRatio > maxRatio){
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else{
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        guard let imageData = UIImageJPEGRepresentation(img, compressionQuality)else{
            return nil
        }
        return imageData
    }
    
    private func uploadImage(image: UIImage) -> Promise<String> {
        return Promise { fulfill, reject in
            guard let user = Auth.auth().currentUser else { return }
            let ref = self.storage.reference().child("images").child(user.uid).child("\(String.random()).jpg")
            let optimisedImage = self.compressImage(image: image)
            guard let data = optimisedImage else {
                print("Error with optimising image.")
                return
            }
            ref.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    print(error)
                }
                guard let metadata = metadata else {
                    print("Problem with metadata.")
                    return
                }
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
                group.notify(queue: .main) {
                    fulfill(true)
                }
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
                    if action.style == .cancel {
                        return
                    }
                    if index == 0 {
                        guard let view = sender.view else {
                            return
                        }
                        if view.tag == 0 {
                            self.present(self.imagePickerOne, animated: true, completion: {
                                self.activeImage = "imageViewOne"
                            })
                        } else if view.tag == 1 {
                            self.present(self.imagePickerTwo, animated: true, completion: {
                                self.activeImage = "imageViewTwo"
                            })
                        } else if view.tag == 2 {
                            self.present(self.imagePickerThree, animated: true, completion: {
                                self.activeImage = "imageViewThree"
                            })
                        } else if view.tag == 3 {
                            self.present(self.imagePickerFour, animated: true, completion: {
                                self.activeImage = "imageViewFour"
                            })
                        }
                    }
                    if index == 1 {
                        guard let view = sender.view else {
                            return
                        }
                        if view.tag == 0 {
                            self.imageViewOne.image = UIImage(named: "Empty_Image_Profile")
                            self.imageViewOne.contentMode = .center
                        } else if view.tag == 1 {
                            self.imageViewTwo.image = UIImage(named: "Empty_Image")
                            self.imageViewTwo.contentMode = .center
                        } else if view.tag == 2 {
                            self.imageViewThree.image = UIImage(named: "Empty_Image")
                            self.imageViewThree.contentMode = .center
                        } else if view.tag == 3 {
                            self.imageViewFour.image = UIImage(named: "Empty_Image")
                            self.imageViewFour.contentMode = .center
                        }
                    }
                }
                .show(on: self, completion: nil)
        }
    }
    
    @objc private func finishTapped() {
        uploadImages()
    }
}

extension ImagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if activeImage == "imageViewOne" {
                imageViewOne.image = image
                imageViewOne.contentMode = .scaleAspectFill
            }
            
            if activeImage == "imageViewTwo" {
                imageViewTwo.image = image
                imageViewTwo.contentMode = .scaleAspectFill
            }
            
            if activeImage == "imageViewThree" {
                imageViewThree.image = image
                imageViewThree.contentMode = .scaleAspectFill
            }
            
            if activeImage == "imageViewFour" {
                imageViewFour.image = image
                imageViewFour.contentMode = .scaleAspectFill
            }
//            for imageView in imageViews {
//                if imageView.image == nil {
//                    imageView.image = image
//                    break
//                }
//            }
        } else {
            print("Something went wrong")
        }
        self.dismiss(animated: true, completion: nil)
    }
}
