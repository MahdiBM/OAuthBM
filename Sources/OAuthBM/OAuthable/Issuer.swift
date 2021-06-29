
/// The issuer of an oauth token.
///
/// This is used to identify the provider which has issued an OAuth token.
///
/// You should extend `Issuer` and add a static member for your issuer, example:
/// ```swift
/// extension Issuer {
///     static let github = Issuer(rawValue: "github")
/// }
/// ```
public struct Issuer: RawRepresentable {
    private(set) public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

//MARK: - `Content` conformance.
extension Issuer: Content {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

//MARK: - `StringConvertible` conformances.
extension Issuer: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String { rawValue }
    
    public var debugDescription: String { .init(reflecting: rawValue) }
}

//MARK: - `Equatable` conformance.
extension Issuer: Equatable { }
