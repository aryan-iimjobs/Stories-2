//
//  StoryCell.swift
//  Stories
//
//  Created by Aryan Sharma on 27/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import AVKit

///Protocol needs to be implemented by the viewController containing the collectionView to which the cell is registered to.
///Defines  methods which instruct the collectionView if it needs to scroll to a new indexPath.
protocol StoryCellDelegate: class {
    ///collectionView needed to scroll to next indexPath.
    ///- parameter companyIndex: The current index of the company whose stories are visible.
    func moveToNextCompany(from companyIndex: Int)
    ///collectionView needed to scroll to previous indexPath.
    ///- parameter companyIndex: The current index of the company whose stories are visible.
    func moveToPreviousCompany(from companyIndex: Int)
    ///User tapped block button to block the current company from appearing.
    ///- parameter companyIndex: The current index of the company whose stories are visible.
    func didTapBlockButton(from companyIndex: Int)
}

///Cell for the collectionView of *StoryViewController*.
class StoryCell: UICollectionViewCell {
    weak var delegate: StoryCellDelegate?

    //MARK: flags
    ///Indicates if the viewController, the cell is in, is visible to the user, granted the cell was currently being displayed and the viewController is at the top of the stack.
    ///True by default. Focus is lost for like when the app goes to background.
    var isViewInFocus = true
    ///Indicates if the SegmentedProgressView has done layout.
    var isProgressBarPresent = false
    ///If the current cell is completely occupying the screen.
    var isCompletelyVisible = false
    ///Cell's data has loaded and SegmentedProgressView has statred filling.
    var isAnimating = false
    ///Story is paused and block company alert window is active.
    var isBlockAlertActive = false
    
    //MARK: properties
    ///Key used to store/retrieve cahce data for story. *storyCompanyId* of CompanyModel.
    var storyCompanyId: String!
    ///Position of  company cell is using data of in arrayCompanies.
    var parentCompanyIndex: Int!
    ///The story currently visible to the user.
    var currentSnap = 0
    ///Number of times user has pressed clap button, limit is 20.
    var clapNumber = 0
    
    //MARK: object references
    ///Reference to the viewController cell is used in.
    var parentVc: StoryViewController!
    ///Reference to the SegmentedProgressView.
    var progressBar: SegmentedProgressView!
    ///Timer used to hide clapped count number after a specific time.
    var clapTimer: Timer?
    let networkingHelp: StoriesNetworkingHelp = StoriesNetworkingHelp()
    let cachingHelp: StoriesCachingHelp = StoriesCachingHelp()
    
    //MARK: data holders
    ///Array of the stories of the company.
    var stories: [StoryModel]!
    ///Array of the Companies
    var arrayCompanies: [CompanyModel]!
    
