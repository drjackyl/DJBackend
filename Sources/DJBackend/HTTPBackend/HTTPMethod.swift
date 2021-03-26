/**
 - See also: [Wikipedia: HTTP Request Methods](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods)
 */
public enum HTTPMethod: String {
    
    /**
     "The GET method requests a representation of the specified resource. Requests using GET should only retrieve data and should have no other effect." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case GET = "GET"
    
    /**
     "The HEAD method asks for a response identical to that of a GET request, but without the response body. This is useful for retrieving meta-information written in response headers, without having to transport the entire content." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case HEAD = "HEAD"
    
    /**
     "The POST method requests that the server accept the entity enclosed in the request as a new subordinate of the web resource identified by the URI." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case POST = "POST"
    
    /**
     "The PUT method requests that the enclosed entity be stored under the supplied URI." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case PUT = "PUT"
    
    /**
     "The DELETE method deletes the specified resource." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case DELETE = "DELETE"
    
    /**
     "The TRACE method echoes the received request so that a client can see what (if any) changes or additions have been made by intermediate servers." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case TRACE = "TRACE"
    
    /**
     "The OPTIONS method returns the HTTP methods that the server supports for the specified URL." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case OPTIONS = "OPTIONS"
    
    /**
     "The CONNECT method converts the request connection to a transparent TCP/IP tunnel, usually to facilitate SSL-encrypted communication (HTTPS) through an unencrypted HTTP proxy." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case CONNECT = "CONNECT"
    
    /**
     "The PATCH method applies partial modifications to a resource." - [Wikipedia](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods), 2020-07-23
     */
    case PATCH = "PATCH"
}






























