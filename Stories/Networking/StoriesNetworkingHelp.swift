//
//  StoriesNetworkingHelp.swift
//  Stories
//
//  Created by Aryan Sharma on 25/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import Alamofire

///Class contains different methods to help with stories API requests.
class StoriesNetworkingHelp: NSObject {
    ///Makes GET request for Data response.
    ///- parameter url: The url string to make API request on.
    ///- parameter completionHandler: Block executed when async API request is complete.
    func dataGetRequest(url: String, completionHandler: @escaping(Data?,Error?) -> Void) {
        Alamofire.request(url).response { (response) in
            if let error = response.error {
                print("Stories/NetworkingHelp/dataGetRequest: error = \(error)")
                completionHandler(nil, error)
            } else if let data = response.data {
                completionHandler(data, nil)
            }
        }
    }
    
    ///Makes GET request for JSON response.
    ///- parameter url: The url string to make API request on.
    ///- parameter completionHandler: Block executed when async API request is complete.
    func jsonGetRequest(url: String, completionHandler: @escaping([String: Any]?, Error?) -> Void) {
        Alamofire.request(url).responseJSON { (response) in
            if let error = response.error, !response.result.isSuccess {
                print("Stories/NetworkingHelp/jsonGetRequest: error = \(error), response = \(response)")
                completionHandler(nil, error)
            } else if let json = response.result.value as? [String: Any] {
                completionHandler(json, nil)
            }
        }
    }
    
    ///Makes POST request for JSON response.
    ///- parameter url: The url string to make API request on.
    ///- parameter parameters: Dictionary to send to API.
    ///- parameter completionHandler: Block executed when async API request is complete.
    func jsonPostRequest(url: String, parameters: [String:String], completionHandler: @escaping([String: Any]?, Error?) -> Void) {
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
            if let error = response.error, !response.result.isSuccess {
                print("Stories/NetworkingHelp/jsonPostRequest: error = \(error), response = \(response)")
                completionHandler(nil, error)
            } else if let json = response.result.value as? [String: Any] {
                completionHandler(json, nil)
            }
        }
    }
    
    ///Tells if the internet is reachable.
    func isInternetReachable() -> Bool {
        if let nm = NetworkReachabilityManager() {
            return nm.isReachable
        }
        return true
    }
    
    //MARK:- helper functions
    
    let cookie = "sVYq_SLASH_MHl4bYuo6ROMRVrdJpcSg0fZEC_PLUS_NCDpe11acqcLJUauKgx9ynVUafUCTsTBsL_PLUS_uC3HtrHAMRFWc0WkiOw_EQUALS__EQUALS_"
    let clapPostUrl = "https://bidder.hirist.com/api7/story/clap"
    let blockCompanyPosturl = "https://bidder.hirist.com/api7/blockstories"
    
    ///Makes API request to POST clap number of a story.
    ///- parameter storyId: storyId from **StoryModel** to identify story at bank-end.
    ///- parameter totalClaps: Total number of claps registered.
    ///- parameter completionHandler: Block executed when async API request is complete.
    ///- parameter isSuccess: True if POST successfull without any error.
    func postClapNumber(storyId: String, totalClaps: Int, completionHandler: @escaping(_ isSuccess: Bool) -> Void) {
        let parameters = [
            "en_cookie": "\(cookie)",
            "payload": "[{\"storyId\":\"\(storyId)\",\"count\":\"\(totalClaps)\"}]"
        ]
        
        jsonPostRequest(url: clapPostUrl, parameters: parameters, completionHandler: { response, error in
            if error == nil, let resp = response, (resp["success"] as? Int) == 1 {
                print("Clap resp: \(response ?? ["":""])")
                completionHandler(true)
            } else {
                if let err = error {
                    print("Clap error :\(err)")
                }
                completionHandler(false)
            }
        })
    }

    ///Makes API POST request to block a company from appearing in API response .
    ///- parameter companyId: companyId from **CompanyModel** to identify company at bank-end.
    ///- parameter completionHandler: Block executed when async API request is complete.
    ///- parameter isSuccess: True if POST successfull without any error.
    func blockCompanyRequest(companyId: Int, completionHandler: @escaping(_ isSuccess: Bool) -> Void) {
        let parameters = [
            "en_cookie": "\(cookie)",
            "blockCompany": "\(companyId)"
        ]
            
        jsonPostRequest(url: blockCompanyPosturl, parameters: parameters, completionHandler: { response, error in
            if error == nil, let resp = response, (resp["success"] as? Int) == 1 {
                print("Company Blocked: \(response ?? ["":""])")
                completionHandler(true)
            } else {
                if let err = error {
                    print("Company Block error :\(err)")
                }
                completionHandler(false)
            }
        })
    }
}

