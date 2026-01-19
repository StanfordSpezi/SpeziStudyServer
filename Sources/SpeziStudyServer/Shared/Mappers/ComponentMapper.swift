//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

enum ComponentMapper {
    static func toModel(_ dto: Components.Schemas.StudyComponent, id: UUID) throws -> StudyDefinition.Component {
        var dto = dto
        var json = dto.additionalProperties.value
        guard let typeKey = json.keys.first,
              var typePayload = json[typeKey] as? [String: (any Sendable)?],
              var componentPayload = typePayload["_0"] as? [String: (any Sendable)?] else {
            throw ServerError.validation(message: "Missing enum encoding")
        }

        // Inject the provided ID
        componentPayload["id"] = id.uuidString
        typePayload["_0"] = componentPayload
        json[typeKey] = typePayload
        dto.additionalProperties.value = json
        return try dto.additionalProperties.recode()
    }

    static func toDTO(_ component: StudyDefinition.Component) throws -> Components.Schemas.StudyComponent {
        try component.recode()
    }

    static func toDTO(_ components: [StudyDefinition.Component]) throws -> [Components.Schemas.StudyComponent] {
        try components.map { try toDTO($0) }
    }
}
