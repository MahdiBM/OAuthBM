
//MARK: - ``SessionData`` extension.

public extension SessionData {
    var oauthbm: OAuthBMSessionData {
        .init(session: self)
    }
}

//MARK: - ``OAuthBMSessionData`` declaration.

/// Session values related to OAuthBM.
public struct OAuthBMSessionData {
    
    /// Custom value entered by app.
    public let customValue: String?
    /// CallbackUrl that should be called after the process by the provider.
    public let callbackUrl: String?
    /// Random value to make this state unpredictable.
    internal let randomValue: String?
    
    /// Initializes an instance from the provided session.
    /// - Parameter session: The session to extract session-data from.
    fileprivate init(session: SessionData) {
        self.customValue = session[Keys.customValue.rawValue]
        self.callbackUrl = session[Keys.callbackUrl.rawValue]
        self.randomValue = session[Keys.randomValue.rawValue]
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
        session.data[Keys.customValue.rawValue] = customValue
        session.data[Keys.callbackUrl.rawValue] = callbackUrl
        session.data[Keys.randomValue.rawValue] = randomValue
    }
    
    /// The session-keys of the values of ``OAuthBMSessionData``.
    private enum Keys: String {
        case customValue = "_OAuthBM_customValue"
        case callbackUrl = "_OAuthBM_callbackUrl"
        case randomValue = "_OAuthBM_randomValue"
    }
}
