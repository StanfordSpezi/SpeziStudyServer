//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HTTPTypes
import JWTKit
import Logging
import OpenAPIRuntime


struct AuthMiddleware: ServerMiddleware {
    let keyCollection: JWTKeyCollection
    let requiredRole: String
    let logger: Logger

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard let authHeader = request.headerFields[.authorization] else {
            throw ServerError.Defaults.missingToken
        }

        guard authHeader.lowercased().hasPrefix("bearer "),
              authHeader.count > 7 else {
            throw ServerError.Defaults.invalidToken
        }

        let token = String(authHeader.dropFirst(7))

        let payload: KeycloakJWTPayload
        do {
            payload = try await keyCollection.verify(token, as: KeycloakJWTPayload.self)
        } catch {
            logger.info("JWT verification failed: \(error)")
            throw ServerError.Defaults.invalidToken
        }

        let roles = payload.roles ?? []
        guard roles.contains(requiredRole) else {
            throw ServerError.Defaults.forbidden
        }

        let authContext = AuthContext(
            roles: roles,
            groups: payload.groups ?? []
        )

        return try await AuthContext.$current.withValue(authContext) {
            try await next(request, body, metadata)
        }
    }
}
