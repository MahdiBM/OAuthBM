
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
    let separator = "@#$%"
    
    /// String representation of the container.
    var description: String {
        [customValue, callbackUrl.rawValue, randomValue].joined(separator: separator)
    }
    
    init(customValue: String = "", callbackUrl: CallbackUrls) {
        self.customValue = customValue
        self.callbackUrl = callbackUrl
        self.randomValue = .random(length: 64)
    }
    
    internal init? (decodeFrom description: String)  {
        let comps = description.components(separatedBy: "@#$%")
        guard comps.count == 3, let callbackUrl = CallbackUrls(rawValue: comps[1])
        else { return nil }
        self.customValue = comps[0]
        self.callbackUrl = callbackUrl
        self.randomValue = comps[2]
    }
}
