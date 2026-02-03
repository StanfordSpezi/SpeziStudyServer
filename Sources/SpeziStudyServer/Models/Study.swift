//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import SpeziStudyDefinition
import Vapor

final class Study: Model, @unchecked Sendable {
    static let schema = "studies"

    @ID(key: .id) var id: UUID?

    @Field(key: "metadata") var metadata: StudyDefinition.Metadata

    @Children(for: \.$study) var components: [Component]

    init() {}

    init(
        metadata: StudyDefinition.Metadata,
        id: UUID? = nil
    ) {
        self.id = id
        self.metadata = metadata
    }
}
