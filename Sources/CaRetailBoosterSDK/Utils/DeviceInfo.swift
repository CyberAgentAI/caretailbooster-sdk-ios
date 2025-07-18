//
//  DeviceInfo.swift
//  AdSDKSampler
//
//  Created by Masaaki Yoda on 2025/01/31.
//

import Foundation
import AdSupport
import UIKit

@MainActor
struct DeviceInfo {
    static var make: String {
        "Apple"
    }

    static var os: String {
        UIDevice.current.systemName
    }

    static var osVersion: String {
        UIDevice.current.systemVersion
    }

    static var hwv: String {
        UIDevice.current.modelIdentifier
    }

    static var height: Int {
        Int(UIScreen.main.bounds.height)
    }

    static var width: Int {
        Int(UIScreen.main.bounds.width)
    }

    static var language: String {
        if #available(iOS 16, *) {
            Locale.current.language.languageCode?.identifier ?? ""
        } else {
            // Fallback on earlier versions
            Locale.current.languageCode ?? ""
        }
    }

    static var ifa: String {
        let manager = ASIdentifierManager.shared()
        guard manager.isAdvertisingTrackingEnabled else {
            return ""
        }
        return manager.advertisingIdentifier.uuidString
    }
}

extension UIDevice {
    var modelIdentifier: String {
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let machineMirror: Mirror = Mirror(reflecting: systemInfo.machine)
        let identifier: String = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
