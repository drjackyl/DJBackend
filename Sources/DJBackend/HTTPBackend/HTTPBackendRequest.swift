import Foundation

public struct HTTPBackendRequest {
    public init(method: HTTPMethod, path: String, parameters: [Parameter] = [], headers: [Header] = [], body: Body? = nil) {
        self.method = method
        self.path = path
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }
    
    public let method: HTTPMethod
    public let path: String
    public let parameters: [Parameter]
    public let headers: [Header]
    public let body: Body?
    
    public struct Parameter: NameValuePair {
        public let name: String
        public let value: String
        
        public static func parameter(name: String, value: String) -> HTTPBackendRequest.Parameter {
            Parameter(name: name, value: value)
        }
    }
    
    public struct Header: NameValuePair {
        public let name: String
        public let value: String
        
        public static func header(name: String, value: String) -> HTTPBackendRequest.Header {
            Header(name: name, value: value)
        }
    }
    
    public enum Body {
        case octetStream(data: Data)
        case formURLEncoded(_ fields: [FormURLEncodedField], encoding: String.Encoding)
        case jsonBody(_ encoder: (JSONEncoder) throws -> Data)
        case customBody(contentType: String, content: Any, encoder: (Any) throws -> Data)
        
        public struct FormURLEncodedField: NameValuePair {
            public let name: String
            public let value: String
            
            public static func field(name: String, value: String) -> HTTPBackendRequest.Body.FormURLEncodedField {
                FormURLEncodedField(name: name, value: value)
            }
        }
    }
}

public protocol NameValuePair {
    var name: String { get }
    var value: String { get }
}

public protocol RequestBuilder {
    func buildRequest() -> HTTPBackendRequest
}
