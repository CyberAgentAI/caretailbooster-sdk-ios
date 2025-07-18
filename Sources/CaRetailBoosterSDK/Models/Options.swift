import Foundation
import CoreGraphics

public struct Options {
    var rewardAd: RewardAdOption?
    var rewardAdItemSpacing: CGFloat?
    var rewardAdLeadingMargin: CGFloat?
    var rewardAdTrailingMargin: CGFloat?
    var hiddenIndicators: Bool?

    public init(
        rewardAd: RewardAdOption? = nil,
        rewardAdItemSpacing: CGFloat? = nil,
        rewardAdLeadingMargin: CGFloat? = nil,
        rewardAdTrailingMargin: CGFloat? = nil,
        hiddenIndicators: Bool? = true
    ) {
        self.rewardAd = rewardAd
        self.rewardAdItemSpacing = rewardAdItemSpacing
        self.rewardAdLeadingMargin = rewardAdLeadingMargin
        self.rewardAdTrailingMargin = rewardAdTrailingMargin
        self.hiddenIndicators = hiddenIndicators
    }
}

public struct RewardAdOption {
    var width: CGFloat?
    var height: CGFloat?
    
    public init(width: Int?, height: Int?) {
        self.width = width.map { CGFloat($0) }
        self.height = height.map { CGFloat($0) }
    }
}
