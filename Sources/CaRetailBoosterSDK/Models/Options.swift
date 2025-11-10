import Foundation
import CoreGraphics

public struct RtBSizeOption {
    public let width: CGFloat?
    public let height: CGFloat?

    public init(width: CGFloat? = nil, height: CGFloat? = nil) {
        self.width = width
        self.height = height
    }
}

public struct RtBBannerOptions {
    public let size: RtBSizeOption?

    public init(size: RtBSizeOption? = nil) {
        self.size = size
    }
}

public struct RtBRewardOptions {
    public let size: RtBSizeOption?

    public init(size: RtBSizeOption? = nil) {
        self.size = size
    }
}

public struct RtBPopupOptions {
    public init() {}
}
