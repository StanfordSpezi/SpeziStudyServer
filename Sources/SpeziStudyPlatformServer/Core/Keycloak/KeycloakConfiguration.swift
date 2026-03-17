//
// This source file is part of the Stanford Spezi open source project
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
    public var researcherRole: String
    public var participantRole: String

    public var jwksURL: String {
        "\(url)/realms/\(realm)/protocol/openid-connect/certs"
    }

    public init() throws {
        self.url = try Environment.require("KEYCLOAK_URL")
        self.realm = try Environment.require("KEYCLOAK_REALM")
        self.clientId = try Environment.require("KEYCLOAK_CLIENT_ID")
        self.clientSecret = try Environment.require("KEYCLOAK_CLIENT_SECRET")
        self.researcherRole = try Environment.require("KEYCLOAK_RESEARCHER_ROLE")
        self.participantRole = try Environment.require("KEYCLOAK_PARTICIPANT_ROLE")
    }
}
