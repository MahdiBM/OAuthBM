import Vapor
import Fluent
import FluentPostgresDriver

func configure(app: Application) {
    // Migrations
    app.migrations.add(OAuthTokens.Create())
    
    // Databases
    let db = DatabaseConfigurationFactory.postgres(
        hostname: "localhost",
        port: 5050,
        username: "oauthBM_test",
        password: "oauthBMPass_test",
        database: "oauthBMDB_test"
    )
    
    app.databases.use(db, as: .psql)
    
    // Sessions
    app.sessions.use(.memory) /// using `.memory` only in tests.
    app.migrations.add(SessionRecord.migration)
    app.sessions.configuration.cookieName = "oauthBM"
    app.middleware.use(app.sessions.middleware)
    app.sessions.configuration.cookieFactory = { sessionId in
        .init(string: sessionId.string)
    }
    
    // Routes
}
