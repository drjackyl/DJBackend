import XCTest
@testable import DJBackend

class StringEscapingTests: XCTestCase {
    
    /**
     - See Also:
       - [application/x-www-form-urlencoded percent-encode set](https://url.spec.whatwg.org/#application-x-www-form-urlencoded-percent-encode-set)
       - via [5.2. application/x-www-form-urlencoded serializing](https://url.spec.whatwg.org/#urlencoded-serializing)
     */
    private let allowedCharactersString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890*-._"
    private lazy var allowedCharactersForFormURLEncoding = { CharacterSet(charactersIn: allowedCharactersString) }()
    private lazy var notAllowedCharactersForFormURLEncoding = { allowedCharactersForFormURLEncoding.inverted }()
    
    func test_StringEscaping_AllowedCharacters() {
        let encodedString = allowedCharactersString.percentEscapeFormURLEncoded()
        
        XCTAssertEqual(encodedString, allowedCharactersString)
    }
    
    func test_StringEscaping_NotAllowedCharacters() {
        let low: UInt16 = 0x0000
        let high: UInt16 = 0xFFFF
        let scalarValues = (low...high).compactMap { (value) -> Unicode.Scalar? in
            guard let scalar = Unicode.Scalar(value),
                  notAllowedCharactersForFormURLEncoding.contains(scalar)
            else { return nil }
            return scalar
        }
        
        var randomStringWithNotAllowedCharacter: String
        repeat {
            randomStringWithNotAllowedCharacter = String(scalarValues.randomElement()!)
        } while (randomStringWithNotAllowedCharacter.contains("%"))
        
        let encodedString = randomStringWithNotAllowedCharacter.percentEscapeFormURLEncoded()
        
        XCTAssertTrue(encodedString?.contains("%") ?? false)
    }
    
    func test_StringEscaping_SpaceEncodedAsPlus() {
        let space = " "
        
        let encodedString = space.percentEscapeFormURLEncoded()
        
        XCTAssertEqual(encodedString, "+")
    }
    
}
