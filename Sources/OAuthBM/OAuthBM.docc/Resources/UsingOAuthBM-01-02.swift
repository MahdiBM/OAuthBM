import Vapor
import Fluent /// for `SessionRecord.migration`

    .
    .
    .

func setupSessions(app: Application) {
    app.sessions.use(.redis)
    app.migrations.add(SessionRecord.migration)
    app.sessions.configuration.cookieName = "MyAppName"
    app.middleware.use(app.sessions.middleware)
    app.sessions.configuration.cookieFactory = { sessionId in
            .init(string: sessionId.string)
    }
}

    .
    .
    .
