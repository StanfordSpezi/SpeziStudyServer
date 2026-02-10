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


// MARK: - AuthContext

struct AuthContext: Sendable {
    enum GroupRole: String, Sendable, Comparable {
        case researcher
        case admin

        private var level: Int {
            switch self {
            case .researcher: 0
            case .admin: 1
            }
        }

        static func < (lhs: GroupRole, rhs: GroupRole) -> Bool {
            lhs.level < rhs.level
        }
    }

    @TaskLocal static var current: AuthContext?

    let roles: [String]
    let groups: [String]

    /// Parses JWT group paths (e.g., "/Stanford Biodesign Digital Health/admin") into a membership map.
    var groupMemberships: [String: GroupRole] {
        var memberships: [String: GroupRole] = [:]
        for path in groups {
            guard path.hasPrefix("/") else { continue }
            let parts = path.dropFirst().split(separator: "/", maxSplits: 1)
            guard parts.count == 2,
                  let role = GroupRole(rawValue: String(parts[1])) else {
                continue
            }
            memberships[String(parts[0])] = role
        }
        return memberships
    }

    static func requireCurrent() throws -> AuthContext {
        guard let context = current else {
            throw ServerError.Defaults.missingToken
        }
        return context
    }

    func requireGroupAccess(groupName: String, role: GroupRole = .researcher) throws {
        guard let memberRole = groupMemberships[groupName], memberRole >= role else {
            throw ServerError.Defaults.forbidden
        }
    }
}


// MARK: - AuthMiddleware

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
