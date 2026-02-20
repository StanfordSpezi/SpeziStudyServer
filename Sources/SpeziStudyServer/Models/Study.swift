//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import SpeziLocalization
import SpeziStudyDefinition
import Vapor


/// Note: This type is mapped from Components.Schemas.StudyDetailContent via typeOverrides in openapi-generator-config.yaml
struct StudyDetailContent: Codable, Sendable, Hashable {
    var title: String
    var shortTitle: String
    var explanationText: String
    var shortExplanationText: String

    init(title: String = "", shortTitle: String = "", explanationText: String = "", shortExplanationText: String = "") {
        self.title = title
        self.shortTitle = shortTitle
        self.explanationText = explanationText
        self.shortExplanationText = shortExplanationText
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.shortTitle = try container.decodeIfPresent(String.self, forKey: .shortTitle) ?? ""
        self.explanationText = try container.decodeIfPresent(String.self, forKey: .explanationText) ?? ""
        self.shortExplanationText = try container.decodeIfPresent(String.self, forKey: .shortExplanationText) ?? ""
    }
}


struct StudyPatch: Sendable {
    var locales: [String]? // swiftlint:disable:this discouraged_optional_collection
    var icon: String?
    var details: LocalizationsDictionary<StudyDetailContent>?
    var participationCriterion: StudyDefinition.ParticipationCriterion?
    var consent: LocalizationsDictionary<String>?
}


final class Study: Model, @unchecked Sendable {
    static let schema = "studies"

    @ID(key: .id) var id: UUID?

    @Parent(key: "group_id") var group: Group

    @Field(key: "locales") var locales: [String]

    @Field(key: "icon") var icon: String

    @Field(key: "details") var details: LocalizationsDictionary<StudyDetailContent>

    @Field(key: "participation_criterion") var participationCriterion: StudyDefinition.ParticipationCriterion

    @Field(key: "consent") var consent: LocalizationsDictionary<String>

    @Children(for: \.$study) var components: [Component]

    init() {}

    init(
        groupId: UUID,
        locales: [String],
        icon: String,
        details: LocalizationsDictionary<StudyDetailContent> = .init(),
        participationCriterion: StudyDefinition.ParticipationCriterion = .all([]),
        consent: LocalizationsDictionary<String> = .init(),
        id: UUID? = nil
    ) {
        self.id = id
        self.$group.id = groupId
        self.locales = locales
        self.icon = icon
        self.details = details
        self.participationCriterion = participationCriterion
        self.consent = consent
    }

    func apply(_ patch: StudyPatch) {
        if let locales = patch.locales { self.locales = locales }
        if let icon = patch.icon { self.icon = icon }
        if let details = patch.details { self.details = details }
        if let participationCriterion = patch.participationCriterion { self.participationCriterion = participationCriterion }
        if let consent = patch.consent { self.consent = consent }
    }
}
