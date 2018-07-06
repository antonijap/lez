//
//  UIViewController+Utility.swift
//  Lez
//
//  Created by Sergey 'Svette' Vetrogonov on 03/07/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Photos

func galleryPickerViewController(forAuthorizationStatus authorizationStatus: PHAuthorizationStatus) -> UIViewController? {
    switch authorizationStatus {
    case .authorized:
        let viewController = UIImagePickerController()
        viewController.sourceType = .photoLibrary
        viewController.allowsEditing = true
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    case .denied:
        let deniedViewController = UIAlertController(title: "Gallery permission denied", message: "We need it. Mind enabling it in Settings?", preferredStyle: .alert)
        deniedViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        deniedViewController.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplicationOpenSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        })
        return deniedViewController
    case .restricted:
        let errorViewController = UIAlertController(title: "Gallery permission restricted", message: "Looks like you cannot upload any photos. Sorry!", preferredStyle: .alert)
        errorViewController.addAction(UIAlertAction(title: "OK", style: .cancel))
        return errorViewController
    case .notDetermined:
        break
    }
    return nil
}
