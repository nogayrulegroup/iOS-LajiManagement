//
//  GarbageItem+.swift
//  LajiDemo
//
//  Created by javen on 2019/8/4.
//  Copyright © 2019 nogayrulegroup. All rights reserved.
//

import Foundation

extension GarbageItem {
    
    func setDataFromCsvLine(dataLine: String) -> Bool {
        let segments = dataLine.split(separator: ",", maxSplits: Int.max, omittingEmptySubsequences: false).map { return String($0) }
        guard segments.count >= 6  else {
            return false
        }
        
        //  id item city classification extra_detail image_hash
        let id = Int64(segments[0])
        guard let oid = id else {
            return false
        }
        self.objectId = oid
        self.name = segments[1]
        let classification = Int32(segments[3])
        guard let category = classification else {
            return false
        }
        self.category = category
        self.extraInfo = segments[4]
        self.imageUrl = segments[5]
        
        return true
    }
    
}

struct GarbageItemCategories: OptionSet, Hashable {
    
    static let kCategoriesCount = 6;
    
    let rawValue: Int
 
    static let noClassifiedWaste = GarbageItemCategories(rawValue: 0)
    static let harmfulWaste = GarbageItemCategories(rawValue: 1 << 0)
    static let recyclableWaste = GarbageItemCategories(rawValue: 1 << 1)
    static let othersWaste = GarbageItemCategories(rawValue: 1 << 2)
    static let perishableWaste = GarbageItemCategories(rawValue: 1 << 3)
    static let bulkyWaste = GarbageItemCategories(rawValue: 1 << 4)
    static let decorationWaste = GarbageItemCategories(rawValue: 1 << 5)
    
    var hashValue: Int {
        return rawValue
    }
    
    static func forEach(_ body: (_ category: GarbageItemCategories) -> ()) {
        for i in stride(from: GarbageItemCategories.kCategoriesCount - 1, through: 0, by: -1) {
            let category = GarbageItemCategories(rawValue: 1 << i)
            body(category)
        }
    }
    
    var labelName: String {
        get {
            switch self.rawValue {
            case 0:
                return "NoClassified"
            case 1 << 0:
                return "Harmful"
            case 1 << 1:
                return "Recyclable"
            case 1 << 2:
                return "Others"
            case 1 << 3:
                return "Perishable"
            case 1 << 4:
                return "Bulky"
            case 1 << 5:
                return "Decoration"
            default:
                return "Unkown"
            }
        }
    }
    
}
