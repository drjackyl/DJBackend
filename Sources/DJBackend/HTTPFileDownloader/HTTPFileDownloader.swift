import Foundation
import Combine





public class HTTPFileDownloader {
    
    // MARK: - Internal API
    
    /**
     Starts a download of the given URL and moves the downloaded data to the destination URL on completion
     
     - Parameter url: URL to download from
     - Parameter destination: File-URL to move the downloaded data to on completion.
     - Parameter expectedDownloadSize: Used for progress-calculation, if provided.
     */
    public func download(_ url: URL, to destination: URL, expectedDownloadSize: Int64? = nil) -> AnyPublisher<Download, HTTPFileDownloader.Error> {
        return downloader.download(url, to: destination, expectedDownloadSize: expectedDownloadSize)
    }
    
    /**
     Pauses the download to resume it later
     
     - Attention: Resume-data is only kept in memory.
     */
    public func pauseDownload(from url: URL) throws {
        try downloader.pauseDownload(from: url)
    }
    
    public func stopDownload(from url: URL) {
        downloader.stopDownload(from: url)
    }
    
    /**
     Resumes a download for a given URL
     
     If a download exists, but has no resume-data, the existing publisher of the download is returned. This should be a running download.
     */
    public func resumeDownload(from url: URL) -> AnyPublisher<Download, HTTPFileDownloader.Error> {
        return downloader.resumeDownload(from: url)
    }
    
    public enum Error: Swift.Error {
        case downloadDoesNotExist
        case movingDownloadToDestinationFailed(underlyingError: Swift.Error)
        case downloadFailed(underlyingError: Swift.Error)
    }
    
    
    
    
    
    // MARK: - Private
    
    let downloader: HTTPFileDownloaderInternal = .init()
    
}






























