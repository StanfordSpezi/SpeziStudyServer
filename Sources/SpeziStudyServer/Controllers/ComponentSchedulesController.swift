//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Controller {
    func getStudiesIdComponentsComponentIdSchedules(
        _ input: Operations.GetStudiesIdComponentsComponentIdSchedules.Input
    ) async throws -> Operations.GetStudiesIdComponentsComponentIdSchedules.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()
        let dtos = try await componentScheduleService.listSchedules(studyId: studyId, componentId: componentId)
        return .ok(.init(body: .json(dtos)))
    }

    func postStudiesIdComponentsComponentIdSchedules(
        _ input: Operations.PostStudiesIdComponentsComponentIdSchedules.Input
    ) async throws -> Operations.PostStudiesIdComponentsComponentIdSchedules.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()
        guard case .json(let scheduleDTO) = input.body else {
            throw ServerError.defaults.jsonBodyRequired
        }

        let responseDTO = try await componentScheduleService.createSchedule(
            studyId: studyId,
            componentId: componentId,
            dto: scheduleDTO
        )
        return .created(.init(body: .json(responseDTO)))
    }

    func getStudiesIdComponentsComponentIdSchedulesScheduleId(
        _ input: Operations.GetStudiesIdComponentsComponentIdSchedulesScheduleId.Input
    ) async throws -> Operations.GetStudiesIdComponentsComponentIdSchedulesScheduleId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()
        let scheduleId = try input.path.scheduleId.toUUID()

        let dto = try await componentScheduleService.getSchedule(
            studyId: studyId,
            componentId: componentId,
            id: scheduleId
        )
        return .ok(.init(body: .json(dto)))
    }

    func putStudiesIdComponentsComponentIdSchedulesScheduleId(
        _ input: Operations.PutStudiesIdComponentsComponentIdSchedulesScheduleId.Input
    ) async throws -> Operations.PutStudiesIdComponentsComponentIdSchedulesScheduleId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()
        let scheduleId = try input.path.scheduleId.toUUID()

        guard case .json(let scheduleDTO) = input.body else {
            throw ServerError.defaults.jsonBodyRequired
        }

        let responseDTO = try await componentScheduleService.updateSchedule(
            studyId: studyId,
            componentId: componentId,
            id: scheduleId,
            dto: scheduleDTO
        )
        return .ok(.init(body: .json(responseDTO)))
    }

    func deleteStudiesIdComponentsComponentIdSchedulesScheduleId(
        _ input: Operations.DeleteStudiesIdComponentsComponentIdSchedulesScheduleId.Input
    ) async throws -> Operations.DeleteStudiesIdComponentsComponentIdSchedulesScheduleId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()
        let scheduleId = try input.path.scheduleId.toUUID()

        try await componentScheduleService.deleteSchedule(
            studyId: studyId,
            componentId: componentId,
            id: scheduleId
        )
        return .noContent(.init())
    }
}
