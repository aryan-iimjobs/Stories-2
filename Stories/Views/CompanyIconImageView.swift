//
//  CompanyIconImageView.swift
//  Stories
//
//  Created by Aryan Sharma on 28/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

///Custom UIView that has a imageView (Company's Icon) overlapping a slightly bigger imageView (Circular Ring).
///
///Used to simulate whether a company's story is seen or not by changing the overlapped imageView.
class CompanyIconImageView: UIView {
    
    //MARK: constant values
    ///Space between ringView and the imageView.
    let PADDING: CGFloat = 4
    
    //MARK: UIViews
    ///Overlapping imageView holds icon image of the company.
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .white
        iv.clipsToBounds = false
        return iv
    }()
    ///Overlapped imageView holds the circular ring image.
    let ringView: UIImageView = {
        let iv = UIImageView()
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = UIColor(displayP3Red: 128/255, green: 128/255, blue: 128/255, alpha: 0.11).cgColor
        imageView.layer.borderWidth = 1
        addSubview(imageView)
            
        addSubview(ringView)
        sendSubviewToBack(ringView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.layer.cornerRadius = (frame.width - (PADDING * 2)) / 2
        imageView.frame = CGRect(x: PADDING, y: PADDING, width: frame.width - (PADDING * 2), height: frame.height - (PADDING * 2))
        
        ringView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
