import Foundation

@available(iOS 13.0, *)
enum ModalType: Equatable {
    case video(url: String)
    case videoSurvey(url: String)
    case survey(url: String)
    case none
    
    var url: String? {
        switch self {
        case .video(let url), .videoSurvey(let url), .survey(let url):
            return url
        case .none:
            return nil
        }
    }
    
    var isPresented: Bool {
        self != .none
    }
}
