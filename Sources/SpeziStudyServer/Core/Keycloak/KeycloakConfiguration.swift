//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Vapor


public struct KeycloakConfiguration: Sendable {
    public var url: String
    public var realm: String
    public var clientId: String
    public var clientSecret: String
    public var requiredRole: String

    public var jwksURL: String {
        "\(url)/realms/\(realm)/protocol/openid-connect/certs"
    }

    public init() throws {
        self.url = try Environment.require("KEYCLOAK_URL")
        self.realm = try Environment.require("KEYCLOAK_REALM")
        self.clientId = try Environment.require("KEYCLOAK_CLIENT_ID")
        self.clientSecret = try Environment.require("KEYCLOAK_CLIENT_SECRET")
        self.requiredRole = try Environment.require("KEYCLOAK_REQUIRED_ROLE")
    }
}
