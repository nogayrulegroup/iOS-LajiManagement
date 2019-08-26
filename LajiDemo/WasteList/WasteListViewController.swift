//
//  WasteListViewController.swift
//  LajiDemo
//
//  Created by javen on 2019/8/10.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import Toast_Swift

class WasteListViewController: UIViewController {
    
    // data
    private let categories: [GarbageItemCategories] = [.noClassifiedWaste, .harmfulWaste, .recyclableWaste, .othersWaste, .perishableWaste, .bulkyWaste, .decorationWaste]
    private var garbegesMap: [GarbageItemCategories: [GarbageItem]] = [:]
    
    // uis
    private var listView: UICollectionView!
    
    private var searchBar: UISearchBar!

    // functions
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initData()
        initUIs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerNetworkStatusChangedNotification(selector: #selector(didNetworkStatusChanged))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterNetworkStatusChangedNotification()
    }
    
    private func initData() {
        fetchObjects()
    }
    
    private func fetchObjects(fetchName: String? = nil, reloadData: Bool = false) {
        var tempGarbegesMap: [GarbageItemCategories: [GarbageItem]] = [:]
        for category in categories {
            tempGarbegesMap[category] = [GarbageItem]()
        }
        let fetchRequest: NSFetchRequest<GarbageItem> = GarbageItem.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "objectId", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if !(fetchName?.isEmpty ?? true) {
            let queryName = "*\(fetchName!)*"
            let predicate = NSPredicate(format: "name like %@", queryName)
            fetchRequest.predicate = predicate
        }
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            let objs = try persistentContainer.viewContext.fetch(fetchRequest)
            for obj in objs {
                let objCategories = GarbageItemCategories(rawValue: Int(obj.category))
                guard objCategories.rawValue > 0 else {
                    tempGarbegesMap[.noClassifiedWaste]?.append(obj)
                    continue
                }
                
                categories.filter { category -> Bool in
                    return category.rawValue > 0 && objCategories.contains(category)
                    }.forEach { category in
                        tempGarbegesMap[category]?.append(obj)
                }
            }
            garbegesMap = tempGarbegesMap
            if reloadData {
                listView?.reloadData()
            }
            print("show local objects cost: \(CFAbsoluteTimeGetCurrent() - startTime)")
        } catch {
            print(error)
        }
    }
    
    private func initUIs() {
        self.view.backgroundColor = backgroundColor
        
        searchBar = UISearchBar()
        searchBar.placeholder = "搜索"
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        self.view.addSubview(searchBar)
        searchBar.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
        }
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.headerReferenceSize = CGSize(width: screenSize.width, height: 30.0)
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = CGSize(width: screenSize.width, height: 35.0)
        listView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        listView.backgroundColor = backgroundColor
        listView.dataSource = self
        listView.delegate = self
        listView.register(CategoryViewCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "category_header_view_cell")
        listView.register(GarbageItemViewCell.self, forCellWithReuseIdentifier: "item_view_cell")
        
        self.view.addSubview(listView)
        
        listView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(searchBar.snp.bottom)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        
        // take detect entrance
        let cameraDetectEntrance = UIBarButtonItem(title: "Detect", style: .plain, target: self, action: #selector(didCameraDetectEntranceClicked))
        navigationItem.setRightBarButton(cameraDetectEntrance, animated: false)
    }

    private func callCameraCapture() {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .camera
        imagePickerVC.delegate = self
        imagePickerVC.cameraDevice = .rear
        imagePickerVC.cameraCaptureMode = .photo
        imagePickerVC.cameraFlashMode = .auto
        present(imagePickerVC, animated: true, completion: nil)
    }
    
    func loadNetworkData() {
        let classificationDataTimestamp = UserDefaults.standard.string(forKey: "classificationDataTimestamp")
        var headers: HTTPHeaders = []
        if let classificationDataTimestamp = classificationDataTimestamp {
            headers.add(HTTPHeader(name: "If-Modified-Since", value: classificationDataTimestamp))
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("classificationData.csv")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let downloadUrl = "\(networkHost)/download/classification"
        let downloadRequest = AF.download(downloadUrl, method: HTTPMethod.get, headers: headers, to: destination)
        
        downloadRequest.response { [weak self] response in
            print(response)
            
            let statusCode = response.response?.statusCode ?? 400
            guard statusCode == 200 else {
                if statusCode != 304 {
                    self?.view.makeToast("未拉取到数据: \(response.error?.localizedDescription ?? "Unkown")")
                }
                return
            }
            
            if response.error == nil, let csvURL = response.fileURL {
                let lastModified = response.response?.headers["Last-Modified"]
                let startTime = CFAbsoluteTimeGetCurrent()
                self?.praseClassificationData(fileUrl: csvURL, lastModified: lastModified)
                print("praseClassificationData cost: \(CFAbsoluteTimeGetCurrent() - startTime)")
            }
        }
    }
    
    private func praseClassificationData(fileUrl: URL, lastModified: String?) {
        guard let reader = StreamReader(path: fileUrl.path) else {
            return
        }
        defer {
            reader.close()
        }
        
        var newGarbegesMap: [GarbageItemCategories: [GarbageItem]] = [:]
        for category in categories {
            newGarbegesMap[category] = [GarbageItem]()
        }
        var itemCounter = 0
        for line in reader {
            let garbageItem = GarbageItem(context: persistentContainer.viewContext)
            guard garbageItem.setDataFromCsvLine(dataLine: line) else {
                persistentContainer.viewContext.delete(garbageItem)
                continue
            }
            
            itemCounter += 1
            let objCategories = GarbageItemCategories(rawValue: Int(garbageItem.category))
            guard objCategories.rawValue > 0 else {
                newGarbegesMap[.noClassifiedWaste]?.append(garbageItem)
                continue
            }
            
            categories.filter { category -> Bool in
                return category.rawValue > 0 && objCategories.contains(category)
            }.forEach { category in
                newGarbegesMap[category]?.append(garbageItem)
            }
        }
        print("find \(itemCounter) items")
        
        garbegesMap.forEach { (_, itemList) in
            itemList.forEach({ item in
                persistentContainer.viewContext.delete(item)
            })
        }
        
        garbegesMap = newGarbegesMap
        if let lastModifiedString = lastModified {
            UserDefaults.standard.set(lastModifiedString, forKey: "classificationDataTimestamp")
        }
        self.listView.reloadData()
        self.listView.makeToast("数据更新完毕")
        
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
}

// MARK: - Actions

extension WasteListViewController {
    
    @objc private func didCameraDetectEntranceClicked() {
        callCameraCapture()
    }
    
    @objc private func didNetworkStatusChanged() {
        if networkManager.isReachable {
            loadNetworkData()
        }
    }
}

// MARK: - Extensions

extension WasteListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchObjects(fetchName: searchText, reloadData: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}

extension WasteListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return garbegesMap[categories[section]]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let viewCell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "category_header_view_cell", for: indexPath) as! CategoryViewCell
        viewCell.categoryName = categories[indexPath.section].labelName
        return viewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "item_view_cell", for: indexPath) as! GarbageItemViewCell
        let category = categories[indexPath.section]
        let children = garbegesMap[category]!
        let data = children[indexPath.row]
        viewCell.categoryName = category.labelName
        viewCell.itemName = data.name
        return viewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let vc = CameraDetectionViewController()
        vc.garbageItem = garbegesMap[categories[indexPath.section]]![indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension WasteListViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let vc = CameraDetectionViewController()
        vc.srcImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        vc.tryToDetectObject = true
        navigationController?.pushViewController(vc, animated: true)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
