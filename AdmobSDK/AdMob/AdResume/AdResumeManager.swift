//
//  AdResumeManager.swift
//  AdmobSDK
//
//  Created by ANH VU on 21/01/2022.
//

import GoogleMobileAds
import UIKit
import FirebaseAnalytics

open class AdResumeManager: NSObject {
    private var backgroudView: UIView?
    public static let shared = AdResumeManager()
    
    public let timeoutInterval: TimeInterval = 4 * 3600
    public var isLoadingAd = false
    public var isShowingAd = false
    public var resumeAdId: AdUnitID?
    private var appOpenAd: GADAppOpenAd?
    public var appOpenAdManagerDelegate: ((_ showed: Bool) -> Void)?
    var loadTime: Date?
    public var adResumeLoadingString = "Welcome back"
    
    private var showVC: UIViewController?
    public var blockadDidDismissFullScreenContent: VoidBlockAds?
    public var blockAdResumeClick                : VoidBlockAds?
    
    private func wasLoadTimeLessThanNHoursAgo(timeoutInterval: TimeInterval) -> Bool {
        // Check if ad was loaded more than n hours ago.
        if let loadTime = loadTime {
            return Date().timeIntervalSince(loadTime) < timeoutInterval
        }
        return false
    }
    
    public func isAdAvailable(id: String) -> Bool {
        // Check if ad exists and can be shown.
        return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInterval: timeoutInterval)
    }
    
    public func loadAd(adId: AdUnitID? = nil, completion: ((Bool) -> Void)? = nil) {
        if isLoadingAd { return }
        var ads = resumeAdId
        if adId != nil {
            ads = adId
        }
        guard let id = ads?.rawValue else {
            completion?(false)
            return
        }
        if isAdAvailable(id: id) {
            completion?(true)
            return
        }
        isLoadingAd = true
        GADAppOpenAd.load(withAdUnitID: id,
                          request: GADRequest()) { ad, error in
            self.isLoadingAd = false
            if let error = error {
                self.appOpenAd = nil
                self.loadTime = nil
                completion?(false)
                print("App open ad failed to load with error: \(error.localizedDescription).")
                return
            }
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
            print("App open ad loaded successfully.")
            completion?(true)
        }
    }
    
    private func showAdAvailable(id: String,
                                 viewController: UIViewController) -> Bool {
        if let ad = appOpenAd {
            print("App open ad will be displayed.")
            isShowingAd = true
            showVC = viewController
            if showVC?.navigationController != nil {
                showVC = showVC?.navigationController
                if showVC?.tabBarController != nil {
                    showVC = showVC?.tabBarController
                }
            }
            guard let showVC = showVC else { return false }
            
            let loadingVC = AdFullScreenLoadingVC()
            loadingVC.needLoadAd = false
            loadingVC.isOpenAd = true
            loadingVC.modalPresentationStyle = .fullScreen
            var parentWindow: UIWindow?
            if let window = UIApplication.shared.keyWindow {
                parentWindow = window
            } else if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                parentWindow = window
            } else {
                parentWindow = nil
            }
            if let window = parentWindow,
               let viewContent = loadingVC.view {
                viewContent.translatesAutoresizingMaskIntoConstraints = false
                window.addSubview(viewContent)
                showVC.view.endEditing(true)
                NSLayoutConstraint.activate([
                    window.topAnchor.constraint(equalTo: viewContent.topAnchor, constant: 0),
                    window.bottomAnchor.constraint(equalTo: viewContent.bottomAnchor, constant: 0),
                    window.leadingAnchor.constraint(equalTo: viewContent.leadingAnchor, constant: 0),
                    window.trailingAnchor.constraint(equalTo: viewContent.trailingAnchor, constant: 0)
                ])
            } else {
                return false
            }
            
            ad.paidEventHandler = { [weak self] value in
                if let adNetworkName = ad.responseInfo.adNetworkInfoArray.first?.adNetworkClassName {
                    print("Ad Network Name: \(adNetworkName)")
                    AdMobManager.shared.trackAdRevenue(format: .appOpen,
                                                       value: value,
                                                       unitId: self?.resumeAdId?.rawValue ?? "",
                                                       adNetwork: adNetworkName)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                loadingVC.view.removeFromSuperview()
                loadingVC.removeFromParent()
                loadingVC.willMove(toParent: nil)
                self.addBackGroundViewWhenShowAd()
                ad.present(fromRootViewController: showVC)
            }
            return true
        }
        return false
    }
    
    public func showOpenAd(adId: AdUnitID, viewController: UIViewController) {
        if isShowingAd {
            print("App open ad is already showing.")
            self.appOpenAdManagerDelegate?(true)
            return
        }
        let id = adId.rawValue
        if !isAdAvailable(id: id) {
            print("App open ad is not ready yet. Loading...")
            loadAd(adId: adId) { [weak self] loaded in
                if loaded {
                    _ = self?.showAdAvailable(id: id,
                                              viewController: viewController)
                } else {
                    self?.appOpenAdManagerDelegate?(false)
                }
            }
            return
        }
        _ = showAdAvailable(id: id,
                            viewController: viewController)
    }
    
    public func showAdIfAvailable(id: String,
                                  viewController: UIViewController) -> Bool {
        if isShowingAd {
            print("App open ad is already showing.")
            return false
        }
        if !isAdAvailable(id: id) {
            print("App open ad is not ready yet.")
            appOpenAdManagerDelegate?(false)
            loadAd()
            return false
        }
        return showAdAvailable(id: id,
                               viewController: viewController)
    }
    
    private func addBackGroundViewWhenShowAd() {
        DispatchQueue.main.asyncSafety { [weak self] in
            self?.removeBackGroundWhenDismissAd()
            self?.backgroudView = UIView()
            guard let backgroundView = self?.backgroudView else { return }
            backgroundView.backgroundColor = .white
            backgroundView.tag = 1000
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func removeBackGroundWhenDismissAd() {
        DispatchQueue.main.asyncSafety { [weak self] in
            self?.backgroudView?.removeFromSuperview()
            self?.backgroudView = nil
        }
    }
}

extension AdResumeManager: GADFullScreenContentDelegate {
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        removeBackGroundWhenDismissAd()
        appOpenAd = nil
        showVC = nil
        isShowingAd = false
        print("App open ad was dismissed.")
        appOpenAdManagerDelegate?(true)
        loadAd()
        blockadDidDismissFullScreenContent?()
    }
    
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isShowingAd = true
        print("App open ad is presented.")
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        appOpenAd = nil
        isShowingAd = false
        print("App open ad failed to present with error: \(error.localizedDescription).")
        appOpenAdManagerDelegate?(false)
        loadAd()
    }
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        blockAdResumeClick?()
        if ad is GADAppOpenAd {
            AdMobManager.shared.logEvenClick(id: resumeAdId?.rawValue ?? "")
        }
    }
}

