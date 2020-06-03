//
//  StoryViewController.swift
//  Stories
//
//  Created by Aryan Sharma on 25/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

///Protocol must be  implemented by **MainStoriesView**.
///Contains methods that relay changes to the MainStoriesView.
protocol StoryViewControllerDelegate: class {
    ///Reloads the collection view of the MainStoriesView after its data source is updated.
    ///- parameter arrayCompanies: Updated array with changes from **StoryViewController**.
    func reloadCollectionView(arrayCompanies: [CompanyModel])
}

///The View Controller is initiated from *MainStoriesView*, it holds a collectionView that shows expanded stories.
class StoryViewController: UIViewController {

    weak var delegate: StoryViewControllerDelegate?
    
    //MARK: constants
    let CELL_REUSE_IDENTIFIER = "StoryCell"
    
    //MARK: properties
    ///Index of the company whose stories are dsiplayed on first launch, selected by the user.
    var selectedCompanyIndex: Int
    ///Index of the company whose stories are currently being displayed.
    var currentCompanyIndex: Int
    ///Global variable used to store CGPoint at which swipe down began.
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    ///Height of the notch if present in the screen.
    var topSafeAreaMargin: CGFloat = 0
    
    //MARK: flags
    ///**False** if first launched company's stories are not all seen, **True** if all the stories are seen.
    var isFirstLaunchStoriesSeen = false
    ///Is the viewController initiated after receiving a notification from a company's showcase page.
    var isFromShowcase = false
    ///Set to false when any other company's stories are displayed except the one selected by the user when
    ///initiating the StoryViewController.
    var isFirstLaunch = true
    
    //MARK: object references
    let networkingHelp: StoriesNetworkingHelp = StoriesNetworkingHelp()
    
    //MARK: data holders
    ///Array of the *CompanyModel* objects passed to the StoryViewController from MainStoriesView.
    var arrayCompanies: [CompanyModel]
    
