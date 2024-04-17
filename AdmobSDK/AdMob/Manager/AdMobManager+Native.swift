//
//  AdMobManager+Native.swift
//  AdmobSDK
//
//  Created by macbook on 29/08/2021.
//

import Foundation
import GoogleMobileAds
import SkeletonView
import FirebaseAnalytics

public protocol NativeAdProtocol {
    var adUnitID: String? {get set}
    var gadNativeAd: GADNativeAd? {get set}
    
    func bindingData(nativeAd: GADNativeAd)
    
    func getGADView() -> GADNativeAdView
}

extension NativeAdProtocol {
    mutating func updateId(value: String) {
        adUnitID = value
    }
    
    mutating func reloadAdContent() {
        guard let adNative = gadNativeAd else { return }
        bindingData(nativeAd: adNative)
    }
}

public enum OptionAdType {
    case option_1
    case option_2
}

public enum NativeAdType {
    case small
    case medium
    case unified(OptionAdType)
    case freeSize
    case smallMedia
    case fullScreen
    case collectionViewCell
    case custom(nibName: String)
    
    var nibName: String {
        switch self {
        case .small:
            return "SmallNativeAdView"
        case .fullScreen:
            return "FullScreenNativeAdView"
        case .medium:
            return "MediumNativeAdView"
        case .unified(let option):
            switch option {
            case .option_1:
                return "UnifiedNativeAdView"
            case .option_2:
                return "UnifiedNativeAdView_2"
            }
        case .freeSize:
            return "FreeSizeNativeAdView"
        case .smallMedia:
            return "SmallMediaNativeAdView"
        case .collectionViewCell:
            return "CellMediaNativeAdView"
        case let .custom(nibName):
            return nibName
        }
    }
}

// MARK: - GADUnifiedNativeAdView
extension AdMobManager {
    
    private func getNativeAdLoader(unitId: AdUnitID) -> GADAdLoader? {
        return listNativeLoader[unitId.rawValue]
    }
    
    func getAdNative(unitId: String) -> NativeAdProtocol? {
        if let adNativeView = listNativeAd[unitId] {
            return adNativeView
        }
        return nil
    }
    
    private func createAdNativeView(unitId: AdUnitID, type: NativeAdType = .small) {
        if let _ = getAdNative(unitId: unitId.rawValue) {
            return
        }
        guard
            let nibObjects = Bundle.main.loadNibNamed(type.nibName, owner: nil, options: nil),
            let adNativeProtocol = nibObjects.first as? NativeAdProtocol else {
            return
        }
        listNativeAd[unitId.rawValue] = adNativeProtocol
    }
    
    private func reloadAdNative(unitId: AdUnitID) {
        if let loader = self.getNativeAdLoader(unitId: unitId) {
            loader.load(GADRequest())
        }
    }
    
    internal func preloadAdNative(unitId: AdUnitID,
                                  refreshAd: Bool = false,
                                  type: NativeAdType = .smallMedia,
                                  ratio: GADMediaAspectRatio = .portrait) {
        if let loader = getNativeAdLoader(unitId: unitId),
            loader.isLoading {
            return
        }
        if refreshAd {
            removeNativeAd(unitId: unitId.rawValue)
        }
        if getNativeAdLoader(unitId: unitId) != nil {
            return
        }
        guard let rootVC = UIApplication.getTopViewController() else {
            blockNativeFailed?(unitId.rawValue)
            return
        }
        createAdNativeView(unitId: unitId, type: type)
        loadAdNative(unitId: unitId, rootVC: rootVC, numberOfAds: 1, ratio: ratio)
    }
    
    internal func addAdNative(unitId: AdUnitID,
                              view: UIView? = nil,
                              refreshAd: Bool = false,
                              type: NativeAdType = .smallMedia,
                              ratio: GADMediaAspectRatio = .portrait) {
        if let loader = getNativeAdLoader(unitId: unitId),
            loader.isLoading { return }
        guard let rootVC = UIApplication.getTopViewController() else {
            blockNativeFailed?(unitId.rawValue)
            return
        }
        if refreshAd {
            removeNativeAd(unitId: unitId.rawValue)
            createAdNativeView(unitId: unitId, type: type)
            loadAdNative(unitId: unitId, rootVC: rootVC, numberOfAds: 1, ratio: ratio)
        } else {
            if var nativeAdProtocol = getAdNative(unitId: unitId.rawValue) {
                nativeAdProtocol.reloadAdContent()
                blockLoadNativeSuccess?(unitId.rawValue, nativeAdProtocol)
            } else {
                addAdNative(unitId: unitId, view: view, refreshAd: true, type: type, ratio: ratio)
            }
        }
    }
    
    private func loadAdNative(unitId: AdUnitID, rootVC: UIViewController, numberOfAds: Int, ratio: GADMediaAspectRatio) {
        if let loader = getNativeAdLoader(unitId: unitId) {
            loader.delegate = self
            loader.load(GADRequest())
            return
        }
        let multipleAdsOptions = GADMultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = numberOfAds
        let aspectRatioOption = GADNativeAdMediaAdLoaderOptions()
        aspectRatioOption.mediaAspectRatio = ratio
        let adLoader = GADAdLoader(adUnitID: unitId.rawValue,
                                   rootViewController: rootVC,
                                   adTypes: [ .native ],
                                   options: [multipleAdsOptions, aspectRatioOption])
        listNativeLoader[unitId.rawValue] = adLoader
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
}

// MARK: - GADUnifiedNativeAdDelegate
extension AdMobManager: GADNativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("ad==> nativeAdDidRecordClick ")
        logEventNative(nativeAd: nativeAd)
    }
    
    func logEventNative(nativeAd: GADNativeAd) {
        logEvenClick(id: nativeAd.advertiser ?? "")
    }
}

// MARK: - GADAdLoaderDelegate
extension AdMobManager: GADAdLoaderDelegate {
    
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("Native load error: \(error)")
        self.removeNativeAd(unitId: adLoader.adUnitID)
        self.blockNativeFailed?(adLoader.adUnitID)
    }
    
    public func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        listNativeLoader.removeValue(forKey: adLoader.adUnitID)
        print("ad==>ad==> adLoaderDidFinishLoading \(adLoader)")
    }
}

// MARK: - GADUnifiedNativeAdLoaderDelegate
extension AdMobManager: GADNativeAdLoaderDelegate {
    
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        nativeAd.delegate = self
        nativeAd.paidEventHandler = { value in
            self.trackAdRevenue(value: value, unitId: adLoader.adUnitID)
        }
        guard var nativeAdView = self.getAdNative(unitId: adLoader.adUnitID) else {return}
        nativeAd.mediaContent.videoController.delegate = self
        nativeAdView.getGADView().tag = 2
        nativeAdView.updateId(value: adLoader.adUnitID)
        nativeAdView.getGADView().hideSkeleton()
        nativeAdView.bindingData(nativeAd: nativeAd)
        blockLoadNativeSuccess?(adLoader.adUnitID, nativeAdView)
    }
    
    public func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("ad==> nativeAdDidRecordImpression")
    }
    
}

// MARK: - GADVideoControllerDelegate
extension AdMobManager: GADVideoControllerDelegate {
    
}
