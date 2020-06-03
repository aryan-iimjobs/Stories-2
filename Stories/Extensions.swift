//
//  Extensions.swift
//  Stories
//
//  Created by Aryan Sharma on 28/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import CoreData
import AVKit

extension UIView {
    ///Sarts a 360 degree rotation of the UIView
    func startRotating(duration: Double = 1) {
        DispatchQueue.main.async {
            let kAnimationKey = "rotation"
            self.alpha = 1
            if self.layer.animation(forKey: kAnimationKey) == nil {
                let animate = CABasicAnimation(keyPath: "transform.rotation")
                animate.duration = duration
                animate.repeatCount = Float.infinity
                animate.fromValue = 0.0
                animate.toValue = Float(.pi * 2.0)
                self.layer.add(animate, forKey: kAnimationKey)
            }
        }
    }
    ///Stops the 360 degree rotation of the UIView if already rotating.
    func stopRotating() {
        DispatchQueue.main.async {
            let kAnimationKey = "rotation"
            UIView.animate(withDuration: 1, animations: {
                self.alpha = 0
            }, completion: { finished in
                if self.layer.animation(forKey: kAnimationKey) != nil {
                    self.layer.removeAnimation(forKey: kAnimationKey)
                }
            })
        }
    }
}

extension AVPlayer {
    ///Seek player to zero and pause it.
    func stop(){
        self.seek(to: CMTime.zero)
        self.pause()
    }
}

extension UIViewController {
    ///Tells if the viewController is currently visible.
    public var isVisible: Bool {
        if isViewLoaded {
            return view.window != nil
        }
        return false
    }
    
    ///Tells if the viewController is at the top in the view stack.
    public var isTopViewController: Bool {
        if self.navigationController != nil {
            return self.navigationController?.visibleViewController === self
        } else if self.tabBarController != nil {
            return self.tabBarController?.selectedViewController == self && self.presentedViewController == nil
        } else {
            return self.presentedViewController == nil && self.isVisible
        }
    }
}

extension NSManagedObjectContext {
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
