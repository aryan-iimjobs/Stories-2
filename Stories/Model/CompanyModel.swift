//
//  CompanyModel.swift
//  IGStories
//
//  Created by Aryan Sharma on 21/03/20.
//  Copyright © 2020 iim jobs. All rights reserved.
//

import Foundation

public class CompanyModel: NSObject, NSCoding, NSSecureCoding {
    public static var supportsSecureCoding = true
    
    var companyName: String
    var companyId: Int
    var storyCompanyId: String
    
    var storyCount: Int
    var storyUpdatedOn: Int
    var stories: [StoryModel]
    
    var companyLogo: String
    
    var showcaseDetail: ShowCaseModel
    
    var rank: Int = 0 // start from 1
    
    enum Key:String { // not used right now
        case companyName = "companyName"
        case companyId = "companyId"
        case storyCompanyId = "storyCompanyId"
        case storyCount = "storyCount"
        case storyUpdatedOn = "storyUpdatedOn"
        case stories = "stories"
        case companyLogo = "companyLogo"
    }
    
    @objc convenience init(company: [String:Any], rank: Int) {
        // prepare storyModel objects
        var storiesObjArray: [StoryModel] = []
        if let storiesArray = company["stories"] as? [[String: Any]] {
            for story in storiesArray {
                storiesObjArray.append(StoryModel(story: story))
            }
        }
        
        //prepare showcaseModel object
        var showcaseDetailObj: ShowCaseModel
        if let showcaseDetail = company["showcaseDetail"] as? [String: Any] {
            showcaseDetailObj = ShowCaseModel(showcaseDetail: showcaseDetail)
        } else {
            showcaseDetailObj = ShowCaseModel(v2companyId: "", v2bannerUrl: "", v2jsonFilePath: "", v2templateType: "", v2showcaseId: "", v2companyName: "", v2bannerBtnTxt: "")
        }
        
        self.init(companyName: company["companyName"] as? String ?? "",
        companyId: company["companyId"] as? Int ?? 0,
        storyCompanyId: company["storyCompanyId"] as? String ?? "",
        storyCount: company["storyCount"] as? Int ?? 0,
        storyUpdatedOn: company["storyUpdatedOn"] as? Int ?? 0,
        stories: storiesObjArray,
        companyLogo: company["companyLogo"] as? String ?? "",
        showcaseDetail: showcaseDetailObj)
        self.rank = rank
    }
    
    @objc init(companyName: String, companyId: Int, storyCompanyId: String ,storyCount: Int, storyUpdatedOn: Int, stories: [StoryModel], companyLogo: String, showcaseDetail: ShowCaseModel) {
        self.companyName = companyName
        self.companyId = companyId
        self.storyCompanyId = storyCompanyId
        self.storyCount = storyCount
        self.storyUpdatedOn = storyUpdatedOn
        self.stories = stories
        self.companyLogo = companyLogo
        self.showcaseDetail = showcaseDetail
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(companyName, forKey: "companyName")
        aCoder.encode(companyId, forKey: "companyId")
        aCoder.encode(storyCompanyId, forKey: "storyCompanyId")
        aCoder.encode(storyCount, forKey: "storyCount")
        aCoder.encode(storyUpdatedOn, forKey: "storyUpdatedOn")
        aCoder.encode(stories, forKey: "stories")
        aCoder.encode(companyLogo, forKey: "companyLogo")
        aCoder.encode(showcaseDetail, forKey: "showcaseDetail")
        aCoder.encode(rank, forKey: "rank")
    }
       
    public required convenience init?(coder aDecoder: NSCoder) {
        let mcompanyName = aDecoder.decodeObject(forKey: "companyName") as? String ?? ""
        let mcompanyId = aDecoder.decodeInt64(forKey: "companyId")
        let mstoryCompanyId = aDecoder.decodeObject(forKey: "storyCompanyId") as? String ?? ""
        let mstoryCount = aDecoder.decodeInt64(forKey: "storyCount")
        let mstoryUpdatedOn = aDecoder.decodeInt64(forKey: "storyUpatedOn")
        let mstories = aDecoder.decodeObject(forKey: "stories") as! [StoryModel]
        let mcompanyLogo = aDecoder.decodeObject(forKey: "companyLogo") as? String ?? ""
        let mshowcaseDetail = aDecoder.decodeObject(forKey: "showcaseDetail") as! ShowCaseModel
        let mrank = aDecoder.decodeInt64(forKey: "rank")
        
        self.init(companyName: mcompanyName, companyId: Int(mcompanyId), storyCompanyId: mstoryCompanyId ,storyCount: Int(mstoryCount), storyUpdatedOn: Int(mstoryUpdatedOn), stories: mstories, companyLogo: mcompanyLogo, showcaseDetail: mshowcaseDetail)
        self.rank = Int(mrank)
    }
}
