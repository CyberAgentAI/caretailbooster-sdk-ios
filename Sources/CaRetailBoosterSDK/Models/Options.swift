import Foundation
import CoreGraphics

public struct Options {
    var size: SizeOption?
    var itemSpacing: CGFloat?
    var leadingMargin: CGFloat?
    var trailingMargin: CGFloat?
    var hiddenIndicators: Bool?

    public init(
        size: SizeOption? = nil,
        itemSpacing: CGFloat? = nil,
        leadingMargin: CGFloat? = nil,
        trailingMargin: CGFloat? = nil,
        hiddenIndicators: Bool? = true
    ) {
        self.size = size
        self.itemSpacing = itemSpacing
        self.leadingMargin = leadingMargin
        self.trailingMargin = trailingMargin
        self.hiddenIndicators = hiddenIndicators
    }
}

public struct SizeOption {
    var width: CGFloat?
    var height: CGFloat?
    
    public init(width: Int?, height: Int?) {
        self.width = width.map { CGFloat($0) }
        self.height = height.map { CGFloat($0) }
    }
}
