import Foundation

extension String {
    
    func percentEscapeFormURLEncoded() -> String? {
        guard let escapedString = self.addingPercentEncoding(withAllowedCharacters: .formURLEncodedCharacters) else { return nil }
        
        return escapedString.replacingOccurrences(of: " ", with: "+")
    }
    
}

extension CharacterSet {
    
    /**
     All characters allowed in application/x-www-form-urlencoded and space
     */
    fileprivate static let formURLEncodedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890*-._ ")
    
}
