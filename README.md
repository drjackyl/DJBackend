# DJBackend

A minimal, URLSession-based wrapper for talking to an HTTP-backend and for downloading files. It uses Combine, hence requires macOS 10.15, iOS 13, tvOS 13 or watchOS 6.

_(Made in a bit of a hurry. Needs some love over time.)_

## Examples

### LoginExample

```swift
class LoginExample {
    init() {
        backend = HTTPBackend(baseURL: URL(string: "https://www.example.com")!)
    }
    
    func login(username: String, password: String) -> AnyPublisher<LoginResponse.User, Swift.Error> {
        let request = LoginRequest(username: username, password: password)
        return backend.sendRequest(request)
            .tryMap { (response: LoginResponse) in
                guard let user = response.user else {
                    throw Error.loginFailed(reason: response.failureReason)
                }
                return user
            }
            .eraseToAnyPublisher()
    }
    
    enum Error: Swift.Error {
        case loginFailed(reason: String?)
    }
    
    private let backend: HTTPBackend
}

struct LoginRequest: RequestBuilder {
    let username: String
    let password: String
    
    func buildRequest() -> HTTPBackendRequest {
        HTTPBackendRequest(
            method: .POST,
            path: "/Login",
            body: .formURLEncoded([
                .field(name: "username", value: username),
                .field(name: "password", value: password)
            ], encoding: .utf8)
        )
    }
}

struct LoginResponse: HTTPBackendResponse {
    static var responseDescriptors: [ResponseDescriptor] = [
        .success(type: .json(decode: { data, decoder in
            try decoder.decode(User.self, from: data)
        })),
        .unauthorized(type: .text(encoding: .utf8)),
        .any(type: .none)
    ]
    
    init(response: HTTPURLResponse, responseDescriptor: ResponseDescriptor, body: Any?) {
        user = body as? User
        
        if case .unauthorized = responseDescriptor.statusCode {
            failureReason = body as? String
        }
        
        statusCode = responseDescriptor.statusCode
    }
    
    var user: User?
    var failureReason: String?
    var statusCode: HTTPStatus
    
    struct User: Decodable {
        let name: String
    }
}
```

### ModelExample

```swift
class ModelExample {
    init() {
        backend = HTTPBackend(baseURL: URL(string: "https://www.example.com")!)
    }
    
    func getData(a: String, b: String) -> AnyPublisher<ModelResponse.Model, Swift.Error> {
        let request = ModelRequest(someParameter: a, notherParamter: b)
        return backend.sendRequest(request)
            .tryMap { (response: ModelResponse) in
                guard let model = response.model else {
                    throw Error.failedToRetrieveModel
                }
                return model
            }
            .eraseToAnyPublisher()
    }
    
    enum Error: Swift.Error {
        case failedToRetrieveModel
    }
    
    private let backend: HTTPBackend
}

struct ModelRequest: RequestBuilder {
    let someParameter: String
    let notherParamter: String
    
    func buildRequest() -> HTTPBackendRequest {
        HTTPBackendRequest(
            method: .GET,
            path: "/GetDataModel",
            parameters: [
                .parameter(name: "some", value: someParameter),
                .parameter(name: "nother", value: notherParamter)
            ]
        )
    }
}

struct ModelResponse: HTTPBackendResponse {
    static var responseDescriptors: [ResponseDescriptor] = [
        .success(type: .json(decode: { (data, jsonDecoder) -> Any? in
            try jsonDecoder.decode(Model.self, from: data)
        })),
        .any(type: .none)
    ]
    
    init(response: HTTPURLResponse, responseDescriptor: ResponseDescriptor, body: Any?) {
        model = body as? Model
    }
    
    var model: Model?
    
    struct Model: Decodable {
        let leModel: String
    }
}
```
