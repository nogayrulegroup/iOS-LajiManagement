//
//  CameraDetectionViewController.swift
//  LajiDemo
//
//  Created by javen on 2019/8/10.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import Kingfisher
import CoreData
import Toast_Swift
import Alamofire
import SelectionDialog

class CameraDetectionViewController: UIViewController {
    
    // data
    var garbageItem: GarbageItem?
    
    var srcImage: UIImage?
    
    var tryToDetectObject = false
    
    // uis
    private var objectNameField: UITextField!
    private var imageView: UIImageView!
    private var categoryIndicators: [GarbageItemCategories: UISwitch] = [:]
    private var extraInfoEdit: UITextView!
    private var backgroundTapGesture: UITapGestureRecognizer!

    // functions
    override func viewDidLoad() {
        super.viewDidLoad()

        initUIs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registNotifications()
        detectObject()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregistNotifications()
    }
    
    private func initUIs() {
        view.backgroundColor = backgroundColor
        view.isUserInteractionEnabled = true
        navigationItem.title = "Object Info"
        backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(didBackgroundTaped))
        backgroundTapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(backgroundTapGesture)
        
        imageView = UIImageView(image: srcImage)
        if let imageHash = garbageItem?.imageUrl, !imageHash.isEmpty {
            imageView.kf.setImage(with: URL(string: "\(networkHost)/download/user-upload/\(imageHash)"))
        } else if srcImage == nil {
            imageView.image = UIImage(named: "image_unknown.jpeg")
        }
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            maker.left.right.equalToSuperview()
            maker.height.equalToSuperview().multipliedBy(0.5)
        }
        
        objectNameField = UITextField()
        objectNameField.backgroundColor = backgroundColor
        objectNameField.placeholder = "未知物体..."
        objectNameField.text = garbageItem?.name
        objectNameField.textAlignment = .center
        objectNameField.font = UIFont.boldSystemFont(ofSize: 16.0)
        view.addSubview(objectNameField)
        objectNameField.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.left.right.equalToSuperview()
            maker.top.equalTo(imageView.snp.bottom).offset(5.0)
        }
        
        let placeHolderView = UIView()
        placeHolderView.backgroundColor = UIColor.clear
        view.addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { maker in
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(1.0)
        }
        
        var refView = placeHolderView
        let objCategories = GarbageItemCategories(rawValue: Int(garbageItem?.category ?? 0))
        GarbageItemCategories.forEach { category in
            let categoryIndicator = UISwitch()
            categoryIndicators[category] = categoryIndicator
            categoryIndicator.tag = category.rawValue
            categoryIndicator.setOn(objCategories.contains(category), animated: false)
            categoryIndicator.addTarget(self, action: #selector(didCategoryIndicatorValueChanged(sender:)), for: .valueChanged)
            view.addSubview(categoryIndicator)
            
            categoryIndicator.snp.makeConstraints { maker in
                maker.right.equalToSuperview().offset(-20.0)
                maker.bottom.equalTo(refView.snp.top).offset(-1.0)
            }
            
            let categoryLabel = UILabel()
            categoryLabel.text = category.labelName
            categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            view.addSubview(categoryLabel)
            categoryLabel.snp.makeConstraints { maker in
                maker.left.equalToSuperview().offset(20.0)
                maker.centerY.equalTo(categoryIndicator)
            }
            
            refView = categoryIndicator
        }
        
        extraInfoEdit = UITextView()
        extraInfoEdit.layer.backgroundColor = backgroundColor.cgColor
        extraInfoEdit.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).cgColor
        extraInfoEdit.layer.borderWidth = 1.0
        extraInfoEdit.layer.masksToBounds = true
        extraInfoEdit.text = garbageItem?.extraInfo
        view.addSubview(extraInfoEdit)
        extraInfoEdit.snp.makeConstraints { maker in
            maker.top.equalTo(objectNameField.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalTo(refView.snp.top).offset(-5.0)
        }
        
        let uploadButton = UIBarButtonItem(title: "Upload", style: .plain, target: self, action: #selector(didUploadButtonClicked))
        navigationItem.setRightBarButton(uploadButton, animated: false)
    }
    
    private func detectObject() {
        guard tryToDetectObject, let imageData = srcImage?.resizeImage(maxSize: 512.0).jpegData(compressionQuality: 0.7) else {
            return
        }
        tryToDetectObject = false
        showModelLoadingDialog()
        
        let request = AF.upload(multipartFormData: { formData in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("image.jpg")
            do {
                if (FileManager.default.fileExists(atPath: fileURL.path)) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                try imageData.write(to: fileURL)
            } catch {
                print(error)
                formData.append(imageData, withName: "image", fileName: "image.jpg")
                return
            }
            formData.append(fileURL, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
        }, to: "\(networkHost)/recognize/image")
        
        request.responseString { [weak self] response in
            self?.hideModelLoadingDialog()
            
            guard response.error == nil, let responseData = response.value else {
                self?.detectObjectFail(errorMsg: "\(response.error!.localizedDescription)")
                return
            }
            
            let json = JSON(parseJSON: responseData)
            if let result = json["result"].arrayValue.first {
                self?.detectObjectSuccess(objName: result["keyword"].stringValue)
            } else {
                self?.detectObjectFail(errorMsg: "未识别出任何物体")
            }
        }
    }
    
    private func detectObjectSuccess(objName: String) {
        let fetchRequest: NSFetchRequest<GarbageItem> = GarbageItem.fetchRequest()
        let queryName = "*\(objName)*"
        fetchRequest.predicate = NSPredicate(format: "name like %@", queryName)
        do {
            let objs = try persistentContainer.viewContext.fetch(fetchRequest)
            guard !objs.isEmpty else {
                view.makeToast("\(objName) 未收录至数据库")
                objectNameField.text = objName
                return
            }
            
            if objs.count > 1 {
                let dialog = SelectionDialog(title: "选一蛤", closeButtonTitle: "不选，咋滴")
                objs.forEach { item in
                    dialog.addItem(item: item.name ?? "Unknown", didTapHandler: {
                        self.showObjectInfo(item)
                        dialog.close()
                    })
                }
                dialog.show()
            } else {
                showObjectInfo(objs.first!)
            }
        } catch {
            print(error)
            view.makeToast("\(objName) 未收录至数据库")
        }
    }
    
    private func detectObjectFail(errorMsg: String) {
        view.makeToast("识别失败: \(errorMsg)")
    }
    
    private func showObjectInfo(_ obj: GarbageItem) {
        garbageItem = obj
        objectNameField.text = obj.name
        extraInfoEdit.text = obj.extraInfo ?? ""
        let objCategories = GarbageItemCategories(rawValue: Int(obj.category))
        GarbageItemCategories.forEach { category in
            categoryIndicators[category]?.setOn(objCategories.contains(category), animated: true)
        }
    }
    
    private func registNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didKeyboardShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didKeyboardHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregistNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: -

extension CameraDetectionViewController {
    
    @objc private func didBackgroundTaped() {
        if extraInfoEdit.isFirstResponder {
            extraInfoEdit.resignFirstResponder()
        }
        if objectNameField.isFirstResponder {
            objectNameField.resignFirstResponder()
        }
    }
    
    @objc private func didUploadButtonClicked() {
        showModelLoadingDialog()
        
        if let currentObject = garbageItem {
            var categories = GarbageItemCategories(rawValue: 0)
            GarbageItemCategories.forEach {
                if categoryIndicators[$0]?.isOn ?? false {
                    categories = categories.union($0)
                }
            }
            let parameters: Parameters = [
                "extra_detail": extraInfoEdit.text ?? "",
                "classification": categories.rawValue
            ]
            let request = AF.request("\(networkHost)/classification/\(currentObject.objectId)", method: HTTPMethod.put, parameters: parameters, encoding: URLEncoding.default, headers: nil, interceptor: nil)
            request.responseString { [weak self] response in
                print(response)
                self?.hideModelLoadingDialog()
                
                if response.error != nil {
                    self?.view.makeToast("更新数据失败: \(response.error?.localizedDescription ?? "Unknown")")
                } else {
                    currentObject.extraInfo = self?.extraInfoEdit.text ?? ""
                    currentObject.category = Int32(categories.rawValue)
                    do {
                        try self?.persistentContainer.viewContext.save()
                    } catch {
                        self?.view.makeToast("更新数据失败: \(error)")
                        return
                    }
                    self?.view.makeToast("更新数据成功: \(response.value ?? "")")
                }
            }
        } else {
            guard let itemName = objectNameField.text, !itemName.isEmpty else {
                view.makeToast("物体名字不允许为空")
                return
            }
            
            var categories = GarbageItemCategories(rawValue: 0)
            GarbageItemCategories.forEach {
                if categoryIndicators[$0]?.isOn ?? false {
                    categories = categories.union($0)
                }
            }
            
            let extraInfo = extraInfoEdit.text ?? ""
            
            func addItemAction(imageHash: String) -> Void {
                print("addItem with imageHash: \(imageHash)")
                let parameters: Parameters = [
                    "item": itemName,
                    "classification": categories.rawValue,
                    "extra_detail": extraInfo,
                    "image_hash": imageHash
                ]
                AF.request("\(networkHost)/classification/", method: HTTPMethod.post, parameters: parameters, encoding: URLEncoding.default, headers: nil, interceptor: nil).responseString(completionHandler: { addItemResponse in
                    self.hideModelLoadingDialog()
                    
                    guard addItemResponse.error == nil && addItemResponse.value ?? "Fail" == "OK" else {
                        self.view.makeToast("新增物体失败: \(addItemResponse.value ?? "Fail")")
                        return
                    }
                    
                    self.view.makeToast("新增物体成功")
                })
            }
            
            if let imageData = srcImage?.resizeImage(maxSize: 512.0).jpegData(compressionQuality: 0.7) {
                do {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appendingPathComponent("image.jpg")
                    try imageData.write(to: fileURL)
                    
                    let uploadRequest = AF.upload(multipartFormData: { formData in
                        formData.append(fileURL, withName: "file", fileName: "image.jpg", mimeType: "image/jpeg")
                    }, to: "\(networkHost)/file-upload")
                    
                    uploadRequest.responseString(queue: DispatchQueue.global()) { [weak self] response in
                        var imageHash = ""
                        if response.error != nil || response.response?.statusCode ?? 400 != 200 {
                            DispatchQueue.main.async {
                                self?.view.makeToast("图片上传失败: \(response.error?.localizedDescription ?? "未知错误")")
                                addItemAction(imageHash: imageHash)
                            }
                        } else {
                            imageHash = response.value ?? ""
                            addItemAction(imageHash: imageHash)
                        }
                    }
                } catch {
                    self.view.makeToast("图片上传失败: \(error.localizedDescription)")
                }
            } else {
                addItemAction(imageHash: "")
            }
        }
    }
    
    @objc private func didKeyboardShow(notification: Notification) {
        let info = notification.userInfo!
        let keyboardRect = info[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let infoEditorFrame = view.convert(extraInfoEdit.frame, to: nil)
        if infoEditorFrame.maxY > keyboardRect.minY {
            extraInfoEdit.transform = CGAffineTransform(translationX: 0.0,
                                                        y: keyboardRect.minY - infoEditorFrame.maxY)
            objectNameField.transform = CGAffineTransform(translationX: 0.0,
                                                          y: keyboardRect.minY - infoEditorFrame.maxY)
        }
    }
    
    @objc private func didKeyboardHidden(notification: Notification) {
        extraInfoEdit.transform = .identity
        objectNameField.transform = .identity
    }
    
}

// MARK: -

extension CameraDetectionViewController {
    
    @objc private func didCategoryIndicatorValueChanged(sender: UISwitch) {
        
    }
    
}
