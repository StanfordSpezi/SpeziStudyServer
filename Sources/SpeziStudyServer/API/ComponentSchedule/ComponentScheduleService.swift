//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

final class ComponentScheduleService: VaporModule, @unchecked Sendable {
    @Dependency(DatabaseStudyRepository.self) var studyRepository: DatabaseStudyRepository
    @Dependency(DatabaseComponentRepository.self) var componentRepository: DatabaseComponentRepository
    @Dependency(DatabaseComponentScheduleRepository.self) var scheduleRepository: DatabaseComponentScheduleRepository

    func listSchedules(studyId: UUID, componentId: UUID) async throws -> [Components.Schemas.ComponentSchedule] {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        let schedules = try await scheduleRepository.findAll(componentId: componentId)

        return try schedules.map { schedule in
            guard let tableId = schedule.id else {
                throw ServerError.internalError(message: "ComponentSchedule missing database ID")
            }
            return try ComponentScheduleMapper.toDTO(schedule.scheduleData, id: tableId, componentId: componentId)
        }
    }

    func getSchedule(studyId: UUID, componentId: UUID, id: UUID) async throws -> Components.Schemas.ComponentSchedule {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        guard let schedule = try await scheduleRepository.find(id: id, componentId: componentId) else {
            throw ServerError.notFound(resource: "ComponentSchedule", identifier: id.uuidString)
        }

        return try ComponentScheduleMapper.toDTO(schedule.scheduleData, id: id, componentId: componentId)
    }

    func createSchedule(
        studyId: UUID,
        componentId: UUID,
        dto: Components.Schemas.ComponentSchedule
    ) async throws -> Components.Schemas.ComponentSchedule {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        // Generate a new UUID for the schedule
        let scheduleId = UUID()

        // Convert DTO to model with IDs injected
        let scheduleData = try ComponentScheduleMapper.toModel(dto, id: scheduleId, componentId: componentId)

        let schedule = ComponentSchedule(
            componentId: componentId,
            scheduleData: scheduleData,
            id: scheduleId
        )

        let createdSchedule = try await scheduleRepository.create(schedule)

        guard createdSchedule.id != nil else {
            throw ServerError.internalError(message: "ComponentSchedule missing database ID after save")
        }

        return try ComponentScheduleMapper.toDTO(scheduleData, id: scheduleId, componentId: componentId)
    }

    func updateSchedule(
        studyId: UUID,
        componentId: UUID,
        id: UUID,
        dto: Components.Schemas.ComponentSchedule
    ) async throws -> Components.Schemas.ComponentSchedule {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        guard let schedule = try await scheduleRepository.find(id: id, componentId: componentId) else {
            throw ServerError.notFound(resource: "ComponentSchedule", identifier: id.uuidString)
        }

        // Convert DTO to model with IDs injected
        let updatedScheduleData = try ComponentScheduleMapper.toModel(dto, id: id, componentId: componentId)
        schedule.scheduleData = updatedScheduleData
        try await scheduleRepository.update(schedule)

        return try ComponentScheduleMapper.toDTO(updatedScheduleData, id: id, componentId: componentId)
    }

    func deleteSchedule(studyId: UUID, componentId: UUID, id: UUID) async throws {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        let deleted = try await scheduleRepository.delete(id: id, componentId: componentId)
        if !deleted {
            throw ServerError.notFound(resource: "ComponentSchedule", identifier: id.uuidString)
        }
    }
}
