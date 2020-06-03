//
//  MainStoriesView.swift
//  Stories
//
//  Created by Aryan Sharma on 24/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

///Main view (entry point) of the stories module. It contains a collection view, whose cells present a story through **StoryViewController**.
class MainStoriesView: UIView {
    
    //MARK: constants
    let CELL_REUSE_IDENTIFIER = "CompanyIconCell"
    ///It is the right side space after each cell. Thus the space between two adjacent cells.
    let SPACE_BETWEEN_CELLS: CGFloat = 1
    ///The maximum number of cells visible at any given point.
    let MAX_FULLY_VISIBLE_CELLS: CGFloat = 8
    ///The minimum number of cells visible at any given point.
    let MIN_FULLY_VISIBLE_CELLS:CGFloat = 5
    ///The default height of the MainStoriesView.
    let DEFAULT_STORIES_HEIGHT: CGFloat = 100
    ///The ratio of **Width** and  **Height** of an cell. Suppose **w = 80** and **h = 100** then **Ratio  = 0.8**.
    let CELL_WIDTH_HEIGHT_RATIO: CGFloat = 0.8
    
    //MARK: properties
    ///It is the default width of each cell.
    var cellWidth: CGFloat = 80
    
    //MARK: flags
    ///Indicates if the **MainStoriesView** is force hidden from the Settings of the application.
    var isStoriesViewHidden: Bool = false
    
    //MARK: object references
    ///Reference to the the viewController  to which **MainStoriesView** is added to.
    var parentVC: ViewController
    let coreDataHelp: StoriesCoreDataHelp = StoriesCoreDataHelp()
    let cachingHelp: StoriesCachingHelp = StoriesCachingHelp()
    let networkHelp: StoriesNetworkingHelp = StoriesNetworkingHelp()
    ///Serial dispatch queue to process all background tasks in the stories module.
    let storiesQueue = DispatchQueue.init(label: "storiesDispatchQueue", qos: .default)
    //end
    
    //MARK: data holders
    ///Array that holds currently being used **CompanyModel** objects.
    var arrayCompanies: [CompanyModel] = []
    ///Array that holds clean **CompanyModel** objects either loaded from database or a copy, about to be replaced with API call results.
    ///Used to contrast and compare with new obtained results from API.
    var arrayCompaniesTemp: [CompanyModel] = []

