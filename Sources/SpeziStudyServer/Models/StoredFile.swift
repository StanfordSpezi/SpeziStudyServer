//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

final class StoredFile: Model, @unchecked Sendable {
    static let schema = "files"

    @ID(key: .id) var id: UUID?

    @OptionalParent(key: "component_id") var component: Component?

    @OptionalParent(key: "study_id") var study: Study?

    @Field(key: "name") var name: String

    @Field(key: "locale") var locale: String

    @Field(key: "content") var content: String

    @Field(key: "type") var type: String

    init() {}

    init(
        componentId: UUID? = nil,
        studyId: UUID? = nil,
        name: String,
        locale: String,
        content: String,
        type: String,
        id: UUID? = nil
    ) {
        precondition(
            (componentId != nil) != (studyId != nil),
            "Exactly one owner FK must be set"
        )
        self.id = id
        self.$component.id = componentId
        self.$study.id = studyId
        self.name = name
        self.locale = locale
        self.content = content
        self.type = type
    }
}
