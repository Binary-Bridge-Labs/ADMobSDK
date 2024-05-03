//
//  AdvertManager.swift
//  Base
//
//  Created by Base on 10/08/2023.
//

import GoogleMobileAds
import UIKit

public protocol AdConfigId {
    
    var name: String { get }
    
    var adType: AdType { get }
    
    var adId: String { get }
    
    var isEnableAd: Bool { get }
    
}

public extension AdConfigId {
    
    var adUnitId: AdUnitID {
        return AdUnitID(rawValue: adId)
    }
    
    var isEnableAd: Bool {
        if IAPState.isUserVip {
            return false
        }
        switch adType {
        case .OpenApp:
            if !ADManager.shared.isShowOpen {
                return false
            }
        case .Banner:
            if !ADManager.shared.isShowBanner {
                return false
            }
        case .Reward:
            if !ADManager.shared.isShowReward {
                return false
            }
        case .Interstitial:
            if !ADManager.shared.isShowFull {
                return false
            }
        case .Native:
            if !ADManager.shared.isShowNative {
                return false
            }
        }
        return (RemoteConfigManager.shared.getValue(by: name)?.boolValue ?? false)
    }
    
}

public enum AdType: String {
    case OpenApp = "App Open"
    case Banner = "Banner"
    case Reward = "Reward"
    case Interstitial = "Interstitial"
    case Native = "Native"
}

public enum AdNativeSize: Int {
    case normal = 0
    case small = 1
}

public class ADManager: NSObject {
    
    public static let shared = ADManager()
    
    internal var isShowingAd = false // Cờ để check xem đang show quảng cáo hay không. Chỉ cho phép show 1 loại quảng cáo/1 thời điểm
    
    internal var timeShowOpen: Int = 0
    
    internal var showState: AdShowState?
    internal var configTime: AdConfigTime?
    
    override init() {
        super.init()
        self.showState = AdShowState(version: Bundle.main.releaseVersionNumber,
                                     isShowBanner: false,
                                     isShowOpen: false,
                                     isShowFull: false,
                                     isShowNative: false,
                                     isTestMode: false)
        timeShowOpen = 0
    }
    
    public func startAds(style: ThemeStyleAds = ThemeStyleAds.origin,
                  testIds: [String] = []) {
        if !testIds.isEmpty {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testIds
        }
        AdMobManager.shared.adsNativeColor = style
        DispatchQueue.main.asyncSafety {
            GADMobileAds.sharedInstance().start()
        }
    }
    
    public func disableAds() {
        self.showState = AdShowState(version: Bundle.main.releaseVersionNumber,
                                     isShowBanner: false,
                                     isShowOpen: false,
                                     isShowFull: false,
                                     isShowNative: false,
                                     isTestMode: false)
    }
    
    public func initialize(readConfig enable: Bool,
                    completion: @escaping ((_ success: Bool) -> Void)) {
        
        BBLLogging.d("ADMANAGER: \(enable)")
        
        if !enable {
            self.loadDefaults()
        } else {
            self.initialAdverts()
        }
        completion(true)
    }
    
}

public extension DispatchQueue {
    
    func asyncSafety(_ closure: @escaping () -> Void) {
        guard self === DispatchQueue.main && Thread.isMainThread else {
            DispatchQueue.main.async(execute: closure)
            return
        }
        closure()
    }
    
    func asyncSafety(execute: DispatchWorkItem) {
        guard self === DispatchQueue.main && Thread.isMainThread else {
            DispatchQueue.main.async(execute: execute)
            return
        }
        execute.perform()
    }
    
}

public extension Bundle {
    var releaseVersionNumber: String {
        return (infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    var buildVersionNumber: String {
        return (infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }
}
