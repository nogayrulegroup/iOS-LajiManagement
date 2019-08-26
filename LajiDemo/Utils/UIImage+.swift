//
//  UIImage+.swift
//  LajiDemo
//
//  Created by javen on 2019/8/3.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit

extension UIImage {
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let realTargetSize = CGSize(width: targetSize.width / screenScale,
                                    height: targetSize.height / screenScale)
        UIGraphicsBeginImageContextWithOptions(realTargetSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(x: 0.0, y: 0.0, width: realTargetSize.width, height: realTargetSize.height))
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage!
    }
    
    func resizeImage(maxSize: CGFloat) -> UIImage {
        if size.width > size.height && size.width > maxSize {
            return scaleImage(scaleSize: maxSize / size.width)
        } else if size.height > maxSize {
            return scaleImage(scaleSize: maxSize / size.height)
        } else {
            return self
        }
    }
    
    func scaleImage(scaleSize: CGFloat) -> UIImage {
        let targetSize = CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize)
        return resizeImage(targetSize: targetSize)
    }
}
