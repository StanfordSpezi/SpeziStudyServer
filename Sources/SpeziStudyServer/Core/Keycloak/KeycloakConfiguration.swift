//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Vapor


public enum KeycloakConfiguration: Sendable {
    case enabled(Config)
    case disabled

    public struct Config: Sendable {
        public static let `default` = Config()

        public var url: String = Environment.get("KEYCLOAK_URL") ?? "http://localhost:8180"
        public var realm: String = Environment.get("KEYCLOAK_REALM") ?? "spezi-study"
        public var clientId: String = Environment.get("KEYCLOAK_CLIENT_ID") ?? "spezi-study-server"
        public var clientSecret: String = Environment.get("KEYCLOAK_CLIENT_SECRET") ?? "change-me-in-production"
    }

    public static let production = KeycloakConfiguration.enabled(.default)
    public static let testing = KeycloakConfiguration.disabled

    public var jwksURL: String? {
        switch self {
        case .enabled(let config):
            return "\(config.url)/realms/\(config.realm)/protocol/openid-connect/certs"
        case .disabled:
            return nil
        }
    }
}
