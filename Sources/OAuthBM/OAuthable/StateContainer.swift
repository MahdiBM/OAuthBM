
/// Length of the ``StateContainer/randomValue``
private let lengthOfRandomValue = 64

/// Container of State-related stuff.
public struct StateContainer<CallbackUrls>
where CallbackUrls: RawRepresentable, CallbackUrls.RawValue == String {
    
    /// Custom value entered by app.
    public let customValue: String
    /// CallbackUrl that should be called after the process by the provider.
    public let callbackUrl: CallbackUrls
    /// Random value to make this state unpredictable.
    /// Not cryptographically-random but should suffice and help not pulling a whole crypto dependancy.
    internal let randomValue: String
    
    /// The value to be used for HTTP requests.
    var value: [String] {
        [customValue, callbackUrl.rawValue, randomValue]
    }
    
    /// Initializes an instance using the provided values.
    /// - Parameters:
    ///   - customValue: The ``customValue``.
    ///   - callbackUrl: The ``callbackUrl``.
    ///   - randomValue: The ``randomValue``.
    internal init(
        customValue: String,
        callbackUrl: CallbackUrls,
        randomValue: String
    ) {
        self.customValue = customValue
        self.callbackUrl = callbackUrl
        self.randomValue = randomValue
    }
    
    /// Initializes an instance using the provided ``customValue`` and ``callbackUrl``.
    /// - Parameters:
    ///   - customValue: The ``customValue``.
    ///   - callbackUrl: The ``callbackUrl``.
    public init(
        customValue: String = "",
        callbackUrl: CallbackUrls
    ) {
        self.customValue = customValue
        self.callbackUrl = callbackUrl
        self.randomValue = .random(length: lengthOfRandomValue)
    }
    
    /// Injects the current values of this instance to the session.
    /// - Parameter session: The ``Session``.
    internal func injectTo(session: Session) {
        OAuthBMSessionData.init(
            customValue: customValue,
            callbackUrl: callbackUrl.rawValue,
            randomValue: randomValue
        ).set(on: session)
    }
    
    /// Extracts an instance of ``OAuthable/State`` out of the session.
    /// - Parameter session: The ``Session``.
    /// - Throws: ``OAuthableError``.
    /// - Returns: The extracted value.
    internal static func extract(
        from session: Session
    ) throws -> Self {
        let oauthbmData = session.data.oauthbm
        guard let customValue = oauthbmData.customValue,
              let callbackUrlStr = oauthbmData.callbackUrl,
              let callbackUrl = CallbackUrls.init(rawValue: callbackUrlStr),
              let randomValue = oauthbmData.randomValue,
              randomValue.count == lengthOfRandomValue
        else {
            throw OAuthableError.serverError(error: .invalidCookies)
        }
        return Self(
            customValue: customValue,
            callbackUrl: callbackUrl,
            randomValue: randomValue
        )
    }
    
    /// Decodes an instance of ``OAuthable/State`` from the container.
    /// - Parameter container: The `URLQueryContainer`.
    /// - Throws: ``OAuthableError``.
    internal init(
        decodeFrom container: URLQueryContainer
    ) throws {
        
        var error: OAuthableError {
            let stateDesc = container[String.self, at: "state"]?.debugDescription ?? "NIL"
            return .serverError(status: .badRequest, error: .stateDecode(state: stateDesc))
        }
        
        let values: [String]
        if let stateString = container[String.self, at: "state"] {
            let stateValues = stateString.components(separatedBy: ",")
            values = stateValues
        } else if let stateValues = container[[String].self, at: "state"] {
            values = stateValues
        } else {
            throw error
        }
        
        guard values.count == 3,
              let callbackUrl = CallbackUrls(rawValue: values[1])
        else {
            throw error
        }
        
        self.customValue = values[0]
        self.callbackUrl = callbackUrl
        self.randomValue = values[2]
    }
}

//MARK: - `Equatable` conformance
extension StateContainer: Equatable {
    public static func ==<A, B> (
        lhs: StateContainer<A>,
        rhs: StateContainer<B>
    ) -> Bool {
        lhs.customValue == rhs.customValue &&
        lhs.callbackUrl.rawValue == rhs.callbackUrl.rawValue &&
        lhs.randomValue == rhs.randomValue
    }
}
