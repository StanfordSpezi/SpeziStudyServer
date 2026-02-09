//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import SpeziStudyDefinition


class StudyRepository: VaporModule, @unchecked Sendable {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func create(_ study: Study) async throws -> Study {
        try await study.save(on: database)

        guard let createdStudy = try await Study.find(try study.requireId(), on: database) else {
            throw ServerError.Defaults.failedToRetrieveCreatedObject
        }

        return createdStudy
    }

    func find(id: UUID) async throws -> Study? {
        try await Study.find(id, on: database)
    }

    func findGroupName(forStudyId id: UUID) async throws -> String? {
        try await Study.query(on: database)
            .filter(\.$id == id)
            .join(Group.self, on: \Study.$group.$id == \Group.$id)
            .field(Group.self, \.$name)
            .first()
            .flatMap { try? $0.joined(Group.self).name }
    }

    func findWithComponents(id: UUID) async throws -> Study? {
        try await Study.query(on: database)
            .filter(\.$id == id)
            .with(\.$components)
            .first()
    }

    func findWithComponentsAndSchedules(id: UUID) async throws -> Study {
        guard let study = try await Study.query(on: database)
            .filter(\.$id == id)
            .with(\.$components)
            .first() else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        for component in study.components {
            try await component.$schedules.load(on: database)
        }

        return study
    }

    func listIds() async throws -> [UUID] {
        try await Study.query(on: database).all(\.$id)
    }

    func listAll(groupId: UUID) async throws -> [Study] {
        try await Study.query(on: database)
            .filter(\.$group.$id == groupId)
            .all()
    }

    func update(id: UUID, metadata: StudyDefinition.Metadata) async throws -> Study? {
        guard let study = try await Study.find(id, on: database) else {
            return nil
        }

        study.metadata = metadata
        try await study.save(on: database)
        return study
    }

    func delete(id: UUID) async throws -> Bool {
        guard let study = try await Study.find(id, on: database) else {
            return false
        }

        try await study.delete(on: database)
        return true
    }
}
