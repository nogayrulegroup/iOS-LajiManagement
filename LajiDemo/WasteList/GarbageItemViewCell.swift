//
//  GarbageItemViewCell.swift
//  LajiDemo
//
//  Created by javen on 2019/8/10.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import UIKit

class GarbageItemViewCell: UICollectionViewCell {
    
    var categoryName: String? {
        set {
            categoryNameLabel.text = (newValue ?? "") + "- "
        }
        get {
            let displayName = categoryNameLabel.text ?? "- "
            return String(displayName[..<(displayName.firstIndex(of: "-") ?? displayName.startIndex)])
        }
    }
    
    var itemName: String? {
        set {
            itemNameLabel.text = newValue
        }
        get {
            return itemNameLabel.text
        }
    }
    
    private var categoryNameLabel: UILabel!
    private var itemNameLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        categoryNameLabel = UILabel()
        itemNameLabel = UILabel()
        
        categoryNameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .light)
        categoryNameLabel.textColor = UIColor.init(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        categoryNameLabel.textAlignment = .center
        
        itemNameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        itemNameLabel.textAlignment = .left
        
        self.contentView.addSubview(categoryNameLabel)
        self.contentView.addSubview(itemNameLabel)
        
        categoryNameLabel.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(5.0)
            maker.centerY.equalToSuperview()
        }
        
        itemNameLabel.snp.makeConstraints { maker in
            maker.right.equalToSuperview()
            maker.left.equalTo(self.categoryNameLabel.snp.right)
            maker.centerY.equalToSuperview()
        }
    }
    
}
