import Foundation

class HTTPBackendRequestFactory {
    
    // MARK: - Internal
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func createURLRequest(requestBuilder: RequestBuilder) throws -> URLRequest {
        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw Error.baseURLDecompositionFailed
        }
        let backendRequest = requestBuilder.buildRequest()
        urlComponents.path += backendRequest.path
        urlComponents.queryItems = createQueryItemsForRequest(backendRequest)
        
        guard let url = urlComponents.url else {
            throw Error.urlCompositionFailed
        }
        var request = URLRequest(url: url)
        
        request.httpMethod = backendRequest.method.rawValue
        
        backendRequest.headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.name)
        }
        
        if let body = backendRequest.body {
            request.httpBody = try createDataForHTTPBody(body: body)
            let contentType = getContentTypeForBody(body)
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    public enum Error: Swift.Error {
        case baseURLDecompositionFailed
        case urlCompositionFailed
        case encodingBodyFailed(underlyingError: Swift.Error)
        case percentEscapingFormURLEncodedBodyFailed
        case convertingStringToBytesFailed(encoding: String.Encoding)
    }
    
    
    
    
    
    // MARK: - Private
    
    private let baseURL: URL
    private let jsonEncoder: JSONEncoder = .init()
    
    private func createQueryItemsForRequest(_ backendRequest: HTTPBackendRequest) -> [URLQueryItem]? {
        let queryItems = backendRequest.parameters.toURLQueryItems()
        if queryItems.count == 0 {
            // If there are no query-items, the property should be set to nil, since the composed URL would contain a
            // "?" at the end, if an empty array was set.
            return nil
        }
        return queryItems
    }
    
    private func createDataForHTTPBody(body: HTTPBackendRequest.Body) throws -> Data {
        switch body {
        case let .jsonBody(encoder):
            return try createDataForHTTPBody(jsonEncode: encoder)
        case let .formURLEncoded(fields, encoding):
            return try createDataForHTTPBody(formURLEncodedFields: fields, encoding: encoding)
        case let .octetStream(data):
            return data
        case let .customBody(_, content, encoder):
            return try createDataForHTTPBody(object: content, encode: encoder)
        }
    }
    
    private func createDataForHTTPBody(jsonEncode: (JSONEncoder) throws -> Data) throws -> Data {
        do {
            return try jsonEncode(jsonEncoder)
        } catch let error {
            throw Error.encodingBodyFailed(underlyingError: error)
        }
    }
    
    private func createDataForHTTPBody(formURLEncodedFields: [HTTPBackendRequest.Body.FormURLEncodedField], encoding: String.Encoding) throws -> Data {
        let bodyData = try formURLEncodedFields
            .map {
                guard let percentEncodedValue = $0.value.percentEscapeFormURLEncoded() else {
                    throw Error.encodingBodyFailed(underlyingError: Error.percentEscapingFormURLEncodedBodyFailed)
                }
                return "\($0.name)=\(percentEncodedValue)"
            }
            .joined(separator: "&")
            .data(using: encoding)
        
        guard let data = bodyData else {
            throw Error.encodingBodyFailed(underlyingError: Error.convertingStringToBytesFailed(encoding: .utf8))
        }
        
        return data
    }
    
    private func createDataForHTTPBody(object: Any, encode: (Any) throws -> Data) rethrows -> Data {
        do {
            return try encode(object)
        } catch let error {
            throw Error.encodingBodyFailed(underlyingError: error)
        }
    }
    
    private func getContentTypeForBody(_ body: HTTPBackendRequest.Body) -> String {
        switch body {
        case .octetStream: return Mimetype.applicationOctetStream.rawValue
        case .formURLEncoded: return Mimetype.applicationFormURLEncoded.rawValue
        case .jsonBody: return Mimetype.applicationJson.rawValue
        case let .customBody(contentType, _, _): return contentType
        }
    }
    
}

private extension NameValuePair {
    func toURLQueryItem() -> URLQueryItem {
        URLQueryItem(name: name, value: value)
    }
}

private extension Array where Element == HTTPBackendRequest.Parameter {
    func toURLQueryItems() -> [URLQueryItem] {
        map { $0.toURLQueryItem() }
    }
}






























