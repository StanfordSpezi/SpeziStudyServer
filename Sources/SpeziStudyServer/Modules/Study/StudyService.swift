//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Logging
import Spezi
import SpeziStudyDefinition


final class StudyService: @unchecked Sendable, Module {
    @Dependency(StudyRepository.self) var repository: StudyRepository
    @Dependency(GroupService.self) var groupService: GroupService

    init() {}

    func createStudy(
        groupId: UUID,
        _ schema: Components.Schemas.StudyInput
    ) async throws -> Components.Schemas.StudyResponse {
        try await groupService.validateExists(id: groupId)
        let study = try Study(schema, groupId: groupId)
        let createdStudy = try await repository.create(study)
        return try .init(createdStudy)
    }

    func listStudies(groupId: UUID) async throws -> [Components.Schemas.StudyResponse] {
        try await groupService.validateExists(id: groupId)
        let studies = try await repository.listAll(groupId: groupId)
        return try studies.map { try .init($0) }
    }

    func getStudy(id: UUID) async throws -> Components.Schemas.StudyResponse {
        guard let study = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        return try .init(study)
    }

    func updateStudy(id: UUID, schema: Components.Schemas.StudyInput) async throws -> Components.Schemas.StudyResponse {
        let metadata = try StudyDefinition.Metadata(schema)
        guard let updatedStudy = try await repository.update(id: id, metadata: metadata) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        return try .init(updatedStudy)
    }

    func deleteStudy(id: UUID) async throws {
        let deleted = try await repository.delete(id: id)
        if !deleted {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }
    }

    func validateExists(id: UUID) async throws {
        if try await repository.find(id: id) == nil {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }
    }
}
