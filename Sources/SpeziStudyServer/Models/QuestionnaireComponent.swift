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

/// Domain model for questionnaire content.
/// Note: This type is mapped from Components.Schemas.QuestionnaireContent via typeOverrides in openapi-generator-config.yaml
struct QuestionnaireContent: Hashable, Codable, Sendable {
    let questionnaire: String
}

/// Database model for questionnaire component
final class QuestionnaireComponent: Model, @unchecked Sendable {
    static let schema = "questionnaire_components"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Field(key: "data") var data: LocalizedDictionary<QuestionnaireContent>

    init() {}

    init(
        studyId: UUID,
        data: LocalizedDictionary<QuestionnaireContent>,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.data = data
    }
}
