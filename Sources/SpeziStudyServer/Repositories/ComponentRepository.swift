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
        guard let component = try await Component.find(id, on: database) else {
            return nil
        }

        guard component.$study.id == studyId else {
            return nil
        }

        return component
    }

    func create(_ component: Component) async throws -> Component {
        try await component.save(on: database)

        guard let componentId = component.id,
              let createdComponent = try await Component.find(componentId, on: database) else {
            throw ServerError.Defaults.failedToRetrieveCreatedObject
        }

        return createdComponent
    }

    func update(_ component: Component) async throws {
        try await component.update(on: database)
    }

    func delete(id: UUID, studyId: UUID) async throws -> Bool {
        guard let component = try await Component.find(id, on: database) else {
            return false
        }

        guard component.$study.id == studyId else {
            return false
        }

        try await component.delete(on: database)
        return true
    }
}

protocol ComponentRepository: VaporModule {
    func findAll(studyId: UUID) async throws -> [Component]
    func find(id: UUID, studyId: UUID) async throws -> Component?
    func create(_ component: Component) async throws -> Component
    func update(_ component: Component) async throws
    func delete(id: UUID, studyId: UUID) async throws -> Bool
}
