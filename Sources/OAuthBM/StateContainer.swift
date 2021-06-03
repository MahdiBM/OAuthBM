
public struct StateContainer<CallbackUrls>
where CallbackUrls: RawRepresentable, CallbackUrls.RawValue == String {
    
    public let customValue: String
    public let callbackUrl: CallbackUrls
    internal let randomValue: String
    
    var description: String {
        customValue + "@#$%" + callbackUrl.rawValue + "@#$%" + randomValue
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
