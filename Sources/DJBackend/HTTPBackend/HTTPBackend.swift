import Foundation
import Combine

public class HTTPBackend {
    
    // MARK: - Public
    
    public init(baseURL: URL, urlSession: URLSession? = nil) {
        requestFactory = HTTPBackendRequestFactory(baseURL: baseURL)
        self.urlSession = urlSession
    }
    
    public func sendRequest<TResponse: HTTPBackendResponse>(_ requestBuilder: RequestBuilder) -> AnyPublisher<TResponse, HTTPBackend.Error> {
        let request: URLRequest
        do {
            request = try requestFactory.createURLRequest(requestBuilder: requestBuilder)
        } catch let error {
            return Fail(error: Error.creatingRequestFailed(underlyingError: error))
                .eraseToAnyPublisher()
        }
        
        let session = getURLSessionForRequest()
        
        return session.dataTaskPublisher(for: request)
            .tryCompactMap { [weak self] (data, response) -> TResponse? in
                try self?.responseFactory.createBackendResponse(data: data, response: response)
            }
            .mapError {
                if $0 is HTTPBackendResponseFactory.Error {
                    return HTTPBackend.Error.creatingResponseFailed(underlyingError: $0)
                } else {
                    return HTTPBackend.Error.requestFailed(underlyingError: $0)
                }
            }
            .eraseToAnyPublisher()
    }
    
    public enum Error: Swift.Error {
        case creatingRequestFailed(underlyingError: Swift.Error)
        case requestFailed(underlyingError: Swift.Error)
        case creatingResponseFailed(underlyingError: Swift.Error)
    }
    
    
    
    
    
    // MARK: - Private
    
    private let requestFactory: HTTPBackendRequestFactory
    private let urlSession: URLSession?
    private let responseFactory: HTTPBackendResponseFactory = .init()
    
    private func getURLSessionForRequest() -> URLSession {
        return self.urlSession ?? URLSession(configuration: .ephemeral)
    }
    
}
