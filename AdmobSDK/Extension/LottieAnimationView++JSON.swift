//
//  LottieAnimationView++JSON.swift
// RemoveObject
//
//  Created by BBLabs on 05/04/2023.
//  Copyright © 2024 BBLabs. All rights reserved.
//

import Foundation
import Lottie

extension LottieAnimationView {
    
    public func loadAnimation(file name: String, loopMode: LottieLoopMode = .playOnce, autoPlay: Bool = true) {
        
        let animation = LottieAnimation.named(name)
        self.animation = animation
        self.contentMode = .scaleAspectFit
        self.loopMode = loopMode
        if autoPlay {
            self.play()
        }
    }
    
}
