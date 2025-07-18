import Foundation

public struct Callback {
    var onMarkSucceeded: () -> Void?
    var onRewardModalClosed: () -> Void?
    
    public init(onMarkSucceeded: @escaping () -> Void?, onRewardModalClosed: @escaping () -> Void?) {
        self.onMarkSucceeded = onMarkSucceeded
        self.onRewardModalClosed = onRewardModalClosed
    }
}
