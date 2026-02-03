//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

final class DatabaseHealthDataComponentRepository: HealthDataComponentRepository {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func findAll(studyId: UUID) async throws -> [HealthDataComponent] {
        try await HealthDataComponent.query(on: database)
            .filter(\.$study.$id == studyId)
            .all()
    }

    func find(id: UUID, studyId: UUID) async throws -> HealthDataComponent? {
        // swiftlint:disable:next first_where
        try await HealthDataComponent.query(on: database)
            .filter(\.$id == id)
            .filter(\.$study.$id == studyId)
            .first()
    }

    func create(
        studyId: UUID,
        data: HealthDataContent
    ) async throws -> HealthDataComponent {
        let component = HealthDataComponent(studyId: studyId, data: data)
        try await component.save(on: database)
        return component
    }

    func update(_ component: HealthDataComponent) async throws {
        try await component.update(on: database)
    }

    func delete(id: UUID, studyId: UUID) async throws -> Bool {
        guard let component = try await find(id: id, studyId: studyId) else {
            return false
        }
        try await component.delete(on: database)
        return true
    }
}

protocol HealthDataComponentRepository: VaporModule {
    func findAll(studyId: UUID) async throws -> [HealthDataComponent]
    func find(id: UUID, studyId: UUID) async throws -> HealthDataComponent?
    func create(studyId: UUID, data: HealthDataContent) async throws -> HealthDataComponent
    func update(_ component: HealthDataComponent) async throws
    func delete(id: UUID, studyId: UUID) async throws -> Bool
}
