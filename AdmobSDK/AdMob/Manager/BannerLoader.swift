//
//  BannerLoader.swift
//  AdmobSDK
//
//  Created by Lê Minh Sơn on 8/6/24.
//

import GoogleMobileAds
import SkeletonView
import FirebaseAnalytics

struct BannerLoaded {
    var timeLoaded: Date
    var bannerView: GADBannerView
}

// MARK: - GADBannerView
class BannerLoader: NSObject {
    
    internal static let shared = BannerLoader()
    public var timeReloadBanner: TimeInterval = 30 // 30s
    private var listBannerCachedAd: [String: BannerLoaded?] = [:]
    private var listLoadingAd: [String] = []
    public var skeletonGradient = UIColor.clouds
    
    private var listDelegate: [String: ((_ unitId: String, _ success: Bool) -> Void)] = [:]
    private var listDelegateBannerClick: [String: ((_ unitId: String) -> Void)] = [:]
    
    fileprivate func getAdBannerView(unitId: AdUnitID) -> GADBannerView? {
        if let bannerLoaded = listBannerCachedAd[unitId.rawValue] {
            let timeLoaded = bannerLoaded?.timeLoaded
            let timeDistance = Date().timeIntervalSince1970 - (timeLoaded?.timeIntervalSince1970 ?? 0)
            if (timeDistance / 1000) > timeReloadBanner {
                return nil
            }
            return bannerLoaded?.bannerView
        }
        return nil
    }
    
    public func createAdBannerIfNeed(unitId: AdUnitID) -> (isNew: Bool, view: GADBannerView) {
        if let adBannerView = self.getAdBannerView(unitId: unitId) {
            return (isNew: false, view: adBannerView)
        }
        let adBannerView = GADBannerView()
        adBannerView.adUnitID = unitId.rawValue
        adBannerView.paidEventHandler = { value in
            self.trackAdRevenue(value: value, unitId: adBannerView.adUnitID ?? "")
        }
        adBannerView.delegate = self
        return (isNew: true, view: adBannerView)
    }
    
    // quảng cáo xác định kích thước
    public func addAdBanner(unitId: AdUnitID,
                            rootVC: UIViewController,
                            view: UIView,
                            completion: @escaping(_ unitId: String, _ success: Bool) -> Void,
                            clickBanner: @escaping(_ unitId: String) -> Void) {
        listDelegate[unitId.rawValue] = completion
        listDelegateBannerClick[unitId.rawValue] = clickBanner
        if listLoadingAd.contains(where: { $0 == unitId.rawValue }) { return}
        let (isNew, adBannerView) = self.createAdBannerIfNeed(unitId: unitId)
        adBannerView.removeFromSuperview()
        adBannerView.rootViewController = rootVC
        view.addSubview(adBannerView)
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.gray.cgColor
        adBannerView.delegate = self
        adBannerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if isNew {
            if view.isSkeletonable == false {
                adBannerView.isSkeletonable = true
                let gradient = SkeletonGradient(baseColor: self.skeletonGradient)
                adBannerView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight, duration: 0.7))
            }
            let request = GADRequest()
            adBannerView.load(request)
        }
    }
    
    // Quảng cáo Collapsible đặt ở bottom, lần đầu sẽ mở rộng
    public func addAdCollapsibleBannerAdaptive(unitId: AdUnitID,
                                               rootVC: UIViewController,
                                               view: UIView,
                                               isCollapsibleBanner: Bool = false,
                                               isTop: Bool,
                                               completion: @escaping(_ unitId: String, _ success: Bool) -> Void,
                                               clickBanner: @escaping(_ unitId: String) -> Void) {
        listDelegate[unitId.rawValue] = completion
        listDelegateBannerClick[unitId.rawValue] = clickBanner
        if listLoadingAd.contains(where: { $0 == unitId.rawValue }) { return}
        let (isNew, adBannerView) = self.createAdBannerIfNeed(unitId: unitId)
        adBannerView.removeFromSuperview()
        adBannerView.rootViewController = rootVC
        view.addSubview(adBannerView)
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.gray.cgColor
        adBannerView.delegate = self
        
        adBannerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if isNew {
            if view.isSkeletonable == false {
                adBannerView.isSkeletonable = true
                let gradient = SkeletonGradient(baseColor: self.skeletonGradient)
                adBannerView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight, duration: 0.7))
            }
            
            adBannerView.adSize =  GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(screenWidthAds)
            let request = GADRequest()
            let gadExtras = GADExtras()
            gadExtras.additionalParameters = ["collapsible":
                                                (isTop ? "top" : "bottom")]
            request.register(gadExtras)
            adBannerView.load(request)
        }
    }
    
    
    // quảng có thích ứng với chiều cao không cố định
    public func addAdBannerAdaptive(unitId: AdUnitID,
                                    rootVC: UIViewController,
                                    view: UIView,
                                    completion: @escaping(_ unitId: String, _ success: Bool) -> Void,
                                    clickBanner: @escaping(_ unitId: String) -> Void) {
        listDelegate[unitId.rawValue] = completion
        listDelegateBannerClick[unitId.rawValue] = clickBanner
        if listLoadingAd.contains(where: { $0 == unitId.rawValue }) { return}
        let (isNew, adBannerView) = self.createAdBannerIfNeed(unitId: unitId)
        adBannerView.removeFromSuperview()
        adBannerView.rootViewController = rootVC
        view.addSubview(adBannerView)
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.gray.cgColor
        adBannerView.delegate = self
        
        adBannerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if isNew {
            if view.isSkeletonable == false {
                adBannerView.isSkeletonable = true
                let gradient = SkeletonGradient(baseColor: self.skeletonGradient)
                adBannerView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight, duration: 0.7))
            }
            
            adBannerView.adSize =  GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(screenWidthAds)
            let request = GADRequest()
            adBannerView.load(request)
        }
    }
    
    
}

