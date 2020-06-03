//
//  StoriesCoreDataHelp.swift
//  Stories
//
//  Created by Aryan Sharma on 25/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import CoreData

///Class helps to store data and retrieve data from stories persistent container.
class StoriesCoreDataHelp: NSObject {

    let DATA_MODEL: String = "StoriesCoreDataModel"
    let ENTITY: String = "Stories"
    let ATTRIBUTE: String = "company"
    
    ///This property contains a reference to the NSManagedObjectContext that is created and owned by stories persistent container.
    lazy var managedObjectContext: NSManagedObjectContext = {
        let container = NSPersistentContainer(name: DATA_MODEL)
        var errorOccurred = false
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // check for errors
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container.viewContext
    }()

    ///Attempts to commit unsaved changes of stories to registered objects to the persistent container.
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                //fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    ///Saves **CompanyModel** objects to the database.
    ///- parameter objectArray: Array of **CompanyModel** objects.
    func saveToPersistentStore(companies objectArray: [CompanyModel]) {
        purgePersistentStore()
            
        for object in objectArray {
            guard let entity = NSEntityDescription.entity(forEntityName: ENTITY, in: managedObjectContext) else {
                //error
                continue
            }
            let company = NSManagedObject(entity: entity, insertInto: managedObjectContext)
            company.setValue(object, forKey: ATTRIBUTE)
            
            saveContext()
        }
        print("MainVC: saved into coreData")
    }
        
    ///Retrieves **CompanyModel** objects from the database.
    func getFromPersistentStore() -> [CompanyModel] {
        print("MainVC: fetch from core data started")
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: ENTITY)
        var arrayCompanies: [CompanyModel] = []
        
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            print("MainVC: fetching from core data, size = \(result.count)")
            for obj in result {
                if let companyObj = obj.value(forKey: ATTRIBUTE) as? CompanyModel {
                    arrayCompanies.append(companyObj)
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return arrayCompanies
    }
    
    ///Batch deletes all data in stories persistent store without loading any data into memory.
    func purgePersistentStore() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ENTITY)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedObjectContext.executeAndMergeChanges(using: batchDeleteRequest)
        } catch let error as NSError {
            print("Could not purge. \(error), \(error.userInfo)")
        }
    }
}


