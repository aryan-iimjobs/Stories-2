//
//  CompanyIconCell.swift
//  Stories
//
//  Created by Aryan Sharma on 24/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

///Cell for the collectionView of *MainStoriesView*
class CompanyIconCell: UICollectionViewCell {
    
    //MARK: constant values
    ///Space between the company icon and company title.
    let GAP_ICON_TITLE: CGFloat = 5
    ///Space between the cell and the icon.
    let padding: CGFloat = 7 // bw cell and icon
    
    //MARK: properties
    ///Key used to store cache. It is *storyCompanyId* from **CompanyModel**.
    var companyId: String?
    
    //MARK: object refrences
    let cachingHelp: StoriesCachingHelp = StoriesCachingHelp()
    let networkingHelp: StoriesNetworkingHelp = StoriesNetworkingHelp()
    
    //MARK: UIViews
    ///Instance of **CompanyIconImageView**.
    ///View that displays company icon.
    let icon: CompanyIconImageView = {
        let i = CompanyIconImageView()
        i.backgroundColor = .white
        return i
    }()
    
    ///Label to display title of the company.
    let companyTitle: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .black
        l.lineBreakMode = .byTruncatingTail
        //l.font = UIFont.newHiristFont(with: 12, type: .regular)
        l.font = UIFont(name: "HelveticaNeue",size: 12.0)
        l.alpha = 0.40
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(icon)
        addSubview(companyTitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        icon.frame = CGRect(x: padding, y: padding, width: frame.width - (padding * 2), height: frame.width - (padding * 2))
        icon.layer.cornerRadius = (frame.width - padding * 2)  / 2
        
        companyTitle.frame = CGRect(x: 0, y: icon.frame.height + GAP_ICON_TITLE, width: frame.width, height: frame.height - icon.frame.height - GAP_ICON_TITLE)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        icon.imageView.image = nil
        icon.ringView.image = nil
        companyTitle.text = ""
    }
    
    ///It either checks for comapny icon in cache or makes a request to API and then displays it.
    ///- parameter address: Link to download the company icon image.
    func getImage(address: String) {
        guard let key = companyId else {
            return
        }
        
        if cachingHelp.fileExists(key: key) {
            icon.imageView.image = cachingHelp.retrieveImage(key: key)
        } else {
            networkingHelp.dataGetRequest(url: address, completionHandler: { data, error in
                if error == nil {
                    if let imageData = data {
                        if let parentKey = self.companyId, parentKey == key { // onReuse, image is only loaded into the parent cell
                            self.icon.imageView.image = UIImage(data: imageData)
                        }
                        self.cachingHelp.store(data: imageData, key: key)
                    }
                } 
            })
        }
    }
}
