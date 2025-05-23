//
//  Notification.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/14.
//
import SwiftUI

extension NSNotification {
    static let Alert = Notification.Name.init("Alert")
    // 通知名はFlutter側と合わせる
    static let FetchAds = Notification.Name.init("FetchAds")
}

