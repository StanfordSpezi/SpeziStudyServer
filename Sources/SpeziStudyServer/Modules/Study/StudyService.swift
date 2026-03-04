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


final class StudyService: Module, @unchecked Sendable {
    @Dependency(StudyRepository.self) var repository: StudyRepository
    @Dependency(GroupService.self) var groupService: GroupService

    init() {}

    func checkHasAccess(to id: UUID, role: AuthContext.GroupRole) async throws {
        guard let groupName = try await repository.findGroupName(forStudyId: id) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        try AuthContext.requireCurrent().checkHasAccess(groupName: groupName, role: role)
    }

    func getStudy(id: UUID) async throws -> Study {
        try await checkHasAccess(to: id, role: .researcher)

        guard let study = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        return study
    }

    func createStudy(groupId: UUID, study: Study) async throws -> Study {
        try await groupService.checkHasAccess(to: groupId, role: .admin)
        return try await repository.create(study)
    }

    func listStudies(groupId: UUID) async throws -> [Study] {
        try await groupService.checkHasAccess(to: groupId, role: .researcher)
        return try await repository.listAll(groupId: groupId)
    }

    func patchStudy(id: UUID, patch: StudyPatch) async throws -> Study {
        try await checkHasAccess(to: id, role: .researcher)

        guard let study = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        study.apply(patch)
        return try await repository.update(study)
    }

    func deleteStudy(id: UUID) async throws {
        try await checkHasAccess(to: id, role: .admin)

        let deleted = try await repository.delete(id: id)
        if !deleted {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }
    }
}
