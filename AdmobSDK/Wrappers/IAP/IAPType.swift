//
//  IAPIdType.swift
//  Base
//
//  Created by BBLabs on 22/12/2022.
//

import Foundation

public struct SubscriptionInfo: Decodable {
    let subscriptionId: String?
    let bestPrice: Bool?
    let timeExpired: String?
    
    private enum CodingKeys: String, CodingKey {
        case subscriptionId
        case bestPrice
        case timeExpired
    }
    
    public var time2Date: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let time = timeExpired {
            return dateFormatter.date(from: time)
        }
        return nil
    }
    
    public var timeDiscount: TimeInterval? {
        return (time2Date?.timeIntervalSince1970 ?? 0) - Date().timeIntervalSince1970
    }
}

public protocol IAPType {
    
    var title: String {
        get
    }
    
    var numberDay: Int {
        get
    }
    
    var unit: String {
        get
    }
    
    var id: String {
        get
    }
    
}

public extension IAPType {
    
    var localizedPrice: String {
        return InappManager.share.listProduct.first(where: {$0.productIdentifier == self.id})?.localizedPrice ?? ""
    }
    
    var freeday: Int {
        return InappManager.share.getFreedaysTrial(id: id)
    }
    
    var price: String {
        return InappManager.share.getPrice(id: id)
    }
    
    var discountPrice: String {
        return InappManager.share.getDiscountPrice(id: id)
    }
    
    var priceLocale: Locale {
        return InappManager.share.getPriceLocale(id: id)
    }
    
    var discountPriceLocale: Locale {
        return InappManager.share.getDiscountPriceLocale(id: id)
    }
    
    var priceNumb: NSDecimalNumber {
        return InappManager.share.getPriceNumb(id: id)
    }
    
    var discountPriceNumb: NSDecimalNumber {
        return InappManager.share.getDiscountPriceNumb(id: id)
    }
    
    var discountPeriod: TimeInterval {
        return InappManager.share.getDiscountPeriod(id: id)
    }
    
    var isBestPrice: Bool {
        guard let subscriptions = RemoteConfigManager.shared.objectJson(forKey: DefaultRemoteKey.subscriptionList, type: [SubscriptionInfo].self) else { return false}
        return subscriptions.first(where: {
            ($0.subscriptionId == id) && ($0.bestPrice ?? false)
        }) != nil
    }
    
    var timeExpired: Date? {
        guard let subscriptions = RemoteConfigManager.shared.objectJson(forKey: DefaultRemoteKey.subscriptionList, type: [SubscriptionInfo].self) else { return nil }
        return subscriptions.first(where: {
            ($0.subscriptionId == id)
        })?.time2Date
    }
    
    var timeDiscount: TimeInterval {
        guard let subscriptions = RemoteConfigManager.shared.objectJson(forKey: DefaultRemoteKey.subscriptionList, type: [SubscriptionInfo].self) else { return 0 }
        return subscriptions.first(where: {
            ($0.subscriptionId == id)
        })?.timeDiscount ?? 0
    }
    
    static func getIdsOption() -> [String] {
        guard let subscriptions = RemoteConfigManager.shared.objectJson(forKey: DefaultRemoteKey.subscriptionList, type: [SubscriptionInfo].self) else { return [] }
        return subscriptions.sorted { type1, type2 in
            return (type1.bestPrice ?? false) && !(type2.bestPrice ?? false)
        }.compactMap({
            $0.subscriptionId
        })
    }
}
