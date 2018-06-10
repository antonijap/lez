//
//  ImageGalleryViewController.swift
//  Lez
//
//  Created by Antonija on 31/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Alertift
import Firebase
import Promises
import JGProgressHUD



//class ImageGalleryViewController: UIViewController, ImagePickerDelegate {
//    
//    var user: User!
//    var profileImagePickerController: ImagePickerController!
//    var imageGalleryPickerController: ImagePickerController!
//    var profileImageView: CustomImageView!
//    var imageView: CustomImageView!
//    var imageView2: CustomImageView!
//    let storage = Storage.storage()
//    let hud = JGProgressHUD(style: .dark)
//    var delegate: ProfileViewControllerDelegate?
//    
//    public var imageAssets: [UIImage] {
//        return AssetManager.resolveAssets(imageGalleryPickerController.stack.assets)
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Check if there is users.
//        
//        // If not then show uploading
//        
//        // If yes then show editing
//        
//        FirestoreManager.shared.fetchUser(uid: Auth.auth().currentUser!.uid).then { (user) in
//            self.user = user
//            self.setupView()
//            
//            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.profileImageTapped(_:)))
////            self.profileImageView.isUserInteractionEnabled = true
////            self.profileImageView.addGestureRecognizer(tapGestureRecognizer)
//            
//            var configuration = Configuration()
//            configuration.doneButtonTitle = "Finish"
//            configuration.noImagesTitle = "Sorry! There are no images here!"
//            configuration.recordLocation = false
//            configuration.allowVideoSelection = false
//            
////            self.profileImagePickerController = ImagePickerController(configuration: configuration)
////            self.profileImagePickerController.imageLimit = 1
//            
//            self.imageGalleryPickerController = ImagePickerController(configuration: configuration)
//            self.imageGalleryPickerController.imageLimit = 2
//        }
//        
//        
//    }
//    
//    var finalImages: [UIImage] = []
//    var finalFilenames: [String] = []
//    var imageURLs: [String] = []
//    
//    func checkImageOne() -> Bool {
//        if imageView.image != UIImage(named: "Add Image") {
//            finalImages.append(imageView.image!)
//            finalFilenames.append("Image1")
//            return true
//        }
//        return false
//    }
//    
//    func checkImageTwo() -> Bool {
//        if imageView2.image != UIImage(named: "Add Image") {
//            finalImages.append(imageView2.image!)
//            finalFilenames.append("Image1")
//            return true
//        }
//        return false
//    }
//    
//    func startSpinner() {
//        hud.textLabel.text = "Uploading Images"
//        hud.vibrancyEnabled = true
//        hud.interactionType = .blockAllTouches
//        hud.show(in: view)
//    }
//    
//    func stopSpinner() {
//        hud.dismiss(animated: true)
//    }
//    
//    func updateImages(images: [String]) {
//        FirestoreManager.shared.updateImages(uid: user.uid, urls: imageURLs).then { success in
//            if success {
//                self.stopSpinner()
//                self.delegate?.shouldRefresh = true
//                self.navigationController?.popViewController(animated: true)
//            } else {
//                self.showOkayModal(messageTitle: "Error Happened", messageAlert: "Something went wrong with saving images. Try again.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
//            }
//        }
//    }
//    
//    func writeUserData(images: [String]) {
//        let data: [String: Any] = [
//            "uid": self.user.uid,
//            "name": self.user.name,
//            "email": self.user.email,
//            "age": self.user.age,
//            "location": [
//                "city": self.user.location.city,
//                "country": self.user.location.country
//            ],
//            "preferences": [
//                "ageRange": [
//                    "from": self.user.preferences.ageRange.from,
//                    "to": self.user.preferences.ageRange.to
//                ],
//                "lookingFor": self.user.preferences.lookingFor
//            ],
//            "details": [
//                "about": self.user.details.about,
//                "dealbreakers": self.user.details.dealBreakers,
//                "diet": self.user.details.diet.rawValue
//            ],
//            "images": self.imageURLs,
//            "isOnboarded": true,
//            "isPremium": false,
//            "isBanned": false,
//            "isHidden": false,
//            "likes": [],
//            "dislikes": [],
//            "created": FieldValue.serverTimestamp(),
//            "blockedUsers": [],
//            "chats": [],
//            "likesLeft": 5,
//            "cooldownTime": ""
//        ]
//        FirestoreManager.shared.addUser(uid: self.user.uid, data: data).then { (success) in
//            if success {
//                self.stopSpinner()
//                self.dismiss(animated: true, completion: nil)
//            } else {
//                self.showOkayModal(messageTitle: "Profile Image", messageAlert: "All profiles must have at least a profile image.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
//            }
//        }
//    }
//    
//    private func uploadImage(image: UIImage, filename: String) {
//        let ref = self.storage.reference().child("images").child(self.user.uid).child("\(filename).jpg")
//        guard let data = UIImageJPEGRepresentation(image, 90.00) else {
//            print("Error happened")
//            return
//        }
//        let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
//            if let error = error {
//                print(error)
//            }
//        }
//        uploadTask.observe(.success) { snapshot in
//            ref.downloadURL { url, error in
//                if let error = error {
//                    print(error.localizedDescription)
//                } else {
//                    guard let url = url else {
//                        print("Error getting download URL.")
//                        return
//                    }
//                    self.imageURLs.append(url.absoluteString)
//                }
//            }
//        }
//    }
//    
//    private func uploadImages() {
//        var images: [UIImage] = []
//        images.append(profileImageView.image!)
//        images.append(imageView.image!)
//        images.append(imageView2.image!)
//        
//        var finalImages: [UIImage] = []
//        
//        for image in images {
//            if image != UIImage(named: "Add Image") {
//                finalImages.append(image)
//            }
//        }
//        
//        if finalImages.count > 0 {
//            for image in finalImages {
//                uploadImage(image: image, filename: String.random())
//            }
//        } else {
//            Alertift.alert(title: "No images", message: "Every profile needs to have at least 1 image. It's mandatory.")
//                .action(.default("Okay"))
//                .show()
//        }
//    }
//    
//    @objc func buttonTapped2(_ sender: CustomButton) {
//        
//    }
//
//    @objc func buttonTapped(_ sender: CustomButton) {
//        if profileImageView.image != UIImage(named: "Add Image") {
//            finalImages.append(profileImageView.image!)
//            finalFilenames.append("Profile")
//            startSpinner()
//            // 1. Upload Profile Image
//            let ref = storage.reference().child("images").child(user.uid).child("profile.jpg")
//            guard let data = UIImageJPEGRepresentation(profileImageView.image!, 90.00) else {
//                print("Error happened")
//                return
//            }
//            let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
//                if let error = error {
//                    print(error)
//                }
//            }
//            uploadTask.observe(.success) { snapshot in
//                
////                self.imageURLs.append(snapshot.metadata!.downloadURL()!.standardizedFileURL.absoluteString)
////                // 2. Check if there is first image and upload it
////                if self.checkImageOne() {
////                    let ref = self.storage.reference().child("images").child(self.user.uid).child("image_1.jpg")
////                    guard let data = UIImageJPEGRepresentation(self.imageView.image!, 90.00) else {
////                        print("Error happened")
////                        return
////                    }
////                    let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
////                        if let error = error {
////                            print(error)
////                        }
////                    }
////                    uploadTask.observe(.success) { snapshot in
////                        self.imageURLs.append(snapshot.metadata!.downloadURL()!.standardizedFileURL.absoluteString)
////                        // 3. Check if there is second image and upload it
////                        if self.checkImageTwo() {
////                            let ref = self.storage.reference().child("images").child(self.user.uid).child("image_2.jpg")
////                            guard let data = UIImageJPEGRepresentation(self.imageView2.image!, 90.00) else {
////                                print("Error happened")
////                                return
////                            }
////                            let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
////                                if let error = error {
////                                    print(error)
////                                }
////                            }
////                            uploadTask.observe(.success) { snapshot in
////                                self.imageURLs.append(snapshot.metadata!.downloadURL()!.standardizedFileURL.absoluteString)
////                                // 4. Write user data to Firestore
////                                if self.user.isOnboarded {
////                                    self.updateImages(images: self.imageURLs)
////                                } else {
////                                    self.writeUserData(images: self.imageURLs)
////                                }
////                            }
////                        } else {
////                            // 4. Write user data to Firestore
////                            if self.user.isOnboarded {
////                                self.updateImages(images: self.imageURLs)
////                            } else {
////                                self.writeUserData(images: self.imageURLs)
////                            }
////                        }
////                    }
////                } else {
////                    // 4. Write user data to Firestore
////                    if self.user.isOnboarded {
////                        self.updateImages(images: self.imageURLs)
////                    } else {
////                        self.writeUserData(images: self.imageURLs)
////                    }
////                }
//            }
//        } else {
//            Alertift.alert(title: "Profile Image", message: "Every profile has a profile image. It's mandatory.")
//                .action(.default("Okay"))
//                .show()
//        }
//    }
//    
//    @objc func imageGalleryTapped(_ sender: UITapGestureRecognizer) {
//        Alertift.actionSheet(message: nil)
//            .actions(["Choose Image", "Remove"])
//            .action(.cancel("Cancel"))
//            .finally { action, index in
//                if action.style == .cancel {
//                    return
//                }
//                if index == 0 {
//                    self.imageGalleryPickerController.delegate = self
//                    self.present(self.imageGalleryPickerController, animated: true, completion: nil)
//                }
//                if index == 1 {
//                    self.profileImageView.image = UIImage(named: "Add Image")
//                }
//            }
//            .show()
//    }
//    
//    @objc func profileImageTapped(_ sender: UITapGestureRecognizer) {
//        Alertift.actionSheet(message: nil)
//            .actions(["Choose Image", "Remove"])
//            .action(.cancel("Cancel"))
//            .finally { action, index in
//                if action.style == .cancel {
//                    return
//                }
//                if index == 0 {
//                    self.profileImagePickerController.delegate = self
//                    self.present(self.profileImagePickerController, animated: true, completion: nil)
//                }
//                if index == 1 {
//                    self.profileImageView.image = UIImage(named: "Add Image")
//                }
//            }
//            .show()
//        
//    }
//
//    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
//        guard images.count > 0 else { return }
//        let lightboxImages = images.map {
//            return LightboxImage(image: $0)
//        }
//        
//        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
//        imagePicker.present(lightbox, animated: true, completion: nil)
//    }
//    
//    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
//        if imagePicker == profileImagePickerController {
//            if images.count == 1 {
//                profileImageView.contentMode = .scaleAspectFill
//                profileImageView.image = images[0].compressTo(size: 1)?.resize(width: 500.00)
//            }
//        } else if imagePicker == imageGalleryPickerController {
//            let images = imageAssets
//            if images.count == 2 {
//                imageView.contentMode = .scaleAspectFill
//                imageView2.contentMode = .scaleAspectFill
//                imageView.image = images[0].compressTo(size: 1)?.resize(width: 500.00)
//                imageView2.image = images[1].compressTo(size: 1)?.resize(width: 500.00)
//            } else {
//                imageView.contentMode = .scaleAspectFill
//                imageView2.contentMode = .center
//                imageView.image = images[0].compressTo(size: 1)?.resize(width: 500.00)
//                imageView2.image = UIImage(named: "Add Image")
//            }
//        }
//   
//        imagePicker.dismiss(animated: true, completion: nil)
//    }
//    
//    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
//        imagePicker.dismiss(animated: true, completion: nil)
//    }
//    
//    func setupView() {
//        if user.isOnboarded {
//            navigationItem.title = "Update Images"
//        } else {
//            navigationItem.title = "Setup Your Profile 2/2"
//        }
//        view.backgroundColor = UIColor(red:0.96, green:0.97, blue:0.97, alpha:1.00)
//        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageGalleryTapped(_:)))
//        tap.numberOfTapsRequired = 1
//
////        profileImageView = CustomImageView()
////        view.addSubview(profileImageView)
////        profileImageView.snp.makeConstraints { (make) in
////            make.size.equalTo(148)
////            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(16)
////            make.centerX.equalToSuperview()
////        }
////        profileImageView.isUserInteractionEnabled = true
////        profileImageView.addGestureRecognizer(tap)
////        profileImageView.contentMode = .scaleAspectFit
////        profileImageView.moa.url = user.images.first
//        
//        let container = UIView()
//        view.addSubview(container)
//        let x = view.frame.width * 0.6
//        container.snp.makeConstraints { (make) in
//            make.width.equalToSuperview().inset(16)
//            make.height.equalTo(x)
//            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(16)
//            make.centerX.equalToSuperview()
//        }
//        container.isUserInteractionEnabled = true
//        container.addGestureRecognizer(tap)
//        
//        imageView = CustomImageView()
//        container.addSubview(imageView)
//        imageView.snp.makeConstraints { (make) in
//            make.width.equalToSuperview().dividedBy(2.1)
//            make.height.equalToSuperview()
//            make.centerY.equalToSuperview()
//            make.left.equalToSuperview()
//        }
//
//        imageView.contentMode = .scaleAspectFit
//        if user.images.count > 1 {
//            imageView.moa.url = user.images[1]
//        }
//
//        imageView2 = CustomImageView()
//        container.addSubview(imageView2)
//        imageView2.snp.makeConstraints { (make) in
//            make.width.equalToSuperview().dividedBy(2.1)
//            make.height.equalToSuperview()
//            make.centerY.equalToSuperview()
//            make.right.equalToSuperview()
//        }
//
//        imageView2.contentMode = .scaleAspectFit
//        if user.images.count > 2 {
//            imageView2.moa.url = user.images[2]
//        }
//        
//        let button = CustomButton()
//        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.buttonTapped(_:)))
//        view.addSubview(button)
//        button.snp.makeConstraints { (make) in
//            make.width.equalToSuperview().inset(32)
//            make.height.equalTo(44)
//            make.bottom.equalToSuperview().inset(32)
//            make.centerX.equalToSuperview()
//        }
//        if user.isOnboarded {
//            button.setTitle("Update", for: .normal)
//        } else {
//            button.setTitle("Complete Profile", for: .normal)
//        }
//        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
//        button.addGestureRecognizer(buttonTap)
//    }
//}
