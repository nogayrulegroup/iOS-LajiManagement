//
//  CategoryViewCell.swift
//  LajiDemo
//
//  Created by javen on 2019/8/10.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit

class CategoryViewCell: UICollectionReusableView {
    
    var categoryName: String? {
        set {
            labelView.text = newValue
        }
        get {
            return labelView.text
        }
    }
    
    private var labelView: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        labelView = UILabel()
        labelView.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        labelView.textAlignment = .left
        
        self.addSubview(labelView)
        
        labelView.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(5.0)
            maker.centerY.equalToSuperview()
        }
    }
    
}
