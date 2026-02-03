//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

final class DatabaseComponentScheduleRepository: ComponentScheduleRepository {
    let database: any Database
    
    init(database: any Database) {
        self.database = database
    }
    
    func findAll(componentId: UUID) async throws -> [ComponentSchedule] {
        try await ComponentSchedule.query(on: database)
            .filter(\.$component.$id == componentId)
            .all()
    }

    func find(id: UUID, componentId: UUID) async throws -> ComponentSchedule? {
        guard let schedule = try await ComponentSchedule.find(id, on: database) else {
            return nil
        }

        guard schedule.$component.id == componentId else {
            return nil
        }

        return schedule
    }

    func create(_ schedule: ComponentSchedule) async throws -> ComponentSchedule {
        try await schedule.save(on: database)

        guard let scheduleId = schedule.id,
              let createdSchedule = try await ComponentSchedule.find(scheduleId, on: database) else {
            throw ServerError.Defaults.failedToRetrieveCreatedObject
        }

        return createdSchedule
    }

    func update(_ schedule: ComponentSchedule) async throws {
        try await schedule.update(on: database)
    }

    func delete(id: UUID, componentId: UUID) async throws -> Bool {
        guard let schedule = try await ComponentSchedule.find(id, on: database) else {
            return false
        }

        guard schedule.$component.id == componentId else {
            return false
        }

        try await schedule.delete(on: database)
        return true
    }
}

protocol ComponentScheduleRepository: VaporModule {
    func findAll(componentId: UUID) async throws -> [ComponentSchedule]
    func find(id: UUID, componentId: UUID) async throws -> ComponentSchedule?
    func create(_ schedule: ComponentSchedule) async throws -> ComponentSchedule
    func update(_ schedule: ComponentSchedule) async throws
    func delete(id: UUID, componentId: UUID) async throws -> Bool
}
