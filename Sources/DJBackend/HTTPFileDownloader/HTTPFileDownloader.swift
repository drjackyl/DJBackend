import Foundation
import Combine





class HTTPFileDownloader: NSObject {
    
    // MARK: - Internal API
    
    override init() {
        self.downloads = [:]
        self.fileIO = FileManager()
        
        super.init()
    }
    
    /**
     Starts a download of the given URL and moves the downloaded data to the destination URL on completion
     
     - Parameter url: URL to download from
     - Parameter destination: File-URL to move the downloaded data to on completion.
     - Parameter expectedDownloadSize: Used for progress-calculation, if provided.
     */
    func download(_ url: URL, to destination: URL, expectedDownloadSize: Int64? = nil) -> AnyPublisher<Download, Backend.Error> {
        let download = getOrCreateDownload(url: url, destination: destination, expectedDownloadSize: expectedDownloadSize)
        download.pausingRequested = false
        if download.task != nil {
            return download.publisher.eraseToAnyPublisher()
        }
        
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        download.task = session.downloadTask(with: download.url)
        download.task?.resume()
        return download.publisher.eraseToAnyPublisher()
    }
    
    /**
     Pauses the download to resume it later
     
     - Attention: Resume-data is only kept in memory.
     */
    func pauseDownload(from url: URL) throws {
        guard let download = getDownload(url: url) else {
            throw Backend.Error.downloadDoesNotExist
        }
        
        download.pausingRequested = true
        download.task?.cancel(byProducingResumeData: { resumeData in
            download.resumeData = resumeData
        })
        download.task = nil
    }
    
    func stopDownload(from url: URL) {
        if let download = getDownload(url: url) {
            download.task?.cancel()
        }
    }
    
    /**
     Resumes a download for a given URL
     
     If a download exists, but has no resume-data, the existing publisher of the download is returned. This should be a running download.
     */
    func resumeDownload(from url: URL) -> AnyPublisher<Download, Backend.Error> {
        guard let download = getDownload(url: url) else {
            let publisher = PassthroughSubject<Download, Backend.Error>()
            publisher.send(completion: .failure(.downloadDoesNotExist))
            return publisher.eraseToAnyPublisher()
        }
        
        guard let resumeData = download.resumeData else {
            forgetDownload(download)
            return self.download(download.url, to: download.destination, expectedDownloadSize: download.expectedDownloadSize)
        }
        
        download.pausingRequested = false
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        download.task = session.downloadTask(withResumeData: resumeData)
        download.task?.resume()
        return download.publisher.eraseToAnyPublisher()
    }
    
    
    
    
    
    // MARK: - Private
    
    private class DownloadInfo {
        init(url: URL, destination: URL, expectedDownloadSize: Int64? = nil) {
            self.url = url
            self.destination = destination
            self.expectedDownloadSize = expectedDownloadSize
            
            let download = Download(url: url, destination: destination, progress: 0)
            self.publisher = CurrentValueSubject<Download, Backend.Error>(download)
        }
        
        let url: URL
        let destination: URL
        let expectedDownloadSize: Int64?
        let publisher: CurrentValueSubject<Download, Backend.Error>
        
        var task: URLSessionDownloadTask?
        var resumeData: Data?
        var pausingRequested: Bool = false
    }
    
    private var downloads: [URL: DownloadInfo]
    private let fileIO: FileManager
    
    private func getOrCreateDownload(url: URL, destination: URL, expectedDownloadSize: Int64? = nil) -> DownloadInfo {
        if let existingDownload = self.downloads[url] {
            return existingDownload
        } else {
            let downloadInfo = DownloadInfo(url: url, destination: destination, expectedDownloadSize: expectedDownloadSize)
            self.downloads[url] = downloadInfo
            return downloadInfo
        }
    }
    
    private func getDownload(url: URL) -> DownloadInfo? {
        return self.downloads[url]
    }
    
    private func forgetDownload(_ downloadInfo: DownloadInfo) {
        _ = self.downloads.removeValue(forKey: downloadInfo.url)
    }
    
    private func publishProgressForDownload(_ downloadInfo: DownloadInfo, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress: Double
        if let expectedDownloadSize = downloadInfo.expectedDownloadSize, expectedDownloadSize > 0 {
            progress = Double(totalBytesWritten) / Double(expectedDownloadSize)
        } else if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            progress = 0
        }
        
        downloadInfo.publisher.value = Download(url: downloadInfo.url, destination: downloadInfo.destination, progress: progress)
    }
}










extension HTTPFileDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.currentRequest?.url,
            let download = getDownload(url: url) else {
                #if DEBUG
                assertionFailure("There is a callback for a download, which doesn't exist in self.downloads: This inconcistency should never happen")
                #endif
                return
        }
        
        self.publishProgressForDownload(download, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // The func-name "didCompleteWithError" is misleading in comparison to "didFinishDownloadingTo".
        // The latter is only the callback for moving the downloaded file to the desired destination, while the
        // first one indicates the completion of the whole process.
        // If an error occurred, it is not nil. This is rather old-school Objective-C-style.
        guard let url = task.currentRequest?.url,
            let download = getDownload(url: url) else {
                #if DEBUG
                assertionFailure("There is a callback for a download, which doesn't exist in self.downloads: This inconcistency should never happen")
                #endif
                return
        }
        
        if let error = error as NSError? {
            if error.code == NSURLErrorCancelled {
                if !download.pausingRequested {
                    self.forgetDownload(download)
                }
                return
            }
        }
        
        download.publisher.send(completion: .finished)
        
        self.forgetDownload(download)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.currentRequest?.url,
            let download = getDownload(url: url) else {
                #if DEBUG
                assertionFailure("There is a callback for a download, which doesn't exist in self.downloads: This inconcistency should never happen")
                #endif
                return
        }
        
        do {
            try self.fileIO.moveItem(at: location, to: download.destination)
        } catch let error {
            download.publisher.send(completion: .failure(.downloadCouldNotBeMovedToDestination(underlyingError: error)))
        }
    }
}






























