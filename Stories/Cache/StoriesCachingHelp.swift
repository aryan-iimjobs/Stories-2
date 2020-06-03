//
//  StoriesCachingHelp.swift
//  Stories
//
//  Created by Aryan Sharma on 25/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

///Class to help caching data of stories module.
///Contains methods to store, retrieve, list and remove cache files.
class StoriesCachingHelp: NSObject {
    
    let cacheDirectory: String = "dotStories"
    
    ///Writes provided data into caches directory.
    ///- parameter data: Data to be written into caches directory.
    ///- parameter key: Key to identify stored cache.
    func store(data: Data, key: String) {
        if let filePath = filePath(forKey: key) {
            do  {
                try data.write(to: filePath, options: .atomic)
            } catch let err {
                print("Saving Company Icon resulted in error: ", err)
            }
        }
    }
    
    ///Returns image data from cache.
    ///- parameter key: Key to identify stored cache..
    ///- returns: Data converted to UIImage.
    func retrieveImage(key: String) -> UIImage {
        if let filePath = filePath(forKey: key),
            let fileData = FileManager.default.contents(atPath: filePath.path),
            let image = UIImage(data: fileData) {
            return image
        }
        return UIImage()
    }
    
    ///Constructs url path for a given key in caches directory.
    ///- parameter key: String to find path for.
    ///- returns: URL for path if successful else nil.
    func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        let documentURLs = fileManager.urls(for: .cachesDirectory,
        in: FileManager.SearchPathDomainMask.userDomainMask)
        
        guard let documentURL = documentURLs.first else { return nil }
        
        let dataPath: String = documentURL.path + "/\(cacheDirectory)"
        
        if !FileManager.default.fileExists(atPath: dataPath) {
            // Creates that folder if not exists
            do {
                try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Error creating story folder in caches dir: \(error)")
                return nil
            }
        }
        return documentURL.appendingPathComponent("\(cacheDirectory)/" + key )
    }
    
    ///Tells if the file already exists in caches directory.
    ///- parameter key: Name of the file.
    func fileExists(key: String) -> Bool {
        if let filePath = filePath(forKey: key), FileManager.default.fileExists(atPath: filePath.path) {
            return true
        }
        return false
    }
    
    ///Provides name of all the cached items in caches directory.
    func listCachedItems() -> [String] {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [NSString]
        guard let path = paths.first else { return [""] }
        
        let cachesDirectory = path.appendingPathComponent("\(cacheDirectory)")
        
        if let allItems = try? FileManager.default.contentsOfDirectory(atPath: cachesDirectory) {
            return allItems
        }
        return [""]
    }
    
    ///Removes cached item if exists.
    ///- parameter localPathName: Name of the cached item.
    func removeCachedItem(localPathName:String) {
        let filemanager = FileManager.default
        let cachesDirectoryPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true) as [NSString]
        guard let cachesDirectoryPath = cachesDirectoryPaths.first else {
            return
        }
        let destinationPath = cachesDirectoryPath.appendingPathComponent("\(cacheDirectory)/" + localPathName)
        if FileManager.default.fileExists(atPath: destinationPath) {
            do {
                try filemanager.removeItem(atPath: destinationPath)
                print("Local path removed successfully")
            } catch let error as NSError {
                print("Error",error.debugDescription)
            }
        }
    }
}
