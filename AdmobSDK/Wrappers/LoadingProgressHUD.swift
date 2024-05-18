//
//  LoadingProgressHUD.swift
// PetTranslate-iOS
//
//  Created by BBLabs on 3/16/23.
//  Copyright © 2024 BBLabs.All rights reserved.
//

import Foundation
import Lottie
import SVProgressHUD
import UIKit

public struct LoadingConfig {
    public var isUsingSVProgressHUD = true
    public var colorBGDimmer: UIColor? = .black.withAlphaComponent(0.5)
    public var colorBGHUD: UIColor? = .white
    public var hudWidth: CGFloat = 80
    public var hudHeight: CGFloat = 80
    public var animationName: String? = ""
    public var hudCorner: CGFloat = 10.0
    
    public static let defaultConfig = LoadingConfig()
}

public class LoadingProgressHUD: UIView {
    
    private static let shared = LoadingProgressHUD()
    private let hudView = LottieAnimationView()
    
    private var isAddedHUD = false
    
    var config: LoadingConfig = LoadingConfig.defaultConfig {
        didSet {
            setup()
        }
    }
    
    // options
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    public static func setConfig(config: LoadingConfig) {
        shared.config = config
    }
    
    private func setup() {
        self.isUserInteractionEnabled = true
        self.frame = UIScreen.main.bounds
        self.backgroundColor = config.colorBGDimmer
        hudView.backgroundColor = config.colorBGHUD
        hudView.roundCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                       .layerMinXMaxYCorner, .layerMaxXMaxYCorner],
                             radius: config.hudCorner)
        hudView.translatesAutoresizingMaskIntoConstraints = false
        if isAddedHUD { return }
        self.addSubview(hudView)
        NSLayoutConstraint.activate([
            hudView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            hudView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
            hudView.widthAnchor.constraint(equalToConstant: config.hudWidth),
            hudView.heightAnchor.constraint(equalToConstant: config.hudHeight)
        ])
        isAddedHUD = true
    }
    
    private func show() {
        self.isHidden = false
        guard let fileName = config.animationName else { return }
        self.hudView.loadAnimation(file: fileName,
                                   loopMode: .loop,
                                   autoPlay: true)
        self.fadeIn()
    }
    
    private func hide() {
        DispatchQueue.main.asyncSafety{
            self.hudView.stop()
            self.fadeOut()
            self.isHidden = true
            self.removeFromSuperview()
        }
    }
    
    public class func isVisible() -> Bool {
        if shared.config.isUsingSVProgressHUD {
            return SVProgressHUD.isVisible()
        }
        return !LoadingProgressHUD.shared.isHidden && (LoadingProgressHUD.shared.superview != nil)
    }
    
    public class func show() {
        if shared.config.isUsingSVProgressHUD {
            SVProgressHUD.show()
            return
        }
        DispatchQueue.main.asyncSafety{
            let progressHUD = LoadingProgressHUD.shared
            if isVisible() { return }
            if let currentController = UIApplication.shared.delegate?.getRootViewController() {
                currentController.view.addSubview(progressHUD)
            } else {
                if let window = UIApplication.shared.keyWindow {
                    window.addSubview(progressHUD)
                }
            }
            progressHUD.show()
        }
    }
    
    public class func dismiss() {
        if shared.config.isUsingSVProgressHUD {
            SVProgressHUD.dismiss()
            return
        }
        DispatchQueue.main.asyncSafety{
            LoadingProgressHUD.shared.hide()
        }
    }
    
    private func fadeIn(_ duration: TimeInterval = 1.0,
                        delay: TimeInterval = 0.0,
                        completion: ((Bool) -> Void)? = nil) {
        self.alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.alpha = 1.0
        }, completion: completion)
    }
    
    private func fadeOut(_ duration: TimeInterval = 1.0, 
                         delay: TimeInterval = 0.0,
                         completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
}