    //MARK: view elements
    ///Company icon image in expanded story.
    let companyIcon: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 20
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.clipsToBounds = true
        iv.frame = CGRect(x: 15, y: 19, width: 40, height: 40)
        iv.isUserInteractionEnabled = true
        return iv
    }()

    ///Company title in expanded story.
    let companyTitle: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = .white
        //l.font = UIFont.newHiristFont(with: 15, type: .bold)
        l.font = UIFont(name: "HelveticaNeue",size: 15.0)
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 2.0
        l.layer.shadowOpacity = 1.0
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.masksToBounds = false
        return l
    }()
        
    ///Label of time elapsed from when the story was published.
    let dateLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = .white
        //l.font = UIFont.newHiristFont(with: 12, type: .light)
        l.font = UIFont(name: "HelveticaNeue",size: 12.0)
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 2.0
        l.layer.shadowOpacity = 1.0
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.masksToBounds = false
        return l
    }()
    
    ///Menu button, opens block company alert.
    let menuBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage(named: "stories_menu"), for: .normal)
        return btn
    }()
    
    ///Image to show swipe up direction.
    let upArrowImage: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "stories_topArrow")
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    ///Text to instruct user to swipe up.
    let swipeUpTextLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .white
        //l.font = UIFont.newHiristFont(with: 15, type: .bold)
        l.font = UIFont(name: "HelveticaNeue",size: 15.0)
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 2.0
        l.layer.shadowOpacity = 1.0
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.masksToBounds = false
        return l
    }()
    
    ///Text label that displays auto hiding clap number.
    let clapCount: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = .white
        //l.font = UIFont.newHiristFont(with: 15, type: .regular)
        l.font = UIFont(name: "HelveticaNeue",size: 12.0)
        l.text = "0"
        //l.backgroundColor = UIColor.getThemeOrangeColor()
        l.isHidden = true
        l.backgroundColor = .orange
        l.layer.masksToBounds = true
        l.textAlignment = .center;
        return l
    }()
        
    let clapBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage(named: "stories_clapunfilled"), for: .normal)
        return btn
    }()
    
    ///ImageView that holds a story image (type = 1 story).
    let snapImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    
    ///VideoView that plays a (type = 2 story) video story.
    let videoView: VideoView = {
        let i = VideoView()
        i.isHidden = true
        return i
    }()
    
    ///System loading indictor displayed when story data has not yet loaded.
    let loadingIndicator: UIActivityIndicatorView = {
        let l = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        l.hidesWhenStopped = true
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(companyIcon)
        companyIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(companyIconAction)))
        
        contentView.addSubview(companyTitle)
        
        contentView.addSubview(dateLabel)
        
        contentView.addSubview(menuBtn)
        menuBtn.addTarget(self, action: #selector(menuBtnAction), for: .touchUpInside)
        
        contentView.addSubview(upArrowImage)
        
        contentView.addSubview(swipeUpTextLabel)
        
        contentView.addSubview(clapCount)

        contentView.addSubview(clapBtn)
        clapBtn.addTarget(self, action: #selector(clapBtnAction), for: .touchUpInside)
        
        contentView.addSubview(snapImage)
        contentView.sendSubviewToBack(snapImage)
        
        videoView.snapVideo.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        contentView.addSubview(videoView)
        contentView.sendSubviewToBack(videoView)
        
        loadingIndicator.startAnimating()
        contentView.addSubview(loadingIndicator)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onlongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        addGestureRecognizer(longPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(tapRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        companyTitle.frame = CGRect(x: 65, y: 19, width: frame.width - 100, height: 20 )
        dateLabel.frame = CGRect(x: 65, y: 39, width: frame.width - 100, height: 16)
        menuBtn.frame = CGRect(x: frame.width - 48, y: 18, width: 40, height: 40)
        upArrowImage.frame = CGRect(x: 0, y: frame.height - 45 - 34, width: frame.width, height: 34)
        swipeUpTextLabel.frame = CGRect(x: 0, y: frame.height - 48, width: frame.width, height: 20)
        clapCount.frame = CGRect(x: frame.width - 71, y: frame.height - 180, width: 52, height: 52)
        clapCount.layer.cornerRadius = clapCount.frame.height / 2
        clapBtn.frame = CGRect(x: frame.width - 71, y: frame.height - 80, width: 52, height: 52)
        clapBtn.layer.cornerRadius = clapBtn.frame.height / 2
        
        snapImage.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        videoView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        loadingIndicator.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        companyIcon.image = nil
        companyTitle.text = ""
        dateLabel.text = ""
        upArrowImage.isHidden = true
        swipeUpTextLabel.text = ""
        clapCount.text = "0"
        clapBtn.setBackgroundImage(UIImage(named: "stories_clapunfilled"), for: .normal)

        snapImage.image = nil
        videoView.snapVideo.replaceCurrentItem(with: nil)
        loadingIndicator.startAnimating()

        currentSnap = 0
        clapNumber = 0
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === videoView.snapVideo.currentItem && keyPath == "status" {
            if videoView.snapVideo.status == .readyToPlay  && isViewInFocus && isCompletelyVisible {
                videoView.snapVideo.play()
                print("StoryCell: Ready to play video.")
            }
        }
        
        if object as AnyObject? === videoView.snapVideo && keyPath == "timeControlStatus" {
            if #available(iOS 10.0, *) {
                if videoView.snapVideo.timeControlStatus == .playing && isViewInFocus && isCompletelyVisible {
                    print("StoryCell : timeControlStatus == .playing")
                    var videoDuration: Double = 5
                    if let currentItem = videoView.snapVideo.currentItem {
                        videoDuration = currentItem.duration.seconds
                    }
                    startAnimatingStory(duration: videoDuration)
                    print("StoryCell: Video started animating.")
                }
            }
        }
    }
    
    ///Invoked by the menu button, which calls block current company delegate.
    @objc func menuBtnAction() {
        if !networkingHelp.isInternetReachable() {
            //error message
            //ErrorMessageView.shared()?.show(fromTop: "Please check your internet connection", view: self, andFromLogin: "no")
            return
        }
        
        if isAnimating, let delegate = self.delegate {
            delegate.didTapBlockButton(from: parentCompanyIndex)
            isBlockAlertActive = true
        }
    }
    
    ///Invoked when clap button is pressed and makes API request. Handles the bounce back animation of the button.
    @objc func clapBtnAction() {
        if !networkingHelp.isInternetReachable() {
            //error message
            //ErrorMessageView.shared()?.show(fromTop: "Please check your internet connection", view: self, andFromLogin: "no")
            return
        }
        
        if !isAnimating || clapNumber >= 20 {
            return
        }
        
        //check for user if logged in
//        guard let loggedInUser = IJModel.shared()?.loggedInUser, let cookie = loggedInUser.cookie else {
//            return
//        }
        
        clapCount.isHidden = false
        clapNumber += 1
        
        networkingHelp.postClapNumber(storyId: stories[currentSnap].storyId, totalClaps: clapNumber, completionHandler: {
            isSuccess in
            
            if isSuccess {
                self.stories[self.currentSnap].isClapped = true
            }
        })
        
        // animate clap
        UIView.animate(withDuration: 0.2,
        animations: {
            self.clapBtn.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        },
        completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.clapBtn.transform = CGAffineTransform.identity
            }
        })
        
        clapBtn.setBackgroundImage(UIImage(named: "stories_clapfilled"), for: .normal)
        clapCount.text = "\(clapNumber)"
        
        if (clapTimer != nil) {
            clapTimer?.invalidate()
        }
        clapTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(hideClapCount(_:)), userInfo: nil, repeats: true)
    }
    
    
    @objc func hideClapCount(_ timer: Timer) {
        clapCount.isHidden = true
        timer.invalidate()
    }
    
    ///Invoked by long press gesture. Pauses current story and hides/unhides UI elements.
    @objc func onlongPress(_ gesture: UILongPressGestureRecognizer) {
        if isAnimating {
            switch gesture.state {
                case UIGestureRecognizerState.began:
                    progressBar.pause()
                    videoView.snapVideo.pause()
                    hideUiElements()
                    break
                case UIGestureRecognizerState.ended:
                    progressBar.resume()
                    videoView.snapVideo.play()
                    unHideUiElements()
                    break
                default:
                    break
            }
        }
    }
    
    ///Hides all the UI elements except story image & video.
    func hideUiElements() {
        progressBar.isHidden = true
        companyIcon.isHidden = true
        companyTitle.isHidden = true
        dateLabel.isHidden = true
        menuBtn.isHidden = true
        clapBtn.isHidden = true
    }
    
    ///UnHides all the UI elements except story image & video.
    func unHideUiElements() {
        progressBar.isHidden = false
        companyIcon.isHidden = false
        companyTitle.isHidden = false
        dateLabel.isHidden = false
        menuBtn.isHidden = false
        clapBtn.isHidden = false
    }
    
    ///Invoked by tap gesture. Divides verticle screen into three parts for next/previous story.
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        let touch = sender.location(in: self)
        let screenWidthOneThird = frame.width / 3
        let screenWidthTwoThird = screenWidthOneThird * 2
        let absoluteTouchX = touch.x
        let absoluteTouchY = touch.y
        
        if absoluteTouchX < screenWidthOneThird {
            if absoluteTouchY > 100 {
                progressBar.rewind()
            } else {
                //nothing
            }
        } else if absoluteTouchX > screenWidthOneThird && absoluteTouchX < screenWidthTwoThird {
            //nothing
        } else {
            progressBar.skip()
        }
    }
    
    ///Invoked by clicking company's icon image to open Company's Showcase page.
    @objc func companyIconAction() {
        if parentVc.isFromShowcase { return }
        if arrayCompanies[parentCompanyIndex].showcaseDetail.v2showcaseId == "" {
            return
        }

//        let showcaseV2storyboard = UIStoryboard.init(name: "ShowcaseV2", bundle: nil);
//
//        var showcaseV2Vc: NewShowcaseViewController
//
//        if let showcase = showcaseV2storyboard.instantiateViewController(withIdentifier: "newShowcaseVC") as? NewShowcaseViewController {
//            showcaseV2Vc = showcase
//        } else { return }
//
//        viewFocusLost()
//
//        let showcaseDetail = arrayCompanies[parentStoryIndex].showcaseDetail
//
//        showcaseV2Vc.companyId = showcaseDetail.v2companyId
//        showcaseV2Vc.jsonFilePath = showcaseDetail.v2jsonFilePath
//        showcaseV2Vc.companyName = showcaseDetail.v2companyName
//        showcaseV2Vc.typeOfTemplate = showcaseDetail.v2templateType
//        showcaseV2Vc.origin = "Stories"
//        showcaseV2Vc.isFromStories = 1
//        showcaseV2Vc.storyCell = self
//
//        let navController = UINavigationController(rootViewController: showcaseV2Vc)
//        navController.modalPresentationStyle = .overFullScreen
//        navController.setNavigationBarHidden(true, animated: true)
//
//        parentVc.present(navController, animated: true)
    }
    
    ///The viewController gains user focus after coming back from background.
    ///Like on after status bar pull or putting app to background.
    func viewFocusGained() {
        if !parentVc.isTopViewController {
            return
        }
        if isBlockAlertActive { return }
        isViewInFocus = true
        if stories[currentSnap].storyType == 1 {
            if isAnimating {
                progressBar.resume()
            } else {
                animate()
            }
        } else {
            if isAnimating {
                videoView.snapVideo.play()
                progressBar.resume()
            } else {
                if videoView.snapVideo.status == .readyToPlay {
                    videoView.snapVideo.play()
                } else {
                    // do nothing
                }
            }
        }
    }
    
    ///The viewController losses user focus on going to background.
    ///Like on status bar pull or putting app to background.
    func viewFocusLost() {
        if isBlockAlertActive { return }
        isViewInFocus = false
        if stories[currentSnap].storyType == 1 {
            if isAnimating {
                progressBar.pause()
            } else {
                //do nothing
            }
        } else {
            if isAnimating {
                videoView.snapVideo.pause()
                progressBar.pause()
            } else {
                //do nothing
            }
        }
    }
    
    ///Create instance of *SegmentedProgressView* and prepare its layout.
    func initProgressbar() {
        if(progressBar != nil) { //avoid overlapping
            progressBar.removeFromSuperview()
        }
        progressBar = SegmentedProgressView(barCount: stories.count)
        progressBar.delegate = self
        progressBar.frame = CGRect(x: 0, y: 0, width: frame.width, height: 20)
        contentView.addSubview(progressBar)
        contentView.bringSubviewToFront(progressBar)
    }
    
    ///It triggers for story data (Images/video) to reload.
    func animate() {
        loadIconImage()
        loadSnapImage()
    }
    
    ///Run when story's data has loaded. Should start the filling of progressBar.
    ///- parameter duration: Time (in seconds) for which a current single story should run.
    func startAnimatingStory(duration: Double) {
        if !isAnimating && isCompletelyVisible && isViewInFocus {
            print("StoryCell: Loading snap \(currentSnap)")
            progressBar.animate(index: currentSnap, duration: duration)
            isAnimating = true
            loadingIndicator.stopAnimating()
        }
    }
    
    ///Prepares data for swipe up text label and makes arrow image visible for a story if swipe up function is present.
    func prepareSwipeUpData() {
        upArrowImage.isHidden = true
        swipeUpTextLabel.text = ""
        switch self.stories[self.currentSnap].linkType {
        case 0: // no linkType
            swipeUpTextLabel.text = ""
            upArrowImage.isHidden = true
            break
        case 1: // showcase
            swipeUpTextLabel.text = stories[currentSnap].linkData["linkText"] as? String
            upArrowImage.isHidden = false
            break
        case 2:// job detail
            swipeUpTextLabel.text = "Swipe up for job details."
            upArrowImage.isHidden = false
            break
        case 3:// recruiter profile
            self.swipeUpTextLabel.text = "Swipe up for recruiter profile."
            upArrowImage.isHidden = false
            break
        case 4: // external link
            self.swipeUpTextLabel.text = stories[currentSnap].linkData["linkText"] as? String
            upArrowImage.isHidden = false
            break
        default: ()
        }
    }
    
    ///Returns time elapsed from linux epoch time.
    ///- parameter epochTime: 13 digit linux epoch time, like: 1591017038380.
    func getElapsedInterval(epochTime: Int) -> String {
        let diff = Int64((Date().timeIntervalSince1970 * 1000) - TimeInterval(epochTime))
        let days = Int(diff / (1000 * 60 * 60 * 24))
        let hours = Int(diff / (1000 * 60 * 60))
        let mins = Int(diff / (1000 * 60))
        
        if mins < 60 {
            return "\(mins)m"
        } else if hours < 24 {
            return "\(hours)h"
        } else if days < 7 {
            return "\(days)d \(hours % 24)h"
        }
        return "\(days / 7)w"
    }
}

