import XCTest
import Vapor
@testable import OAuthBM

final class OAuthBMTests: XCTestCase {
    var app: Application!
    
    override func setUpWithError() throws {
        app = .init(.testing)
    }
    
    func testAuthorizationCodeFlowRoutes() {
        
//        let provider = testTwitchProvider
        
//        /// An endpoint that your users will open when they want to register.
//        app.get("oauth", "register") { req in
//            provider.requestAuthorization(req, state: .init(callbackUrl: .normal))
//        }
//
//        /// This must be the same endpoint as the one registered as
//        /// the `callbackUrl` in your provider's panel.
//        app.get("oauth", "callback") { req in
//            provider.authorizationCallback(req).map {
//                state, token -> String in
//                /// Returning a response to say the process has succeeded.
//                return "You have successfully registered. The `state` is \(state) and the `token` is \(token)."
//            }
//        }
        
    }
}
