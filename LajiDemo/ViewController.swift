//
//  ViewController.swift
//  LajiDemo
//
//  Created by javen on 2019/8/3.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit
import SnapKit
import Alamofire

class ViewController: UIViewController {
    
    private var cameraButton: UIButton?
    private var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUIs()
        
    }
    
    private func initUIs() {
        imageView = UIImageView()
        imageView?.contentMode = .scaleAspectFit
        
        if let imageView = imageView {
            self.view.addSubview(imageView)
            imageView.snp.makeConstraints({ maker in
                maker.left.right.bottom.top.equalToSuperview()
            })
        }
        
        cameraButton = UIButton(type: .system)
        cameraButton?.setTitle("Take Picture", for: .normal)
        cameraButton?.addTarget(self, action: #selector(didCameraButtonClicked(sender:)), for: .touchUpInside)
        
        if let cameraButton = cameraButton {
            self.view.addSubview(cameraButton)
            cameraButton.snp.makeConstraints({ maker in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            })
        }
    }

}

// MARK: -
// MARK: - Evevts
extension ViewController {
    
    @objc func didCameraButtonClicked(sender: UIButton?) {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .camera
        imagePickerVC.delegate = self
        imagePickerVC.cameraDevice = .rear
        imagePickerVC.cameraCaptureMode = .photo
        imagePickerVC.cameraFlashMode = .auto
        present(imagePickerVC, animated: true, completion: nil)
    }
    
}

// MARK: -

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView?.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
