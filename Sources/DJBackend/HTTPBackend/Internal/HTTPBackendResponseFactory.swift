import Foundation

class HTTPBackendResponseFactory {
    
    // MARK: - Internal
    
    func createBackendResponse<TResponse: HTTPBackendResponse>(data: Data, response: URLResponse) throws -> TResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.responseIsNoHTTPResponse(hint: "\(type(of: response))")
        }
        
        let bodyDescriptor = try getBodyDescriptorForResponse(bodyDescriptors: TResponse.responseDescriptors, response: httpResponse)
        
        switch bodyDescriptor.bodyType {
        case .none:
            return TResponse(response: httpResponse, responseDescriptor: bodyDescriptor, body: nil)
        case .data:
            return TResponse(response: httpResponse, responseDescriptor: bodyDescriptor, body: data)
        case let .text(encoding):
            let text = try decodeContent(data, encoding: encoding)
            return TResponse(response: httpResponse, responseDescriptor: bodyDescriptor, body: text)
        case let .json(decoder):
            let json = try decodeContent(data, decode: decoder)
            return TResponse(response: httpResponse, responseDescriptor: bodyDescriptor, body: json)
        case let .custom(decoder):
            let object = try decodeContent(data, decode: decoder)
            return TResponse(response: httpResponse, responseDescriptor: bodyDescriptor, body: object)
        }
    }
    
    enum Error: Swift.Error {
        case responseIsNoHTTPResponse(hint: String)
        case responseProvidesNoBodyDescriptorForHTTPStatusCode(_ code: Int)
        case decodingBodyAsTextFailed(encoding: String.Encoding)
        case decodingBodyAsJSONFailed(underlyingError: Swift.Error)
        case decodingBodyFailed(underlyingError: Swift.Error)
    }
    
    
    
    
    
    // MARK: - Private
    
    private let jsonDecoder: JSONDecoder = .init()
    
    private func getBodyDescriptorForResponse(bodyDescriptors: [ResponseDescriptor], response: HTTPURLResponse) throws -> ResponseDescriptor {
        let relevantDescriptor = bodyDescriptors
            .filter { $0.statusCode.statusCodeRange.contains(response.statusCode) }
            .sorted { $0.statusCode.statusCodeRange.count < $1.statusCode.statusCodeRange.count }
            .first
        
        guard let descriptor = relevantDescriptor else {
            throw Error.responseProvidesNoBodyDescriptorForHTTPStatusCode(response.statusCode)
        }
        
        return descriptor
    }
    
    private func decodeContent(_ content: Data, encoding: String.Encoding) throws -> String {
        guard let text = String(data: content, encoding: encoding) else {
            throw Error.decodingBodyAsTextFailed(encoding: encoding)
        }
        return text
    }
    
    private func decodeContent(_ content: Data, decode: (Data, JSONDecoder) throws -> Any) throws -> Any {
        do {
            return try decode(content, jsonDecoder)
        } catch let error {
            throw Error.decodingBodyAsJSONFailed(underlyingError: error)
        }
    }
    
    private func decodeContent(_ content: Data, decode: (Data) throws -> Any) throws -> Any {
        do {
            return try decode(content)
        } catch let error {
            throw Error.decodingBodyFailed(underlyingError: error)
        }
    }
    
}