    //MARK: UIViews
    ///Main collection view of the stories module, first view visible to the user for interaction.
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout();
        layout.scrollDirection = .horizontal;
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout);
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1) // white
        return cv;
    }()
    
    ///Image view with a circluar loading image. Displayed when loading stories or refreshing stories.
    let loadingSpinner : UIImageView = {
        let iv = UIImageView(image: UIImage(named: "stories_circularSpinner"))
        iv.alpha = 0 // hidden by default
        return iv
    }()
    
    /**
     Creates a **MainStoriesView** instance.
     - parameter parentVC: ViewController  to which **MainStoriesView** is added to.
     - parameter isHidden: Indicates if the **MainStoriesView** is force hidden from the Settings of the application.
     - returns: Instance of **MainStoriesView**.
     */
    init(parentVC: ViewController, isHidden: Bool) {
        self.parentVC = parentVC
        self.isStoriesViewHidden = isHidden
        super.init(frame: .zero)
        
        setupViews()
        addNotificationObservers()
        
        //check for login
        getData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        collectionView.register(CompanyIconCell.self, forCellWithReuseIdentifier: CELL_REUSE_IDENTIFIER)
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        
        addSubview(loadingSpinner)
        bringSubviewToFront(loadingSpinner)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

        cellWidth = getCellWidth()
        
        loadingSpinner.frame = CGRect(x: 2, y: 0, width: cellWidth, height: cellWidth)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        ///handle change in visibility of main view
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: "changeStoriesVisibilityState"), object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.viewVisibilityStateChanged), name: NSNotification.Name(rawValue: "changeStoriesVisibilityState"), object: nil)
        
        ///handle app termination
        notificationCenter.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.viewWillDisappear), name: UIApplication.willTerminateNotification, object: nil)
        
        ///open specific story from CompanyShowcase
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: "openStoryFromShowcase"), object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.openSpecificStory(_:)), name: NSNotification.Name(rawValue: "openStoryFromShowcase"), object: nil)
    }
    
    ///Fired by **changeStoriesVisibilityState** notification when ever there is a change in visibility of **MainStoriesView**
    ///from the Settings of the application.
    @objc func viewVisibilityStateChanged() {
        if isStoriesViewHidden {
            unHideStoriesView()
        } else {
            hideStoriesView()
        }
    }
    
    ///Fired by  system's **UIApplication.willTerminateNotification** notification.
    ///Simulates a viewController's **viewWillDisappear()** function.
    @objc func viewWillDisappear() {
        if isStoriesViewHidden { return }
        self.coreDataHelp.saveToPersistentStore(companies: arrayCompanies)
    }
    
    ///Fired by **openStoryFromShowcase** notification  when story is opened from a companies showcase.
    @objc func openSpecificStory(_ notification: NSNotification) {
        if isStoriesViewHidden { return }
        if let companyId = notification.userInfo?["companyId"] as? String {
            for (company, index) in zip(arrayCompanies, 0..<arrayCompanies.count) {
                if "\(company.companyId)" == companyId {
                    let vc = StoryViewController(arrayCompanies: arrayCompanies, selectedCompanyIndex: index)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.delegate = self
                    vc.isFromShowcase = true
                    parentVC.present(vc, animated: true, completion: nil)
                    break
                }
            }
        }
    }
    
    ///Retrieves data from database and then requests API for new data.
    func getData() {
        if isStoriesViewHidden { return }
        self.storiesQueue.async { [weak self] in
            guard let self = self else {
               return
            }
            self.arrayCompaniesTemp = self.coreDataHelp.getFromPersistentStore()
            self.arrayCompanies = self.arrayCompaniesTemp

            if self.arrayCompanies.count > 0 {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
        requestData()
    }
    
    ///Requests API for new data and then processes the data.
    func requestData() {
        let url = "https://angel.hirist.com/api7/stories?en_cookie=sVYq_SLASH_MHl4bYuo6ROMRVrdJpcSg0fZEC_PLUS_NCDpe11acqcLJUauKgx9ynVUafUCTsTBsL_PLUS_uC3HtrHAMRFWc0WkiOw_EQUALS__EQUALS_&debug=1"
        self.loadingSpinner.startRotating()
        networkHelp.jsonGetRequest(url: url, completionHandler: { jsonResponse, error in
            if error == nil {
                guard let json = jsonResponse, json["success"] as? Int == 1 else {
                    self.loadingSpinner.stopRotating(); return
                }
                guard let companyArray = json["companyStories"] as? [[String: Any]] else {
                    self.loadingSpinner.stopRotating(); return
                }
                
                self.storiesQueue.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    var arrayCompaniesTemp: [CompanyModel] = []
                    
                    for (company, index) in zip(companyArray, 1...companyArray.count) {
                        let companyObj = CompanyModel(company: company, rank: index)
                        arrayCompaniesTemp.append(companyObj)
                    }
                    
                    arrayCompaniesTemp = self.checkArrayCompanies(companies: arrayCompaniesTemp)
                    
                    arrayCompaniesTemp = self.prepareArrayCompanies(companies: arrayCompaniesTemp)
                    
                    self.arrayCompanies = self.appendSeenCompany(companies: arrayCompaniesTemp)
                    
                    DispatchQueue.main.async {
                        self.loadingSpinner.stopRotating()
                        self.collectionView.reloadData()
                    }
                    self.removeExpiredCacheData()
                }
            } else {
                self.loadingSpinner.stopRotating()
            }
        })
    }
    
    ///Checks if the number of **StoryModel** objects in **stories** array in **CompanyModel** are equal to storyCount.
    func checkArrayCompanies(companies: [CompanyModel]) -> [CompanyModel] {
        var arrayCompanies: [CompanyModel] = []
        for company in companies {
            if company.storyCount != company.stories.count || company.stories.isEmpty {
                ///remove element or don't add to arrayCompanies
            } else {
                arrayCompanies.append(company)
            }
        }
        return arrayCompanies
    }
    
    /**
     Adds seen and clapped information to new data from **arrayCompaniesTemp**.
     - parameter companies: array of **CompanyModel** objects.
     - returns: array of **CompanyModel** objects with the new information.
     */
    func prepareArrayCompanies(companies: [CompanyModel]) -> [CompanyModel] {
        ///sort stories based on created date
        for company in companies {
            company.stories.sort { $0.createdOn < $1.createdOn }
        }
        
        let oldCompanies = arrayCompaniesTemp
        
        ///add seen snd clap info into new arrayCompanies
        for newCompany in companies {
            for oldCompany in oldCompanies {
                if newCompany.companyId == oldCompany.companyId {
                    for newStory in newCompany.stories {
                        for story in oldCompany.stories {
                            if newStory.storyId == story.storyId {
                                newStory.isSeen = story.isSeen
                                newStory.isClapped = story.isClapped
                                break
                            }
                        }
                    }
                    break
                }
            }
        }
        return companies
    }
    
    /**
     Appends all the companies whose stories are fully seen.
     - parameter companies: array of **CompanyModel** objects.
     - returns: array of **CompanyModel** objects with appended companies.
    */
    func appendSeenCompany(companies: [CompanyModel]) -> [CompanyModel] {
        var seenCompanyArray: [CompanyModel] = []
        var unSeenCompanyArray: [CompanyModel] = []
        
        for company in companies {
            var allSeen = true
            for story in company.stories {
                if !story.isSeen {
                    allSeen = false
                    break
                }
            }
            if allSeen {
                seenCompanyArray.append(company)
            } else {
                unSeenCompanyArray.append(company)
            }
        }
        
        for company in seenCompanyArray {
            unSeenCompanyArray.append(company)
        }
        
        return unSeenCompanyArray
    }
    
    ///Removes expired cache from **.cachesDirectory**.
    ///
    ///Lists all the cache data and removes them if data's name is not present in new data (arrayCompanies) from API.
    ///**storyCompanyId** and **storyId** is used as name or key of cache data.
    func removeExpiredCacheData() {
        var arrayStoryIds: [String] = []
                   
        let companies = arrayCompanies
        
        for company in companies {
            arrayStoryIds.append(company.storyCompanyId)
            for story in company.stories {
                arrayStoryIds.append(story.storyId)
            }
        }

        let presentItems = cachingHelp.listCachedItems()

        for item in presentItems {
            if arrayStoryIds.contains(where: {$0 == item}) {
            } else {
                cachingHelp.removeCachedItem(localPathName: item)
            }
        }
    }
    
    ///Makes a new API call to get stories data. Used in case of **pull to refresh** etc.
    /// - Warning: Should not be used to make 1st API call
    func refreshMainView() {
        if isStoriesViewHidden { return }
        collectionView.setContentOffset(.zero, animated: false)
        arrayCompaniesTemp = arrayCompanies
        requestData()
    }
    
    ///Toggles *isStoriesViewHidden* flag and saves data to database.
    func hideStoriesView() {
        isStoriesViewHidden = true
        if arrayCompanies.count > 0 {
            coreDataHelp.saveToPersistentStore(companies: arrayCompanies)
        }
    }
    
    ///Toggles *isStoriesViewHidden* flag and triggers an API request.
    func unHideStoriesView() {
        isStoriesViewHidden = false
        collectionView.setContentOffset(.zero, animated: false)
        getData()
    }
    
    ///Calculates the width of each cell depending on the height and width of the collectionView.
    ///- returns: Width of a cell.
    func getCellWidth() -> CGFloat {
        let ratio = CELL_WIDTH_HEIGHT_RATIO
        let spaceBwCells = SPACE_BETWEEN_CELLS
        
        //check to avoid division by zero
        if ratio == 0 || collectionView.frame.height == 0 || collectionView.frame.width == 0 {
            return cellWidth
        }
        
        let number = (collectionView.frame.width - spaceBwCells) / ((ratio * collectionView.frame.height) + spaceBwCells)
        
        let spaceForCells = (collectionView.frame.width - (spaceBwCells * number))
        let spaceForCellsWithInsets = spaceForCells - spaceBwCells // left inset
        let widthOfCell = spaceForCellsWithInsets / number
        
        return widthOfCell
    }
    
    /**
     Calculates the height of **MainStoriesView** such that number of cells is between
     MAX_FULLY_VISIBLE_CELLS and MIN_FULLY_VISIBLE_CELLS.
     - parameter parentViewWidth: Width of the parent view.
     - returns: Calculated height.
     */
    func getMainStoriesViewHeight(parentViewWidth: CGFloat) -> CGFloat {
        let ratio = CELL_WIDTH_HEIGHT_RATIO
        let maxCells = MAX_FULLY_VISIBLE_CELLS
        let minCells = MIN_FULLY_VISIBLE_CELLS
        let spaceBwCells = SPACE_BETWEEN_CELLS
        
        let numberOfCells = (parentViewWidth - spaceBwCells) / ((ratio * DEFAULT_STORIES_HEIGHT) + spaceBwCells)
        if numberOfCells > maxCells {
            return (((parentViewWidth - spaceBwCells) / maxCells) - spaceBwCells) / ratio
        } else if numberOfCells < minCells && numberOfCells > 0  {
            return (((parentViewWidth - spaceBwCells) / minCells) - spaceBwCells) / ratio
        }
        return DEFAULT_STORIES_HEIGHT
    }
    
    /**
     Tells if all the stories are seen in a **CompanyModel** object.
     - parameter indexPath: Position of the item in *arrayCompanies*.
     - returns: True if all stories are seen.
     */
    func isStoriesSeen(indexPath: IndexPath) -> Bool {
        var allSeenFlag = true
        
        if indexPath.item >= arrayCompanies.count || indexPath.item < 0 { return false }
        
        for snap in arrayCompanies[indexPath.item].stories {
            if !snap.isSeen {
                allSeenFlag = false
                break
            }
        }
        return allSeenFlag
    }
}

