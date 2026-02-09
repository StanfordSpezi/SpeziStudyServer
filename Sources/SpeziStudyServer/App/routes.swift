//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "It works!"
    }
    
    let controller = Controller(spezi: app.spezi)

    let transport = VaporTransport(routesBuilder: app)
    try controller.registerHandlers(
        on: transport,
        serverURL: URL(string: "/")!,
        middlewares: [ErrorMiddleware(logger: app.logger)]
    )
}
