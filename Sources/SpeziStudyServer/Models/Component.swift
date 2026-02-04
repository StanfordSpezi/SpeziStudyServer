//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

final class Component: Model, @unchecked Sendable {
    static let schema = "components"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Field(key: "type") var type: ComponentType

    @Field(key: "name") var name: String

    @Children(for: \.$component) var schedules: [ComponentSchedule]

    init() {}

    init(
        studyId: UUID,
        type: ComponentType,
        name: String,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.type = type
        self.name = name
    }
}
