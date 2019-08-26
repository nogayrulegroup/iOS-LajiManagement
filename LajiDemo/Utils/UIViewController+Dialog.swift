//
//  UIViewController+Dialog.swift
//  LajiDemo
//
//  Created by javen on 2019/8/26.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit

extension UIViewController {
    
    private static var loadingViewTag: Int = 99999999
    
    var safeToastPosition: CGPoint {
        return CGPoint(x: screenWidth / 2, y: screenHeight - 72)
    }
    
    func showMessageAlert(title: String?, message: String?, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: handler)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showModelLoadingDialog(message: String? = "Loading", bgSize: CGFloat = 90) {
        let rootFrame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        let loadingViewContainer = UIView(frame: rootFrame)
        loadingViewContainer.alpha = 0.0
        loadingViewContainer.isUserInteractionEnabled = true
        loadingViewContainer.tag = UIViewController.loadingViewTag
        loadingViewContainer.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        let bgView = UIView()
        bgView.frame = CGRect(x: (rootFrame.width - bgSize) / 2, y: (rootFrame.height - bgSize) / 2, width: bgSize, height: bgSize)
        bgView.layer.cornerRadius = 10
        bgView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingViewContainer.addSubview(bgView)
        
        let indicatorView = UIActivityIndicatorView(style: .white)
        indicatorView.startAnimating()
        bgView.addSubview(indicatorView)
        
        if message != nil {
            indicatorView.snp.makeConstraints { maker in
                maker.width.height.equalTo(50)
                maker.centerX.equalToSuperview()
                maker.top.equalToSuperview().offset(10)
            }
            
            let lableView = UILabel()
            lableView.font = UIFont.systemFont(ofSize: 14)
            lableView.textColor = UIColor.white
            lableView.text = message
            lableView.textAlignment = .center
            lableView.sizeToFit()
            bgView.addSubview(lableView)
            
            lableView.snp.makeConstraints { maker in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(indicatorView.snp.bottom)
            }
        } else {
            indicatorView.snp.makeConstraints { maker in
                maker.width.height.equalTo(50)
                maker.center.equalToSuperview()
            }
        }
    
        UIApplication.shared.delegate?.window??.addSubview(loadingViewContainer)
        UIView.animate(withDuration: 0.5) {
            loadingViewContainer.alpha = 1.0
        }
    }
    
    func hideModelLoadingDialog() {
        UIApplication.shared.delegate?.window??.subviews.forEach({ subView in
            if subView.tag == UIViewController.loadingViewTag {
                UIView.animate(withDuration: 0.5, animations: {
                    subView.alpha = 0.0
                }) { _ in
                    subView.removeFromSuperview()
                }
            }
        })
    }
    
    func showShareDialog(items: [Any], completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil, sourceView: UIView? = nil) {
        let activitiesVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activitiesVC.completionWithItemsHandler = completionWithItemsHandler
        if let ppc = activitiesVC.popoverPresentationController {
            ppc.sourceView = sourceView ?? view
            ppc.sourceRect = sourceView?.bounds ?? view.bounds
        }
        self.present(activitiesVC, animated: true, completion: nil)
    }
}
