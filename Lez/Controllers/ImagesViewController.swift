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
    var imageURLs: [String] = []
    var activeImage = ""
    var dataForNewUser: [String: Any]?
    var user: User?
    var delegate: ProfileViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        view.backgroundColor = .white
        navigationItem.title = "Image Gallery"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
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
            for imageView in getAllImageViews() {
                group.enter()
                uploadImage(image: imageView.image!).then { (url) in
                    self.imageURLs.append(url)
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                guard let user = Auth.auth().currentUser else { return }
                FirestoreManager.shared.updateUser(uid: user.uid, data: ["images": self.imageURLs, "isOnboarded": true]).then({ (success) in
                    // Images uploaded
                    self.stopSpinner()
                    self.showOkayModal(messageTitle: "Success", messageAlert: "Profile setup completed. Enjoy Lez.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                        self.dismiss(animated: true, completion: nil)
                    })
                })
            }
        }
    }
    
    private func uploadImage(image: UIImage) -> Promise<String> {
        return Promise { fulfill, reject in
            guard let user = Auth.auth().currentUser else { return }
            let ref = self.storage.reference().child("images").child(user.uid).child("\(String.random()).jpg")
            guard let data = UIImageJPEGRepresentation(image, 90.00) else {
                print("Error happened")
                return
            }
            let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    print(error)
                }
            }
            uploadTask.observe(.success) { (snapshot) in
                ref.downloadURL { url, error in
                    if let error = error {
                        reject(error)
                    } else {
                        guard let url = url else {
                            print("Error getting download URL.")
                            return
                        }
                        fulfill(url.absoluteString)
                    }
                }
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
