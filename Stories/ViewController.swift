//
//  ViewController.swift
//  Stories
//
//  Created by iim jobs on 23/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var dotStories: MainStoriesView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dotStories = MainStoriesView(parentVC: self, isHidden: false)
        dotStories.translatesAutoresizingMaskIntoConstraints = false;
        view.addSubview(dotStories)
        
        dotStories.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true;
        dotStories.rightAnchor.constraint(equalTo:  view.rightAnchor).isActive = true;
        
        if #available(iOS 11.0, *) {
            dotStories.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            dotStories.topAnchor.constraint(equalTo:  view.topAnchor).isActive = true
        };
        
        let dotStoriesHeight = dotStories.getMainStoriesViewHeight(parentViewWidth: view.frame.width)
        
        dotStories.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true;
        dotStories.heightAnchor.constraint(equalToConstant: dotStoriesHeight).isActive = true;
        
    }
}