    //MARK: UIViews
    ///Horizontal collectionView of the expanded stories. Uses *AnimatedCollectionViewLayout* for *cube* tranisition effect as layout.
    let collectionView: UICollectionView = {
        let layout = AnimatedCollectionViewLayout()
        layout.animator = CubeAttributesAnimator(perspective: -1/100, totalAngle: .pi/12)
        layout.scrollDirection = .horizontal;
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout);
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.isPrefetchingEnabled = true
        return cv;
    }();
    
    /**
    Creates a **StoryViewController** instance.
    - parameter arrayCompanies: Array of currently being used *CompanyModel* objects.
    - parameter selectedCompanyIndex: Index of the company selected by the user.
    - returns: Instance of **StoryViewController**.
    */
    init(arrayCompanies: [CompanyModel], selectedCompanyIndex: Int ) {
        self.selectedCompanyIndex = selectedCompanyIndex
        self.arrayCompanies = arrayCompanies
        self.currentCompanyIndex = selectedCompanyIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true // disable auto-lock
        
        addNotificationObservers()
        
        collectionView.register(StoryCell.self, forCellWithReuseIdentifier: CELL_REUSE_IDENTIFIER)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor(displayP3Red: 38/255, green: 38/255, blue: 38/255, alpha: 1)
        collectionView.decelerationRate = .fast
        collectionView.layer.cornerRadius = 0
        view.addSubview(collectionView)
        
        addGestureRecognizers()
    }
    
    override func viewWillLayoutSubviews() {
        if #available(iOS 11.0, *) {
            topSafeAreaMargin = view.safeAreaInsets.top
        }
        collectionView.frame = CGRect(x: 0, y: topSafeAreaMargin, width: UIScreen.main.bounds.width, height:  UIScreen.main.bounds.height - topSafeAreaMargin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLaunch {
            let indexPath = IndexPath(item: selectedCompanyIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get {
            return .portrait // only portrait allowed
        }
    }
    
    func addNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appBackToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func addGestureRecognizers() {
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeUp(_:)))
        swipeUpRecognizer.direction = .up
        swipeUpRecognizer.numberOfTouchesRequired = 1
        view.addGestureRecognizer(swipeUpRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.swipeDown(_:)))
        panRecognizer.require(toFail: swipeUpRecognizer)
        view.addGestureRecognizer(panRecognizer)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("StoryViewController: viewWillDisappear")
        
        UIApplication.shared.isIdleTimerDisabled = false // enable auto-lock
        
        sortAndAppendSeenCompany()
        
        delegate?.reloadCollectionView(arrayCompanies: arrayCompanies)
        
        if let cell = mostVisibleCell() {
            cell.videoView.snapVideo.replaceCurrentItem(with: nil)
        }
    }
        
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let cell = mostVisibleCell() else {
            return
        }
        cell.progressBar.resetBars()
    }
    
    ///Fired by *UIApplication.didBecomeActiveNotification* system notification
    ///when the app gets back to foreground from background.
    @objc func appBackToForeground() {
        print("StoryViewController: View back in Foreground")
        UIApplication.shared.isIdleTimerDisabled = true // enable auto-lock
        
        guard let cell = mostVisibleCell() else {
            return
        }
        cell.viewFocusGained()
    }
    
    ///Fired by *UIApplication.willResignActiveNotification* system notification
    ///when the app goes to background from foreground.
    @objc func appMovedToBackground() {
        print("StoryViewController: moved to background")
        UIApplication.shared.isIdleTimerDisabled = false // enable auto-lock
        guard let cell = mostVisibleCell() else {
            return
        }
        cell.viewFocusLost()
    }
    
    ///Appends all the companies whose stories are fully seen and then sorts them as they came from API thorugh rank.
    func sortAndAppendSeenCompany() {
        var seenCompanyArray: [CompanyModel] = []
        var unSeenCompanyArray: [CompanyModel] = []
        
        for company in arrayCompanies {
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

        seenCompanyArray.sort {$0.rank < $1.rank}
        
        for company in seenCompanyArray {
            unSeenCompanyArray.append(company)
        }
        
        arrayCompanies = unSeenCompanyArray
    }
    
    ///Handles swipe up gestures.
    @objc func swipeUp(_ sender: UISwipeGestureRecognizer) {
        if sender.direction != .up { return }
        
        guard let cell = mostVisibleCell() else {
            return
        }
        
        if cell.currentSnap >= cell.stories.count || cell.currentSnap < 0 { return }
        let story = cell.stories[cell.currentSnap]
        
        switch story.linkType {
        case 0: // no linkType
            cell.swipeUpTextLabel.text = ""
            break
        case 1: // external showcase
            var urlString = story.linkUrl
            
            if var url = URL(string: urlString) {
                if !UIApplication.shared.canOpenURL(url) {
                    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                        urlString = "http://" + urlString
                        if let newUrl = URL(string: urlString), UIApplication.shared.canOpenURL(newUrl) {
                            url = newUrl
                        } else { break }
                    } else { break }
                }
                cell.viewFocusLost()
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:],
                      completionHandler: {
                        (success) in
                      })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            break
        case 2:// job detail
            let jobId = story.linkData["jobId"]
            if let jobId = (jobId as? String), jobId != "" {
                openJobDetail(jobId: jobId, storyCell: cell)
            }
            break
        case 3:// recruiter profile
            let dictionary = story.linkData
            openRecruiterProfile(linkData: dictionary, storyCell: cell)
            break
        case 4: // external link
            var urlString = story.linkUrl
            
            if var url = URL(string: urlString) {
                if !UIApplication.shared.canOpenURL(url) {
                    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                        urlString = "http://" + urlString
                        if let newUrl = URL(string: urlString), UIApplication.shared.canOpenURL(newUrl) {
                            url = newUrl
                        } else { break }
                    } else { break }
                }
                cell.viewFocusLost()
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:],
                      completionHandler: {
                        (success) in
                      })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            break
        default: ()
        }
    }
    
    ///Presents Recruiter Profile viewController, invoked from swipe up gesture.
    ///- parameter linkData: Data to be passed to Recruiter Profile viewController.
    ///- parameter storyCell: The cell from which swipe up gesture occured.
    func openRecruiterProfile(linkData: [String:Any], storyCell: StoryCell) {
           storyCell.viewFocusLost()
           
//           let newScreensStoryboard = UIStoryboard.init(name: "NewScreens", bundle: nil)
//           guard let newRecruiterProfileVC = newScreensStoryboard.instantiateViewController(withIdentifier: "newRecruiterProfileVC") as? NewRecruiterProfileViewController else { storyCell.viewFocusGained(); return }
//
//           newRecruiterProfileVC.recruiterId = "\(linkData["id"] as? Int ?? 0)"
//
//           let recruiterDic = ["recruiterPic": linkData["image"] as? String ?? "", "recruiterName": linkData["name"] as? String ?? "", "recruiterDesignation": linkData["designation"] as? String ?? ""]
//           newRecruiterProfileVC.recruiterDic = recruiterDic
//
//           newRecruiterProfileVC.storyCell = storyCell
//
//           let navController = UINavigationController(rootViewController: newRecruiterProfileVC)
//           navController.modalPresentationStyle = .overFullScreen
//           navController.setNavigationBarHidden(false, animated: true)
//
//           self.present(navController, animated: true)
    }
    
    ///Presents JobDetail viewController, invoked from swipe up gesture.
    ///- parameter jobId: Id used to retrieve data for specific job from API.
    ///- parameter storyCell: The cell from which swipe up gesture occured.
    func openJobDetail(jobId: String, storyCell: StoryCell) {
//        SVProgressHUD.show()
//        view.isUserInteractionEnabled = false
//        storyCell.viewFocusLost()
//
//        ServiceManager.fetchJobDetails(unpublished: false, with: jobId) { (jobViewModel, error) in
//            SVProgressHUD.dismiss()
//            self.view.isUserInteractionEnabled = true
//
//            if let error = error {
//                ErrorMessageView.shared()?.show(fromTop: error.localizedDescription, view: self.view, andFromLogin: "no")
//                storyCell.viewFocusGained()
//            } else if let jobFeedViewModel = jobViewModel {
//
//                let storyBoard: UIStoryboard = UIStoryboard(name: "NewScreens", bundle: nil)
//
//                guard let newJobDescriptionVC = storyBoard.instantiateViewController(withIdentifier: "newJobDescriptionVC") as? JobDescriptionViewController else { storyCell.viewFocusGained(); return }
//
//                newJobDescriptionVC.jobViewModel = jobFeedViewModel
//                newJobDescriptionVC.jobIndex = 0
//                //newJobDescriptionVC.jdSourceType = .notification
//                newJobDescriptionVC.storyCell = storyCell
//
//                let navController = UINavigationController(rootViewController: newJobDescriptionVC)
//                navController.setNavigationBarHidden(false, animated: true)
//                navController.modalPresentationStyle = .overFullScreen
//
//                self.present(navController, animated: true, completion: nil)
//            } else {
//                storyCell.viewFocusGained()
//            }
//        }
    }
    
    ///Handles swipe down gesture and dismisses the StoryViewController.
    @objc func swipeDown(_ sender: UIPanGestureRecognizer) {
        guard let cell = mostVisibleCell(), let window = view.window else {
            return
        }
        
        let touchPoint = sender.location(in: window)
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
            cell.viewFocusLost()
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                collectionView.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y + topSafeAreaMargin, width: collectionView.frame.size.width, height: collectionView.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 200 {
                UIView.animate(withDuration: 0.15, animations: {
                    self.collectionView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)

                }, completion: { finished in
                    if cell.isAnimating {
                        if cell.currentSnap >= cell.stories.count || cell.currentSnap < 0 {
                            self.dismiss(animated: true, completion: nil)
                        }
                        cell.stories[cell.currentSnap].isSeen = true
                    }
                    self.dismiss(animated: true, completion: nil)
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.collectionView.frame = CGRect(x: 0, y: self.topSafeAreaMargin, width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)
                }, completion: { finished in
                    cell.viewFocusGained()
                })
            }
        }
    }
    
    /**
    Tells if all the stories are seen in a **CompanyModel** object.
    - parameter indexPath: Position of the item in *arrayCompanies*.
    - returns: True if all stories are seen.
    */
    func isStoriesSeen(indexPath: IndexPath) -> Bool {
        //check if all stories are seen in a company
        if indexPath.item >= arrayCompanies.count || indexPath.item < 0 { return false }
        
        var allSeenFlag = true
        for snap in arrayCompanies[indexPath.item].stories {
            if !snap.isSeen {
                allSeenFlag = false
                break
            }
        }
        return allSeenFlag
    }
}

