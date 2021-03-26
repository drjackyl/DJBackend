import Foundation

public protocol HTTPBackendResponse {
    static var responseDescriptors: [ResponseDescriptor] { get }
    
    init(response: HTTPURLResponse, responseDescriptor: ResponseDescriptor, body: Any?)
}

public struct ResponseDescriptor {
    public let statusCode: HTTPStatus
    public let bodyType: BodyType
    
    /// 200...299
    public static func success(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .success, bodyType: type)
    }
    
    /// 400...499
    public static func clientError(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .clientError, bodyType: type)
    }
    
    /// 400...400
    public static func badRequest(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .badRequest, bodyType: type)
    }
    
    /// 401...401
    public static func unauthorized(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .unauthorized, bodyType: type)
    }
    
    /// 403...403
    public static func forbidden(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .forbidden, bodyType: type)
    }
    
    /// 404...404
    public static func notFound(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .notFound, bodyType: type)
    }
    
    /// 500...599
    public static func serverError(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .serverError, bodyType: type)
    }
    
    /// 500...500
    public static func internalServerError(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .internalServerError, bodyType: type)
    }
    
    /// 501...501
    public static func notImplemented(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .notImplemented, bodyType: type)
    }
    
    /// 502...502
    public static func badGateway(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .badGateway, bodyType: type)
    }
    
    /// 503...503
    public static func serviceUnavailable(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .serviceUnavailable, bodyType: type)
    }
    
    /// 504...504
    public static func gatewayTimeout(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .gatewayTimeout, bodyType: type)
    }
    
    public static func statusCode(_ code: Int, type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .code(code), bodyType: type)
    }
    
    public static func any(type: BodyType) -> ResponseDescriptor {
        ResponseDescriptor(statusCode: .any, bodyType: type)
    }
    
    public enum BodyType {
        case none
        case data
        case text(encoding: String.Encoding)
        case json(decode: (Data, JSONDecoder) throws -> Any?)
        case custom(decode: (Data) throws -> Any?)
    }
    
}






























