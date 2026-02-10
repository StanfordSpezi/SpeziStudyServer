//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Vapor


public struct KeycloakConfiguration: Sendable {
    public static let `default` = KeycloakConfiguration()

    public var url: String = Environment.get("KEYCLOAK_URL") ?? "http://localhost:8180"
    public var realm: String = Environment.get("KEYCLOAK_REALM") ?? "spezi-study"
    public var clientId: String = Environment.get("KEYCLOAK_CLIENT_ID") ?? "spezi-study-server"
    public var clientSecret: String = Environment.get("KEYCLOAK_CLIENT_SECRET") ?? "change-me-in-production"
    public var requiredRole: String = Environment.get("KEYCLOAK_REQUIRED_ROLE") ?? "spezistudyplatform-authorized-users"

    public var jwksURL: String {
        "\(url)/realms/\(realm)/protocol/openid-connect/certs"
    }
}
