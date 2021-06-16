import Vapor

/// Container of State-related stuff.
public struct StateContainer<CallbackUrls>
where CallbackUrls: RawRepresentable, CallbackUrls.RawValue == String {
    
    /// Custom value entered by app.
    public let customValue: String
    /// CallbackUrl that should be called after the process by the provider.
    public let callbackUrl: CallbackUrls
    /// Random value to make this state unpredictable.
    internal let randomValue: String
    
    /// Separator between values in `description`.
    internal let separator = ",,,"
    
    /// String representation of the container.
    var description: String {
        [customValue, callbackUrl.rawValue, randomValue].joined(separator: separator)
    }
    
    internal init(customValue: String, callbackUrl: CallbackUrls, randomValue: String) {
        self.customValue = customValue
        self.callbackUrl = callbackUrl
        self.randomValue = randomValue
    }
    
    public init(customValue: String = "", callbackUrl: CallbackUrls) {
        self.customValue = customValue
        self.callbackUrl = callbackUrl
        self.randomValue = .random(length: 64)
    }
    
    internal func injectTo(session: Session) {
        session.data["_OAuthBM_customValue"] = customValue
        session.data["_OAuthBM_callbackUrl"] = callbackUrl.rawValue
        session.data["_OAuthBM_randomValue"] = randomValue
    }
    
    internal static func extractFrom(session: Session) throws -> Self {
        guard let customValue = session.data["_OAuthBM_customValue"],
              let callbackUrlStr = session.data["_OAuthBM_callbackUrl"],
              let callbackUrl = CallbackUrls.init(rawValue: callbackUrlStr),
              let randomValue = session.data["_OAuthBM_randomValue"]
        else {
            throw OAuthableError.serverError(error: .invalidCookie)
        }
        return Self(
            customValue: customValue,
            callbackUrl: callbackUrl,
            randomValue: randomValue
        )
    }
    
    internal init(decodeFrom description: String) throws {
        let comps = description.components(separatedBy: ",,,")
        guard comps.count == 3, let callbackUrl = CallbackUrls(rawValue: comps[1]) else {
            throw OAuthableError.serverError(
                status: .badRequest, error: .stateDecode(state: description))
        }
        self.customValue = comps[0]
        self.callbackUrl = callbackUrl
        self.randomValue = comps[2]
    }
}

/// MARK: - Equatable conformance
extension StateContainer: Equatable {
    public static func ==<A, B> (lhs: StateContainer<A>, rhs: StateContainer<B>) -> Bool {
        lhs.randomValue == rhs.randomValue &&
        lhs.callbackUrl.rawValue == rhs.callbackUrl.rawValue &&
        lhs.customValue == rhs.customValue
    }
}