//MARK:- CollectionView DataSource
extension StoryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        arrayCompanies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_REUSE_IDENTIFIER, for: indexPath) as? StoryCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.item >= arrayCompanies.count || indexPath.item < 0 { return UICollectionViewCell() }
        
        let company = arrayCompanies[indexPath.item]
        
        cell.parentVc = self
        cell.parentCompanyIndex = indexPath.item
        cell.arrayCompanies = arrayCompanies
        cell.stories = company.stories
        cell.storyCompanyId = company.storyCompanyId
        cell.initProgressbar()
        
        cell.companyTitle.text = company.companyName
    
        cell.getIconImage(address: company.companyLogo)
        
        for i in 0..<company.stories.count {
            let snap = company.stories[i]
            cell.getSnapImage(address: snap.s3Path, index: i)
        }
        
        cell.delegate = self
        
        if isFirstLaunch && selectedCompanyIndex == indexPath.row {
            print("StoryViewController: first launch")
            isFirstLaunch = false
            currentCompanyIndex = selectedCompanyIndex
            cell.isCompletelyVisible = true
        }
        
        for i in 0..<company.stories.count { // jump over seen and start from first unSeen story
            let snap = company.stories[i]
            if !snap.isSeen {
                cell.progressBar.startfrom(index: i)
                cell.currentSnap = i
                break
            }
        }
        
        cell.prepareSwipeUpData()
        
        cell.loadIconImage()
        cell.loadSnapImage()
        
        return cell
    }
}

