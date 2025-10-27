import SwiftUI

@available(iOS 13.0, *)
public protocol Ad {
    var tagGroupId: String { get }
    var eventName: String? { get }
    func load() async throws
}

@available(iOS 13.0, *)
public protocol ViewableAd: Ad {
    var views: [AnyView] { get }
}

@available(iOS 13.0, *)
public protocol OverlayAd: Ad {
    func show(from viewController: UIViewController?)
}
