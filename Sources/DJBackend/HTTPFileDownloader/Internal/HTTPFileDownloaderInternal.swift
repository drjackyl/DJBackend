import Foundation
import Combine





class HTTPFileDownloaderInternal: NSObject {
    
    // MARK: - Internal API
    
    func download(_ url: URL, to destination: URL, expectedDownloadSize: Int64? = nil) -> AnyPublisher<Download, HTTPFileDownloader.Error> {
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
    
    func pauseDownload(from url: URL) throws {
        guard let download = getDownload(url: url) else {
            throw HTTPFileDownloader.Error.downloadDoesNotExist
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
    
    func resumeDownload(from url: URL) -> AnyPublisher<Download, HTTPFileDownloader.Error> {
        guard let download = getDownload(url: url) else {
            let publisher = PassthroughSubject<Download, HTTPFileDownloader.Error>()
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
    
    private class DownloadState {
        init(url: URL, destination: URL, expectedDownloadSize: Int64? = nil) {
            self.url = url
            self.destination = destination
            self.expectedDownloadSize = expectedDownloadSize
            
            let download = Download(url: url, destination: destination, progress: 0)
            publisher = CurrentValueSubject<Download, HTTPFileDownloader.Error>(download)
        }
        
        let url: URL
        let destination: URL
        let expectedDownloadSize: Int64?
        let publisher: CurrentValueSubject<Download, HTTPFileDownloader.Error>
        
        var task: URLSessionDownloadTask?
        var resumeData: Data?
        var pausingRequested: Bool = false
    }
    
    private var downloads: [URL: DownloadState] = .init()
    private let fileIO: FileManager = .init()
    
    private func getOrCreateDownload(url: URL, destination: URL, expectedDownloadSize: Int64? = nil) -> DownloadState {
        if let existingDownload = downloads[url] {
            return existingDownload
        } else {
            let downloadState = DownloadState(url: url, destination: destination, expectedDownloadSize: expectedDownloadSize)
            downloads[url] = downloadState
            return downloadState
        }
    }
    
    private func getDownload(url: URL) -> DownloadState? {
        return downloads[url]
    }
    
    private func forgetDownload(_ downloadState: DownloadState) {
        _ = downloads.removeValue(forKey: downloadState.url)
    }
    
    private func publishProgressForDownload(_ downloadState: DownloadState, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress: Double
        if let expectedDownloadSize = downloadState.expectedDownloadSize, expectedDownloadSize > 0 {
            progress = Double(totalBytesWritten) / Double(expectedDownloadSize)
        } else if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            progress = 0
        }
        
        downloadState.publisher.value = Download(url: downloadState.url, destination: downloadState.destination, progress: progress)
    }
    
    private func finishDownload(_ downloadState: DownloadState, completion: Subscribers.Completion<HTTPFileDownloader.Error>) {
        downloadState.publisher.send(completion: completion)
        forgetDownload(downloadState)
    }
    
}










extension HTTPFileDownloaderInternal: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.currentRequest?.url,
            let download = getDownload(url: url) else {
                #if DEBUG
                assertionFailure("There is a callback for a download, which doesn't exist in self.downloads: This inconcistency should never happen")
                #endif
                return
        }
        
        publishProgressForDownload(download, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
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
                // Pausing is implemented by canceling a download with resume-data. Hence pausing a download leads
                // to this error being created. Hence if pausing was requested, when this error occurs, nothing should
                // be done. If pausing was not requested, though, the cancellation is a "stop" and the download should
                // be forgotten.
                if !download.pausingRequested {
                    finishDownload(download, completion: .finished)
                }
                return
            } else {
                finishDownload(download, completion: .failure(HTTPFileDownloader.Error.downloadFailed(underlyingError: error)))
            }
        } else {
            finishDownload(download, completion: .finished)
        }
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
            try fileIO.moveItem(at: location, to: download.destination)
        } catch let error {
            finishDownload(download, completion: .failure(.movingDownloadToDestinationFailed(underlyingError: error)))
        }
    }
    
}






























