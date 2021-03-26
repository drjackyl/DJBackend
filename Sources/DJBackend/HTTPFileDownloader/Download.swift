import Foundation

public struct Download {
    public init(url: URL, destination: URL, progress: Double) {
        self.url = url
        self.destination = destination
        self.progress = progress
    }
    
    public let url: URL
    public let destination: URL
    public let progress: Double
}






