//MARK: Request data and store cache
extension StoryCell {
    ///If not present make API request to get company icon image data and then store in cache.
    ///- parameter address: String url of the image.
    func getIconImage(address: String) {
        if !cachingHelp.fileExists(key: storyCompanyId!) {
            networkingHelp.dataGetRequest(url: address, completionHandler: { response, error in
                if error == nil, let image = response {
                    self.cachingHelp.store(data: image, key: self.storyCompanyId!)
                }
            })
        }
    }
    
    func getSnapThumbnail(address: String, type: Int, index: Int) {
        if address != "" {
            networkingHelp.dataGetRequest(url: address, completionHandler: { response, error in
                if error == nil, let image = response {
                    if type == 1 && self.currentSnap == index && !self.isAnimating {
                        self.videoView.isHidden = true
                        self.snapImage.isHidden = false
                        
                        self.snapImage.image = UIImage(data: image)
                        self.loadingIndicator.stopAnimating()
                    }
                    else { /* video thumbnail */ }
                }
            })
        }
    }
    
    ///If not present make API request to get story image data and then store in cache.
    ///- parameter address: String url of the image.
    ///- parameter index:Position of the story data from stories of a Company.
    func getSnapImage(address: String, index: Int) {
        let story = stories[index]
        let storyId = story.storyId
        let type = story.storyType
        if !cachingHelp.fileExists(key: storyId) {
            getSnapThumbnail(address: story.thumbnailPath, type: type, index: index)
            if type == 1 {
                networkingHelp.dataGetRequest(url: address, completionHandler: { response, error in
                    if error == nil, let image = response {
                        self.cachingHelp.store(data: image, key: storyId)
                        
                        if self.isCompletelyVisible && index == self.currentSnap {
                            self.animate()
                            self.loadingIndicator.stopAnimating()
                        }
                    }
                })
            }
        }
    }
}

