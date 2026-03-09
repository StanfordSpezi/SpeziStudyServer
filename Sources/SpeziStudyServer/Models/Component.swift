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
import SpeziStudyDefinition


/// Note: This type is mapped from Components.Schemas.InformationalContent via typeOverrides in openapi-generator-config.yaml
struct InformationalContent: Hashable, Codable, Sendable {
    let title: String
    let lede: String?
    let content: String
}

/// Note: This type is mapped from Components.Schemas.QuestionnaireContent via typeOverrides in openapi-generator-config.yaml
struct QuestionnaireContent: Hashable, Codable, Sendable {
    let questionnaire: String
}


enum ComponentData: Codable, Sendable, Hashable {
    case informational(LocalizationsDictionary<InformationalContent>)
    case questionnaire(LocalizationsDictionary<QuestionnaireContent>)
    case healthDataCollection(StudyDefinition.HealthDataCollectionComponent)

    private enum CodingKeys: String, CodingKey {
        case type
        case content
    }

    private enum DataType: String, Codable {
        case informational
        case questionnaire
        case healthDataCollection
    }

    var type: ComponentType {
        switch self {
        case .informational: .informational
        case .questionnaire: .questionnaire
        case .healthDataCollection: .healthDataCollection
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DataType.self, forKey: .type)
        switch type {
        case .informational:
            self = .informational(try container.decode(LocalizationsDictionary<InformationalContent>.self, forKey: .content))
        case .questionnaire:
            self = .questionnaire(try container.decode(LocalizationsDictionary<QuestionnaireContent>.self, forKey: .content))
        case .healthDataCollection:
            self = .healthDataCollection(try container.decode(StudyDefinition.HealthDataCollectionComponent.self, forKey: .content))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .informational(let content):
            try container.encode(DataType.informational, forKey: .type)
            try container.encode(content, forKey: .content)
        case .questionnaire(let content):
            try container.encode(DataType.questionnaire, forKey: .type)
            try container.encode(content, forKey: .content)
        case .healthDataCollection(let content):
            try container.encode(DataType.healthDataCollection, forKey: .type)
            try container.encode(content, forKey: .content)
        }
    }
}


final class Component: Model, @unchecked Sendable {
    static let schema = "components"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Field(key: "data") var data: ComponentData

    @Field(key: "name") var name: String

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Field(key: "type") var type: ComponentType

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$component) var schedules: [ComponentSchedule]

    init() {}

    init(
        studyId: UUID,
        data: ComponentData,
        name: String,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.data = data
        self.type = data.type
        self.name = name
    }
}
