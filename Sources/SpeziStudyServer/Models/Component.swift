//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation
import SpeziStudyDefinition

final class Component: Model, @unchecked Sendable {
    static let schema = "components"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Children(for: \.$component) var schedules: [ComponentSchedule]

    @Field(key: "component_data") var componentData: StudyDefinition.Component

    init() {}

    init(
        studyId: UUID,
        componentData: StudyDefinition.Component,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.componentData = componentData
    }
}
