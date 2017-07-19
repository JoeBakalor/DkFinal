//
//  UIViewExtensions.swift
//  LiveSYNCiPad
//
//  Created by Joe Bakalor on 1/10/17.
//  Copyright © 2017 Joe Bakalor. All rights reserved.
//

import Foundation
import UIKit

extension UIView
{
    func rotate360Degrees(duration: CFTimeInterval = 5.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 8.0)
        rotateAnimation.duration = duration
        
        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate as? CAAnimationDelegate
        }
        self.layer.add(rotateAnimation, forKey: nil)
    }
}
