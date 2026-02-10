//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


final class GroupService: Module, @unchecked Sendable {
    @Dependency(GroupRepository.self) var repository: GroupRepository

    init() {}

    func listGroups() async throws -> [Components.Schemas.GroupResponse] {
        let groups = try await repository.listAll()
        return try groups.map { try .init($0) }
    }

    func getGroup(id: UUID) async throws -> Components.Schemas.GroupResponse {
        guard let group = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "Group", identifier: id.uuidString)
        }

        return try .init(group)
    }

    func requireGroupAccess(id: UUID, role: AuthContext.GroupRole = .researcher) async throws {
        guard let group = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "Group", identifier: id.uuidString)
        }

        try AuthContext.requireCurrent().requireGroupAccess(groupName: group.name, role: role)
    }

    /// Creates local groups for any Keycloak top-level groups not yet in the database.
    /// Groups removed from Keycloak are kept locally to preserve associated studies.
    func syncGroups(from keycloakGroups: [KeycloakGroup]) async throws {
        let existingNames = Set(try await repository.listAll().map(\.name))

        for keycloakGroup in keycloakGroups where !existingNames.contains(keycloakGroup.name) {
            _ = try await repository.create(Group(name: keycloakGroup.name, icon: "tree"))
        }
    }
}
