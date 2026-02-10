//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziStudyDefinition


extension Study {
    convenience init(_ schema: Components.Schemas.StudyInput, groupId: UUID) throws {
        let studyId = UUID()
        var metadataPayload = schema.metadata.additionalProperties
        metadataPayload.value["id"] = studyId.uuidString
        var metadata: StudyDefinition.Metadata = try metadataPayload.recode()
        metadata.id = studyId
        self.init(groupId: groupId, metadata: metadata, id: studyId)
    }
}

extension Components.Schemas.StudyResponse {
    init(_ model: Study) throws {
        let metadata: Components.Schemas.StudyResponse.MetadataPayload = try model.metadata.recode()
        self.init(
            id: try model.requireId().uuidString,
            metadata: metadata
        )
    }
}

extension StudyDefinition.Metadata {
    init(_ schema: Components.Schemas.StudyInput) throws {
        let metadataPayload = schema.metadata.additionalProperties
        self = try metadataPayload.recode()
    }
}
