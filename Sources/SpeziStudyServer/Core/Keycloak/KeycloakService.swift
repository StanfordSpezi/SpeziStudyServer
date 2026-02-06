//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


struct KeycloakGroup: Decodable, Sendable {
    let id: UUID
    let name: String
    let subGroups: [KeycloakGroup]
}

enum KeycloakError: Error, CustomStringConvertible {
    case failedToAuthenticate(statusCode: Int, body: String)
    case failedToFetchGroups(statusCode: Int, body: String)

    var description: String {
        switch self {
        case let .failedToAuthenticate(statusCode, body):
            "Failed to authenticate with Keycloak (HTTP \(statusCode)): \(body)"
        case let .failedToFetchGroups(statusCode, body):
            "Failed to fetch groups from Keycloak (HTTP \(statusCode)): \(body)"
        }
    }
}

final class KeycloakService: VaporModule, @unchecked Sendable {
    private struct TokenResponse: Decodable {
        let access_token: String // swiftlint:disable:this identifier_name
    }

    init() {}

    func fetchGroups(config: KeycloakConfiguration.Config) async throws -> [KeycloakGroup] {
        let token = try await fetchAccessToken(config: config)

        var request = URLRequest(url: URL(string: "\(config.url)/admin/realms/\(config.realm)/groups")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = response as? HTTPURLResponse
        guard httpResponse?.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw KeycloakError.failedToFetchGroups(statusCode: httpResponse?.statusCode ?? 0, body: body)
        }

        return try JSONDecoder().decode([KeycloakGroup].self, from: data)
    }

    private func fetchAccessToken(config: KeycloakConfiguration.Config) async throws -> String {
        let tokenURL = URL(string: "\(config.url)/realms/\(config.realm)/protocol/openid-connect/token")!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=client_credentials",
            "client_id=\(config.clientId)",
            "client_secret=\(config.clientSecret)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = response as? HTTPURLResponse
        guard httpResponse?.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw KeycloakError.failedToAuthenticate(statusCode: httpResponse?.statusCode ?? 0, body: body)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.access_token
    }
}