extension MainStoriesView: StoryViewControllerDelegate {
    func reloadCollectionView(arrayCompanies: [CompanyModel]) {
        self.arrayCompanies = arrayCompanies
        collectionView.layoutIfNeeded()
        collectionView.reloadData()
    }
}

//MARK:- CollectionView DataSource
extension MainStoriesView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
       return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayCompanies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_REUSE_IDENTIFIER, for: indexPath) as? CompanyIconCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.item >= arrayCompanies.count || indexPath.item < 0 { return UICollectionViewCell() }
        
        cell.icon.ringView.image = isStoriesSeen(indexPath: indexPath) ? UIImage(named: "stories_ring_gray") : UIImage(named: "stories_ring")
        
        let company = arrayCompanies[indexPath.item]
        cell.companyId = company.storyCompanyId
        cell.companyTitle.text = company.companyName
        cell.getImage(address: company.companyLogo)
        
        return cell
    }
}

//MARK:- CollectionView Delegate
extension MainStoriesView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = StoryViewController(arrayCompanies: arrayCompanies, selectedCompanyIndex: indexPath.item)
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        if isStoriesSeen(indexPath: indexPath) {
            vc.isFirstLaunchStoriesSeen = true
        }
        self.parentVC.present(vc, animated: true)
    }
}

//MARK:- CollectionView FlowLayout Delegate
extension MainStoriesView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width:  cellWidth, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return SPACE_BETWEEN_CELLS
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: SPACE_BETWEEN_CELLS, bottom: 0, right: 0)
    }
}
