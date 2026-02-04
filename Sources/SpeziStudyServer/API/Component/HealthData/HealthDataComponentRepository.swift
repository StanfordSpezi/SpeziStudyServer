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

    func find(id: UUID) async throws -> HealthDataComponent? {
        try await HealthDataComponent.find(id, on: database)
    }

    func create(
        componentId: UUID,
        data: HealthDataContent
    ) async throws -> HealthDataComponent {
        let component = HealthDataComponent(componentId: componentId, data: data)
        try await component.save(on: database)
        return component
    }

    func update(_ component: HealthDataComponent) async throws {
        try await component.update(on: database)
    }

    func delete(id: UUID) async throws -> Bool {
        guard let component = try await find(id: id) else {
            return false
        }
        try await component.delete(on: database)
        return true
    }
}

protocol HealthDataComponentRepository: VaporModule {
    func find(id: UUID) async throws -> HealthDataComponent?
    func create(componentId: UUID, data: HealthDataContent) async throws -> HealthDataComponent
    func update(_ component: HealthDataComponent) async throws
    func delete(id: UUID) async throws -> Bool
}
