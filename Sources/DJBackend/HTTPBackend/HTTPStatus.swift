public enum HTTPStatus {
    /// 200...299
    case success
    
    /// 400...499
    case clientError
    
    /// 400...400
    case badRequest
    
    /// 401...401
    case unauthorized
    
    /// 403...403
    case forbidden
    
    /// 404...404
    case notFound
    
    /// 500...599
    case serverError
    
    /// 500...500
    case internalServerError
    
    /// 501...501
    case notImplemented
    
    /// 502...502
    case badGateway
    
    /// 503...503
    case serviceUnavailable
    
    /// 504...504
    case gatewayTimeout
    
    case code(_ code: Int)
    
    case any
    
    public var statusCodeRange: ClosedRange<Int> {
        switch self {
        case .success: return 200...299
        case .clientError: return 400...499
        case .badRequest: return 400...400
        case .unauthorized: return 401...401
        case .forbidden: return 403...403
        case .notFound: return 404...404
        case .serverError: return 500...599
        case .internalServerError: return 500...500
        case .notImplemented: return 501...501
        case .badGateway: return 502...502
        case .serviceUnavailable: return 503...503
        case .gatewayTimeout: return 504...504
        case let .code(code): return code...code
        // Using Int.min...Int.max leads to ClosedRange<Int>.count not being representable, since its typed as Int.
        // Accessing it crashes with:
        //
        // Execution was interrupted, reason: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0).
        //
        // Since status-codes are limited to 3 digits anyways, 0...999 should still be more than sufficient, probably
        // even 100...599.
        case .any: return 0...999
        }
    }
}