// MARK: - GADBannerViewDelegate
extension BannerLoader: GADBannerViewDelegate {
    
    // MARK: - GADBanner delegate
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        let adUnitID = bannerView.adUnitID ?? ""
        print("ad==> bannerView did load \(adUnitID)")
        bannerView.hideSkeleton()
        bannerView.superview?.hideSkeleton()
        let bannerLoaded = BannerLoaded(timeLoaded: Date(),
                                        bannerView: bannerView)
        listBannerCachedAd[adUnitID] = bannerLoaded
        listLoadingAd.removeAll { $0 == adUnitID }
        listDelegate[adUnitID]?(adUnitID, true)
        listDelegate.removeValue(forKey: adUnitID)
        listDelegate[adUnitID] = nil
    }
    
    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("ad==> bannerView faild \(error.localizedDescription)")
        bannerView.delegate = nil
        let adUnitID = bannerView.adUnitID ?? ""
        listLoadingAd.removeAll { $0 == adUnitID }
        listDelegate[adUnitID]?(adUnitID, false)
        listDelegate.removeValue(forKey: adUnitID)
        listDelegate[adUnitID] = nil
    }
    
    
    public func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        if let adUnitID = bannerView.adUnitID {
            self.listBannerCachedAd.removeValue(forKey: adUnitID)
            self.listBannerCachedAd[adUnitID] = nil
        }
    }
    
    public func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("ad==> adViewDidRecordImpression bannerView\(bannerView.adUnitID ?? "")")
        bannerView.delegate = nil
        bannerView.hideSkeleton()
        bannerView.superview?.hideSkeleton()
    }
    
    public func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        if let adUnitID = bannerView.adUnitID {
            listDelegateBannerClick[adUnitID]?(adUnitID)
        }
        AdMobManager.shared.logEvenClick(id: bannerView.adUnitID ?? "")
    }
    
    //    MARK: - Track Ad Revenue
    func trackAdRevenue(value: GADAdValue, unitId: String) {
        Analytics.logEvent("paid_ad_impression_value", parameters: ["adunitid" : unitId, "value" : "\(value.value.doubleValue)"])
    }
    
    func logEvenClick(id: String) {
        Analytics.logEvent("user_click_ads", parameters: ["adunitid" : id])
    }
    
}