//MARK:- CollectionView FlowLayout Delegate
extension StoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    //handle when scrolling over cells
    //not called when programmatically scrolling, like on tap/auto
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        collectionView.isUserInteractionEnabled = true
        
        guard let cell = mostVisibleCell() else {
            return
        }
        
        if cell.parentCompanyIndex != currentCompanyIndex {
            cell.isCompletelyVisible = true
            cell.animate()
            currentCompanyIndex = cell.parentCompanyIndex
        } else {
            cell.viewFocusGained()
        }
    }
    
    //disable user interaction when scrolling fast using tap
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if selectedCompanyIndex != 0 && isFirstLaunch {
            //do nothing
        } else {
            collectionView.isUserInteractionEnabled = false
        }
    }
    
    //handle pause all when swipe through cell started
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if isFromShowcase { self.dismiss(animated: true, completion: nil); return }
        guard let cell = mostVisibleCell() else {
            return
        }
        cell.viewFocusLost()
    }
    
    //Handle progressView when auto/tap scroll over stories
    //not called when scrolling over cells
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        collectionView.isUserInteractionEnabled = true
        
        guard let cell = mostVisibleCell() else {
            return
        }

        if cell.parentCompanyIndex != currentCompanyIndex {
            cell.isCompletelyVisible = true
            cell.animate()
            currentCompanyIndex = cell.parentCompanyIndex
        } else {
            //print("..but same cell")
        }
    }
    
    ///Finds out the cell which is in focus.
    ///- returns: StoryCell type cell.
    func mostVisibleCell() -> StoryCell? {
        var cell: StoryCell?
        let visibleCells = collectionView.visibleCells
        
        if visibleCells.isEmpty { return nil }
        
        if visibleCells.count > 1 {
            let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            let visibleIndexPath: IndexPath? = collectionView.indexPathForItem(at: visiblePoint)
            
            if let indexPath = visibleIndexPath {
                cell = collectionView.cellForItem(at: indexPath) as? StoryCell
            } else { return nil }
        } else {
            cell = visibleCells.first as? StoryCell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("StoryViewController: endedDisplay of \(indexPath.item)")
        guard let oldCell = cell as? StoryCell else {
            return
        }
        
        if oldCell.isAnimating {
            if oldCell.currentSnap >= oldCell.stories.count || oldCell.currentSnap < 0 { return }
            oldCell.stories[oldCell.currentSnap].isSeen = true
        }
        
        oldCell.unHideUiElements()
        oldCell.progressBar.resetBars()
        oldCell.isCompletelyVisible = false
        oldCell.isAnimating = false
        oldCell.videoView.snapVideo.replaceCurrentItem(with: nil)
        oldCell.isViewInFocus = true
    }
}

