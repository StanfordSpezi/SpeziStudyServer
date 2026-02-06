//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import SpeziLocalization


/// Note: This type is mapped from Components.Schemas.QuestionnaireContent via typeOverrides in openapi-generator-config.yaml
struct QuestionnaireContent: Hashable, Codable, Sendable {
    let questionnaire: String
}

final class QuestionnaireComponent: Model, @unchecked Sendable {
    static let schema = "questionnaire_components"

    @ID(custom: "component_id") var id: UUID?

    @Field(key: "data") var data: LocalizedDictionary<QuestionnaireContent>

    init() {}

    init(componentId: UUID, data: LocalizedDictionary<QuestionnaireContent>) {
        self.id = componentId
        self.data = data
    }
}
