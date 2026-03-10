//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import Spezi


final class ComponentScheduleRepository: Module, Sendable {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func findAll(componentId: UUID) async throws -> [ComponentSchedule] {
        try await ComponentSchedule.query(on: database)
            .filter(\.$component.$id == componentId)
            .all()
    }

    func find(id: UUID) async throws -> ComponentSchedule? {
        try await ComponentSchedule.find(id, on: database)
    }

    func create(_ schedule: ComponentSchedule) async throws -> ComponentSchedule {
        try await schedule.save(on: database)
        return schedule
    }

    func update(_ schedule: ComponentSchedule) async throws {
        try await schedule.update(on: database)
    }

    func delete(id: UUID) async throws -> Bool {
        guard let schedule = try await find(id: id) else {
            return false
        }
        try await schedule.delete(on: database)
        return true
    }
}