//MARK:- StoryCell delegates
extension StoryViewController: StoryCellDelegate {
    func moveToNextCompany(from companyIndex: Int) {
        if isFromShowcase { self.dismiss(animated: true, completion: nil); return }
        if companyIndex < arrayCompanies.count - 1 {
            print("StoryViewController: next Story")
            let indexPath = IndexPath(item: companyIndex + 1, section: 0)
            
            if isFirstLaunchStoriesSeen {
                print("StoryViewController: next story AllSeen so exit")
                self.dismiss(animated: true, completion: nil)
            }
            
            var allNextSeen = true
            for index in (companyIndex+1)..<arrayCompanies.count {
                let indexPathTemp = IndexPath(item: index, section: 0)
                if !isStoriesSeen(indexPath: indexPathTemp) {
                    allNextSeen = false
                    break
                }
            }
            
            if !self.isFirstLaunchStoriesSeen && allNextSeen {
                print("StoryViewController: from !seen but upcoming seen")
                self.dismiss(animated: true, completion: nil)
            } else {
                collectionView.scrollToItem(at: indexPath, at: .right, animated: true)
            }
        } else {
            print("StoryViewController: exit from right")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func moveToPreviousCompany(from companyIndex: Int) {
        if isFromShowcase { self.dismiss(animated: true, completion: nil); return }
        if companyIndex >= 1 && !isFirstLaunchStoriesSeen {
            print("StoryViewController: previous Story")
            let indexPath = IndexPath(item: companyIndex - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        } else {
            print("StoryViewController: exit from left")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func didTapBlockButton(from companyIndex: Int) {
        guard let cell = mostVisibleCell(), companyIndex == currentCompanyIndex else {
            return
        }

//        guard let loggedInUser = IJModel.shared()?.loggedInUser, let cookie = loggedInUser.cookie else {
//            return
//        }

        print("StoryViewController: block Company  pressed")
        cell.progressBar.pause()
        cell.videoView.snapVideo.pause()
        
        let alert = UIAlertController(title: "Block '\(arrayCompanies[currentCompanyIndex].companyName)'?", message: "You will no longer receive stories from this company. ", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Block", comment: "Default action"), style: .destructive, handler: { _ in
            
            let companyId = self.arrayCompanies[self.currentCompanyIndex].companyId
            
            //SVProgressHUD.show()
            self.networkingHelp.blockCompanyRequest(companyId: companyId, completionHandler: { isSuccess in
                if isSuccess {
                    for (company, index) in zip(self.arrayCompanies, 0..<self.arrayCompanies.count) {
                        if company.companyId == self.arrayCompanies[self.currentCompanyIndex].companyId {
                            self.arrayCompanies.remove(at: index)
                            break
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                }
                //SVProgressHUD.dismiss()
            })
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Default action"), style: .cancel, handler: { _ in
            cell.isBlockAlertActive = false
            cell.progressBar.resume()
            cell.videoView.snapVideo.play()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
