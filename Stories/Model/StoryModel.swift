//
//  Story.swift
//  IGStories
//
//  Created by Aryan Sharma on 21/03/20.
//  Copyright © 2020 iim jobs. All rights reserved.
//

import UIKit

public class StoryModel: NSObject, NSCoding, NSSecureCoding {
    public static var supportsSecureCoding = true
    
    var storyId: String
    var storyType: Int
    
    var createdOn: Int
    var expiryOn: Int
    
    var totalViewCount: Int
    var totalClapCount: Int
    var thumbnailPath: String
    
    var s3Path: String
    
    var isSeen: Bool = false
    var isClapped: Bool = false
    
    //Additional data
    var linkType: Int = 0
    var linkUrl: String = ""
    var linkData: Dictionary<String, Any> = ["":""]
    
    @objc convenience init(story: [String:Any]) {
        self.init(storyId: story["storyId"] as? String ?? "",
                  storyType: story["storyType"] as? Int ?? 0,
                  createdOn: story["createdOn"] as? Int ?? 0,
                  expiryOn: story["expiryOn"] as? Int ?? 0,
                  totalViewCount: story["totalViewCount"] as? Int ?? 0,
                  totalClapCount: story["totalClapCount"] as? Int ?? 0,
                  thumbnailPath: story["thumbnailPath"] as? String ?? "",
                  s3Path: story["s3Path"] as? String ?? "")
        
        if story["linkType"] as? Int != nil {
            var dictionary: [String:Any] = ["":""]
            switch story["linkType"] as? Int ?? 0 {
            case 1:
                //external showcase
                //linkData is empty in API
                dictionary = ["linkText":story["linkText"] as? String ?? ""]
                break
            case 2:
                //Job Detail
                if let linkData = story["linkData"] as? [[String: Any]], !linkData.isEmpty {
                    let obj = linkData[0]
                    dictionary = ["jobId":obj["jobId"] as? String ?? ""]
                }
                break
            case 3:
                //Recruiter Profile
                if let linkDataArray = story["linkData"] as? [[String: Any]], !linkDataArray.isEmpty {
                    let linkData = linkDataArray[0]
                    dictionary = ["designation": linkData["desgination"] as? String ?? "",
                                  "email": linkData["email"] as? String ?? "",
                                  "id": linkData["id"] as? Int ?? 0,
                                  "image": linkData["image"] as? String ?? "",
                                  "name": linkData["name"] as? String ?? "",
                                  "organisation": linkData["organisation"] as? String ?? "",
                                  "phone": linkData["phone"] as? String ?? ""]
                }
                break
            case 4:
                //External Link
                //linkData is empty in API
                dictionary = ["linkText":story["linkText"] as? String ?? ""]
                break
            default: ()
            }
            self.setAdditionalData(linkType: story["linkType"] as? Int ?? 0,
                                   linkUrl: story["linkUrl"] as? String ?? "",
                                   linkData: dictionary)
        }
    }
    
    @objc init(storyId: String, storyType: Int, createdOn: Int, expiryOn: Int, totalViewCount: Int, totalClapCount: Int, thumbnailPath: String, s3Path: String) {
        self.storyId = storyId
        self.storyType = storyType
        self.createdOn = createdOn
        self.expiryOn = expiryOn
        self.totalViewCount = totalViewCount
        self.totalClapCount = totalClapCount
        self.thumbnailPath = thumbnailPath
        self.s3Path = s3Path
    }
    
    public func setAdditionalData(linkType: Int, linkUrl: String, linkData: Dictionary<String, Any>) {
        self.linkType = linkType
        self.linkUrl = linkUrl
        self.linkData = linkData
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(storyId, forKey: "storyId")
        aCoder.encode(storyType, forKey: "storyType")
        aCoder.encode(createdOn, forKey: "createdOn")
        aCoder.encode(expiryOn, forKey: "expiryOn")
        aCoder.encode(totalViewCount, forKey: "totalViewCount")
        aCoder.encode(totalClapCount, forKey: "totalClapCount")
        aCoder.encode(thumbnailPath, forKey: "thumbnailPath")
        aCoder.encode(s3Path, forKey: "s3Path")
        aCoder.encode(isSeen, forKey: "isSeen")
        aCoder.encode(isClapped, forKey: "isClapped")
        aCoder.encode(linkType, forKey: "linkType")
        aCoder.encode(linkUrl, forKey: "linkUrl")
        aCoder.encode(linkData, forKey: "linkData")
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let mstoryId = aDecoder.decodeObject(forKey: "storyId") as? String ?? ""
        let mstoryType = aDecoder.decodeInt64(forKey: "storyType")
        let mcreatedOn = aDecoder.decodeInt64(forKey: "createdOn")
        let mexpiryOn = aDecoder.decodeInt64(forKey: "expiryOn")
        let mtotalViewCount = aDecoder.decodeInt64(forKey: "totalViewCount")
        let mtotalClapCount = aDecoder.decodeInt64(forKey: "totalClapCount")
        let mthumbnailPath = aDecoder.decodeObject(forKey: "thumbnailPath") as? String ?? ""
        let ms3Path = aDecoder.decodeObject(forKey: "s3Path") as? String ?? ""
        let misSeen = aDecoder.decodeBool(forKey: "isSeen")
        let misClapped = aDecoder.decodeBool(forKey: "isClapped")
        let mlinkType = aDecoder.decodeInt64(forKey: "linkType")
        let mlinkUrl = aDecoder.decodeObject(forKey: "linkUrl") as? String ?? ""
        let mlinkData = aDecoder.decodeObject(forKey: "linkData") as? Dictionary<String, Any> ?? ["":""]
        
        self.init(storyId: mstoryId, storyType: Int(mstoryType), createdOn: Int(mcreatedOn), expiryOn: Int(mexpiryOn), totalViewCount: Int(mtotalViewCount), totalClapCount: Int(mtotalClapCount), thumbnailPath: mthumbnailPath, s3Path: ms3Path)
        self.isSeen = misSeen
        self.isClapped = misClapped
        self.setAdditionalData(linkType: Int(mlinkType), linkUrl: mlinkUrl, linkData: mlinkData)
    }
}
