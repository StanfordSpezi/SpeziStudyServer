//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

enum ComponentScheduleMapper {
    static func toModel(
        _ dto: Components.Schemas.ComponentSchedule,
        id: UUID,
        componentId: UUID
    ) throws -> StudyDefinition.ComponentSchedule {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(dto)

        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServerError.internalError(message: "Failed to convert component schedule DTO to JSON")
        }

        // Inject the id and componentId fields
        json["id"] = id.uuidString
        json["componentId"] = componentId.uuidString

        let modifiedData = try JSONSerialization.data(withJSONObject: json)
        return try decoder.decode(StudyDefinition.ComponentSchedule.self, from: modifiedData)
    }

    static func toDTO(
        _ schedule: StudyDefinition.ComponentSchedule,
        id: UUID,
        componentId: UUID
    ) throws -> Components.Schemas.ComponentSchedule {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(schedule)

        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServerError.internalError(message: "Failed to convert component schedule to JSON")
        }

        // Ensure the id and componentId fields are set
        json["id"] = id.uuidString
        json["componentId"] = componentId.uuidString

        let modifiedData = try JSONSerialization.data(withJSONObject: json)
        return try decoder.decode(Components.Schemas.ComponentSchedule.self, from: modifiedData)
    }

    static func toDTO(
        _ schedules: [StudyDefinition.ComponentSchedule],
        componentId: UUID
    ) throws -> [Components.Schemas.ComponentSchedule] {
        try schedules.compactMap { schedule in
            // Extract the id from the schedule's JSON representation
            let encoder = JSONEncoder()
            let data = try encoder.encode(schedule)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let idString = json["id"] as? String,
                  let scheduleId = UUID(uuidString: idString) else {
                throw ServerError.internalError(message: "ComponentSchedule missing id field")
            }
            return try toDTO(schedule, id: scheduleId, componentId: componentId)
        }
    }
}
