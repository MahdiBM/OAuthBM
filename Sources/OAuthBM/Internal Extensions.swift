import Vapor

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
    static func random(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".map({ $0 })
        let indices = 0..<letters.count
        let randomInts = (0..<length).map { _ in
            Int.random(in: indices)
        }
        let randomStrings = randomInts.map({ String(letters[$0]) })
        return randomStrings.joined()
    }
}

extension EventLoopFuture {
    /// A version of `.flatMap` which can throw as well.
    func tryFlatMap<NewValue>(
        file: StaticString = #file,
        line: UInt = #line,
        _ callback: @escaping (Value) throws -> EventLoopFuture<NewValue>
    ) -> EventLoopFuture<NewValue> {
        flatMap(file: file, line: line) { result in
            do {
                return try callback(result)
            } catch {
                return self.eventLoop.makeFailedFuture(error, file: file, line: line)
            }
        }
    }
}
