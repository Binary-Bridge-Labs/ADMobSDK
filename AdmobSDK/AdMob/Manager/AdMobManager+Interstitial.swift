//
//  AdMobManager+Interstitial.swift
//  AdmobSDK
//
//  Created by Quang Ly Hoang on 22/02/2022.
//

import Foundation
import GoogleMobileAds
import FirebaseAnalytics

// MARK: - GADInterstitial
extension AdMobManager: GADFullScreenContentDelegate {
    
    /// khởi tạo id ads trước khi show
    public func createAdInterstitialIfNeed(unitId: AdUnitID, completion: BoolBlockAds? = nil) {
        if self.getAdInterstitial(unitId: unitId) != nil {
            completion?(true)
            return
        }
        
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: unitId.rawValue,
                               request: request,
                               completionHandler: { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                AdResumeManager.shared.isShowingAd = false
                self.removeAd(unitId: unitId.rawValue)
                self.blockFullScreenAdFailed?(unitId.rawValue)
                self.blockCompletionHandeler?(false)
                completion?(false)
                return
            }
            
            guard let ad = ad else {
                AdResumeManager.shared.isShowingAd = false
                self.removeAd(unitId: unitId.rawValue)
                self.blockFullScreenAdFailed?(unitId.rawValue)
                self.blockCompletionHandeler?(false)
                completion?(false)
                return
            }
            ad.fullScreenContentDelegate = self
            ad.paidEventHandler = { value in
                self.trackAdRevenue(value: value, unitId: ad.adUnitID)
            }
            self.listAd.setObject(ad, forKey: unitId.rawValue as NSCopying)
            self.blockLoadFullScreenAdSuccess?(unitId.rawValue)
            completion?(true)
        })
    }
    
    func getAdInterstitial(unitId: AdUnitID) -> GADInterstitialAd? {
        if let interstitial = listAd.object(forKey: unitId.rawValue) as? GADInterstitialAd {
            return interstitial
        }
        return nil
    }
    
    /// show ads Interstitial
    func presentAdInterstitial(unitId: AdUnitID) {
        self.createAdInterstitialIfNeed(unitId: unitId)
        let interstitial = self.getAdInterstitial(unitId: unitId)
        if let topVC =  UIApplication.getTopViewController() {
            print("topVC: \(String(describing: topVC.self))")
            interstitial?.present(fromRootViewController: topVC)
            AdResumeManager.shared.isShowingAd = true // kiểm tra nếu show inter thì ko show resume
        }
    }
    
    public func showIntertitial(unitId: AdUnitID,
                                isSplash: Bool = false,
                                blockWillDismiss: VoidBlockAds? = nil,
                                blockDidDismiss: VoidBlockAds? = nil) {
        if isSplash {
            AdResumeManager.shared.isShowingAd = true // kiểm tra nếu show inter thì ko show resume
            createAdInterstitialIfNeed(unitId: unitId) { [weak self] result in
                if result {
                    self?.isSplash = true
                    self?.showIntertitial(unitId: unitId, blockWillDismiss: blockWillDismiss, blockDidDismiss: blockDidDismiss)
                } else {
                    blockWillDismiss?()
                    blockDidDismiss?()
                }
            }
            return
        }
        
        if AdMobManager.shared.getAdInterstitial(unitId: unitId) != nil {
            AdResumeManager.shared.isShowingAd = true // kiểm tra nếu show inter thì ko show resume
            var rootVC = UIApplication.getTopViewController()
            if rootVC?.navigationController != nil {
                rootVC = rootVC?.navigationController
                if rootVC?.tabBarController != nil {
                    rootVC = rootVC?.tabBarController
                }
            }
            guard let rootVC = rootVC else { return }
            print("rootVC: \(rootVC)")
            let loadingVC = AdFullScreenLoadingVC.createViewController(unitId: unitId, adType: .interstitial(id: unitId))
            loadingVC.view.translatesAutoresizingMaskIntoConstraints = false
            loadingVC.blockDidDismiss = { [weak loadingVC] in
                loadingVC?.willMove(toParent: nil)
                loadingVC?.view.removeFromSuperview()
                loadingVC?.removeFromParent()
                self.isSplash = false
                blockDidDismiss?()
            }
            loadingVC.blockWillDismiss = blockWillDismiss
            rootVC.addChild(loadingVC)
            rootVC.view.addSubview(loadingVC.view)
            NSLayoutConstraint.activate([
                loadingVC.view.topAnchor.constraint(equalTo: rootVC.view.topAnchor, constant: 0),
                loadingVC.view.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor, constant: 0),
                loadingVC.view.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor, constant: 0),
                loadingVC.view.bottomAnchor.constraint(equalTo: rootVC.view.bottomAnchor, constant: 0)
            ])
            loadingVC.didMove(toParent: rootVC.parent)
        } else {
            createAdInterstitialIfNeed(unitId: unitId)
            blockWillDismiss?()
            blockDidDismiss?()
        }
    }
    
    // MARK: - GADInterstitialDelegate
    
    public func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.blockFullScreenAdWillDismiss?()
    }
    
    /// Tells the delegate that the ad failed to present full screen content.
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content. \(error)")
        UIApplication.shared.isStatusBarHidden = false
        var id = ""
        if let adId = (ad as? GADInterstitialAd)?.adUnitID {
            id = adId
        } else if let adId = (ad as? GADRewardedAd)?.adUnitID {
            id = adId
        }
        self.blockFullScreenAdFailed?(id)
        AdResumeManager.shared.isShowingAd = false
    }
    
    /// Tells the delegate that the ad presented full screen content.
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did present full screen content.")
        blockCompletionHandeler?(true)
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        UIApplication.shared.isStatusBarHidden = false
        blockFullScreenAdDidDismiss?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AdResumeManager.shared.isShowingAd = false
        }
        print("Ad did dismiss full screen content.")
    }
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        blockFullScreenAdClick?()
        if let ad = ad as? GADInterstitialAd {
            logEvenClick(id: ad.adUnitID)
        } else if let ad = ad as? GADRewardedAd {
            logEvenClick(id: ad.adUnitID)
        }
    }
}
