//
//  ShowCaseModel.swift
//  IGStories
//
//  Created by Aryan Sharma on 08/04/20.
//  Copyright © 2020 iim jobs. All rights reserved.
//

import UIKit

class ShowCaseModel: NSObject, NSCoding, NSSecureCoding {
    public static var supportsSecureCoding = true
    
    var v2companyId: String
    var v2bannerUrl: String
    var v2jsonFilePath: String
    var v2templateType: String
    var v2showcaseId: String
    var v2companyName: String
    var v2bannerBtnTxt: String
    
    @objc convenience init(showcaseDetail: [String:Any]) {
        self.init(v2companyId: showcaseDetail["v2companyId"] as? String ?? "",
        v2bannerUrl: showcaseDetail["v2bannerUrl"] as? String ?? "",
        v2jsonFilePath: showcaseDetail["v2jsonFilePath"] as? String ?? "",
        v2templateType: showcaseDetail["v2templateType"] as? String ?? "",
        v2showcaseId: showcaseDetail["v2showcaseId"] as? String ?? "",
        v2companyName: showcaseDetail["v2companyName"] as? String ?? "",
        v2bannerBtnTxt: showcaseDetail["v2bannerBtnTxt"] as? String ?? "")
    }
    
    @objc init(v2companyId: String, v2bannerUrl: String, v2jsonFilePath: String, v2templateType: String, v2showcaseId: String, v2companyName: String, v2bannerBtnTxt: String) {
        self.v2companyId = v2companyId
        self.v2bannerUrl = v2bannerUrl
        self.v2jsonFilePath = v2jsonFilePath
        self.v2templateType = v2templateType
        self.v2showcaseId = v2showcaseId
        self.v2companyName = v2companyName
        self.v2bannerBtnTxt = v2bannerBtnTxt
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(v2companyId, forKey: "v2companyId")
        aCoder.encode(v2bannerUrl, forKey: "v2bannerUrl")
        aCoder.encode(v2jsonFilePath, forKey: "v2jsonFilePath")
        aCoder.encode(v2templateType, forKey: "v2templateType")
        aCoder.encode(v2showcaseId, forKey: "v2showcaseId")
        aCoder.encode(v2companyName, forKey: "v2companyName")
        aCoder.encode(v2bannerBtnTxt, forKey: "v2bannerBtnTxt")
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let mv2companyId = aDecoder.decodeObject(forKey: "v2companyId") as? String ?? ""
        let mv2bannerUrl = aDecoder.decodeObject(forKey: "v2bannerUrl") as? String ?? ""
        let mv2jsonFilePath = aDecoder.decodeObject(forKey: "v2jsonFilePath") as? String ?? ""
        let mv2templateType = aDecoder.decodeObject(forKey: "v2templateType") as? String ?? ""
        let mv2showcaseId = aDecoder.decodeObject(forKey: "v2showcaseId") as? String ?? ""
        let mv2companyName = aDecoder.decodeObject(forKey: "v2companyName") as? String ?? ""
        let mv2bannerBtnTxt = aDecoder.decodeObject(forKey: "v2bannerBtnTxt") as? String ?? ""
        
        self.init(v2companyId: mv2companyId, v2bannerUrl: mv2bannerUrl, v2jsonFilePath: mv2jsonFilePath, v2templateType: mv2templateType, v2showcaseId: mv2showcaseId, v2companyName: mv2companyName, v2bannerBtnTxt: mv2bannerBtnTxt)
    }
    
}
