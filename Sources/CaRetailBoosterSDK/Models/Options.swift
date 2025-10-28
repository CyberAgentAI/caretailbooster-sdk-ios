import Foundation
import CoreGraphics

public struct SizeOption {
    public let width: CGFloat?
    public let height: CGFloat?

    public init(width: CGFloat? = nil, height: CGFloat? = nil) {
        self.width = width
        self.height = height
    }
}

public struct BannerOptions {
    public let size: SizeOption?

    public init(size: SizeOption? = nil) {
        self.size = size
    }
}

public struct RewardOptions {
    public let size: SizeOption?

    public init(size: SizeOption? = nil) {
        self.size = size
    }
}

public struct PopupOptions {
    public init() {}
}
