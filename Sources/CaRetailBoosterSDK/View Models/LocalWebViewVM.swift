import Foundation

@MainActor
@available(iOS 13.0, *)
class LocalWebViewVM: BaseWebViewVM {
    private func processWebResource(webResource: String) -> (inDirectory: String,
                                                             fileName: String,
                                                             fileExtension: String) {
        var wr = webResource
        
        if wr.hasPrefix("/") {
            // Remove leading "/"
            wr.remove(at: wr.startIndex)
        }
        
        if !wr.hasPrefix("Web/") {
            // Prepend "Web/"
            wr = "Web/" + wr
        }
        
        // Extract path, file name, and file extension. NSString provides
        // easier solution
        let nswr = NSString(string: wr)
        
        let pathName = nswr.deletingLastPathComponent
        let fileExtension = nswr.pathExtension
        let fileName = nswr.lastPathComponent.replacingOccurrences(of: ".\(fileExtension)", with: "")
        
        return (inDirectory: pathName,
                fileName: fileName,
                fileExtension: fileExtension)
    }
    
    override func loadWebPage(webResource: String) {
//        if let webResource = webResource {
            let (inDirectory,
                 fileName,
                 fileExtension) = processWebResource(webResource: webResource)
            
            guard let filePath = Bundle.main.path(forResource: fileName,
                                                  ofType: fileExtension,
                                                  inDirectory: inDirectory) else {
                print("Bad path")
                return
            }
            
            let url = URL(fileURLWithPath: filePath)
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
//        }
    }
}
