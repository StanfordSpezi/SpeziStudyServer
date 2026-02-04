//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

final class DatabaseComponentRepository: ComponentRepository {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func findAll(studyId: UUID) async throws -> [Component] {
        try await Component.query(on: database)
            .filter(\.$study.$id == studyId)
            .all()
    }

    func find(id: UUID, studyId: UUID) async throws -> Component? {
        // swiftlint:disable:next first_where
        try await Component.query(on: database)
            .filter(\.$id == id)
            .filter(\.$study.$id == studyId)
            .first()
    }

    func create(
        studyId: UUID,
        type: String,
        name: String,
        id: UUID? = nil
    ) async throws -> Component {
        let component = Component(studyId: studyId, type: type, name: name, id: id)
        try await component.save(on: database)
        return component
    }

    func update(_ component: Component) async throws {
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

protocol ComponentRepository: VaporModule {
    func findAll(studyId: UUID) async throws -> [Component]
    func find(id: UUID, studyId: UUID) async throws -> Component?
    func create(studyId: UUID, type: String, name: String, id: UUID?) async throws -> Component
    func update(_ component: Component) async throws
    func delete(id: UUID, studyId: UUID) async throws -> Bool
}
