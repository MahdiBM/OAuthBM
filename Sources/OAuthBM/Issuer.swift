import Vapor

/// The issuer of an oauth token.
///
/// You should extend `Issuer` and add a static member for your issuer, example:
/// ```swift
/// extension Issuer {
///     static let twitch = Issuer(rawValue: "twitch")
/// }
/// ```
public struct Issuer: RawRepresentable {
    private(set) public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Codable conformance.
extension Issuer: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

/// StringConvertible conformance.
extension Issuer: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { rawValue }
    public var debugDescription: String { .init(reflecting: rawValue) }
}

/// Equatable conformance.
extension Issuer: Equatable { }
