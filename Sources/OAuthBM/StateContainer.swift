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
    
    /// The value to be used for HTTP requests.
    var value: [String] {
        [customValue, callbackUrl.rawValue, randomValue]
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
    
    internal init(decodeFrom value: [String]) throws {
        let count = value.count
        var error: OAuthableError {
            let stateDesc = value.joined(separator: ", ").debugDescription
            return .serverError(status: .badRequest, error: .stateDecode(state: stateDesc))
        }
        if count == 3 {
            guard let callbackUrl = CallbackUrls(rawValue: value[1]) else {
                throw error
            }
            self.customValue = value[0]
            self.callbackUrl = callbackUrl
            self.randomValue = value[2]
        } else if count == 2 {
            guard let callbackUrl = CallbackUrls(rawValue: value[0]) else {
                throw error
            }
            self.customValue = ""
            self.callbackUrl = callbackUrl
            self.randomValue = value[1]
        } else {
            throw error
        }
    }
}

//MARK: - Equatable conformance
extension StateContainer: Equatable {
    public static func ==<A, B> (lhs: StateContainer<A>, rhs: StateContainer<B>) -> Bool {
        lhs.randomValue == rhs.randomValue &&
        lhs.callbackUrl.rawValue == rhs.callbackUrl.rawValue &&
        lhs.customValue == rhs.customValue
    }
}