//MARK: Load stories data
extension StoryCell {
    ///Retrieve the Company icon image from cache.
    func loadIconImage() {
        if cachingHelp.fileExists(key: storyCompanyId) {
            companyIcon.image = cachingHelp.retrieveImage(key: storyCompanyId)
        }
    }

    ///Retrieve the Story image from cache.
    func loadSnapImage() {
        let currentStory = stories[currentSnap]
        
        let time = currentStory.createdOn
        dateLabel.text = getElapsedInterval(epochTime: time)
        
        let storyId = currentStory.storyId
        let type = currentStory.storyType
        
        if (currentStory.isClapped) {
            clapBtn.setBackgroundImage(UIImage(named: "stories_clapfilled"), for: .normal)
        } else {
            clapBtn.setBackgroundImage(UIImage(named: "stories_clapunfilled"), for: .normal)
        }
        
        if cachingHelp.fileExists(key: storyId) {
            if type == 1 {
                loadingIndicator.stopAnimating()
                videoView.isHidden = true
                snapImage.isHidden = false
                snapImage.image = cachingHelp.retrieveImage(key: storyId)
                
                startAnimatingStory(duration: 5)
            }
        } else {
            if type == 2 {
                if isCompletelyVisible {
                    snapImage.isHidden = true
                    videoView.isHidden = false
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        guard let url = URL(string: currentStory.s3Path) else {
                            return
                        }
                        let asset = AVAsset(url: url)
                        let item = AVPlayerItem(asset: asset)
                        
                        DispatchQueue.main.async {
                            self.videoView.snapVideo.replaceCurrentItem(with: item)
                            self.videoView.snapVideo.currentItem?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
                        }
                    }
                }
            }
        }
    }
}

//MARK: SegmentedProgressViewDelegate
extension StoryCell: SegmentedProgressViewDelegate {
    func segmentedProgressBarChangedIndex(index: Int) {
        print("StoryCell: index changed delegate")
        if isAnimating {
            stories[currentSnap].isSeen = true
        }

        currentSnap = index
        isAnimating = false
    
        clapNumber = 0
        snapImage.image = nil
        videoView.isHidden = true
        videoView.snapVideo.replaceCurrentItem(with: nil)
        loadingIndicator.startAnimating()
        
        prepareSwipeUpData()
        animate()
    }
    
    func segmentedProgressBarsFinished(left: Bool) {
        if isAnimating {
            stories[currentSnap].isSeen = true
        }
        
        currentSnap = 0
        
        if left {
            delegate?.moveToPreviousCompany(from: parentCompanyIndex)
        } else {
            delegate?.moveToNextCompany(from: parentCompanyIndex)
        }
    }
}
