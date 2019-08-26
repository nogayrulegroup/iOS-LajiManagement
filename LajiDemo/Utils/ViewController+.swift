//
//  ViewController+.swift
//  LajiDemo
//
//  Created by huya on 2019/8/4.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

extension UIViewController {
    
    var persistentContainer: NSPersistentContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    var networkManager: NetworkReachabilityManager {
        return (UIApplication.shared.delegate as! AppDelegate).networkManager!
    }
    
    func registerNetworkStatusChangedNotification(selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: didNetworkStatusChangedNotification, object: nil)
    }
    
    func unregisterNetworkStatusChangedNotification() {
        NotificationCenter.default.removeObserver(self, name: didNetworkStatusChangedNotification, object: nil)
    }
    
    var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
}
