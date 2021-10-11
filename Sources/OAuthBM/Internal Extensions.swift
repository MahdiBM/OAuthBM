
extension ByteBuffer {
    
    /// Content string of a ByteBuffer.
    var contentString: String {
        .init(decoding: self.readableBytesView, as: UTF8.self)
    }
}

extension String {
    
    /// Creates a random string.
    /// - Parameters:
    ///   - length: length of the string.
    /// - Returns: a random string.
    static func random(
        length: Int
    ) -> String {
        let letters: [Character] = .init(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        )
        let indices = 0..<letters.count
        let randomInts = (0..<length).map { _ in
            Int.random(in: indices)
        }
        let randomStrings = randomInts.map({ String(letters[$0]) })
        return randomStrings.joined()
    }
}
