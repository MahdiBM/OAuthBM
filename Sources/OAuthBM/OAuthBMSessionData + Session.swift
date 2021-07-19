
//MARK: - ``SessionData`` extension.

public extension SessionData {
    var oauthbm: OAuthBMSessionData {
        .init(session: self)
    }
}

//MARK: - ``OAuthBMSessionData`` declaration.

/// Session values related to OAuthBM.
public struct OAuthBMSessionData {
    
    /// Optional custom value that is entered by you.
    public let customValue: String?
    /// The CallbackUrl that is called by the provider, after the user-authorization process.
    public let callbackUrl: String?
    /// Random value to make this state unpredictable.
    internal let randomValue: String?
    
    /// Initializes an instance from the provided session.
    /// - Parameter session: The session to extract session-data from.
    fileprivate init(session: SessionData) {
        self.customValue = session[Keys.customValue]
        self.callbackUrl = session[Keys.callbackUrl]
        self.randomValue = session[Keys.randomValue]
    }
    
    /// Sets the ``OAuthBMSessionData`` related parameters to the entered values.
    /// - Parameters:
    ///   - session: The session to set values to.
    ///   - customValue: The ``customValue``.
    ///   - callbackUrl: The ``callbackUrl``.
    ///   - randomValue: The ``randomValue``.
    internal static func set(
        session: Session,
        customValue: String?,
        callbackUrl: String?,
        randomValue: String?
    ) {
        session.data[Keys.customValue] = customValue
        session.data[Keys.callbackUrl] = callbackUrl
        session.data[Keys.randomValue] = randomValue
    }
    
    /// The session-keys of the values of ``OAuthBMSessionData``.
    private enum Keys {
        static let customValue = "_OAuthBM_customValue"
        static let callbackUrl = "_OAuthBM_callbackUrl"
        static let randomValue = "_OAuthBM_randomValue"
    }
}
