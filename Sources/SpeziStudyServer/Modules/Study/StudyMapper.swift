//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

enum StudyMapper {
    static func toModel(_ dto: Components.Schemas.StudyInput) throws -> Study {
        let studyId = UUID()
        var metadataPayload = dto.metadata.additionalProperties
        metadataPayload.value["id"] = studyId.uuidString
        var metadata: StudyDefinition.Metadata = try metadataPayload.recode()
        metadata.id = studyId
        return Study(metadata: metadata, id: studyId)
    }

    static func toDTO(_ model: Study) throws -> Components.Schemas.StudyResponse {
        guard let id = model.id else {
            throw ServerError.Defaults.unexpectedError
        }

        let metadata: Components.Schemas.StudyResponse.MetadataPayload = try model.metadata.recode()
        return Components.Schemas.StudyResponse(
            id: id.uuidString,
            metadata: metadata
        )
    }

    static func toMetadata(_ dto: Components.Schemas.StudyInput) throws -> StudyDefinition.Metadata {
        let metadataPayload = dto.metadata.additionalProperties
        let metadata: StudyDefinition.Metadata = try metadataPayload.recode()
        return metadata
    }
}
