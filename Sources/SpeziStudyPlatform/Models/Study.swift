//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import SpeziLocalization
import SpeziStudyDefinition
import Vapor


/// Note: This type is mapped from Components.Schemas.EnrollmentConditions via typeOverrides in openapi-generator-config.yaml
enum EnrollmentConditions: String, Codable, Sendable {
    /// No special conditions — anyone can enroll.
    case none
    /// Enrollment requires a valid invitation code.
    case requiresInvitationCode
}


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

/// Note: This type is mapped from Components.Schemas.ConsentContent via typeOverrides in openapi-generator-config.yaml
struct ConsentContent: Codable, Sendable, Hashable {
    var title: String
    var content: String

    init(title: String = "", content: String = "") {
        self.title = title
        self.content = content
    }
}

struct StudyPatch: Sendable {
    var locales: Set<LocalizationKey>? // swiftlint:disable:this discouraged_optional_collection
    var icon: String?
    var details: LocalizationsDictionary<StudyDetailContent>?
    var participationCriterion: StudyDefinition.ParticipationCriterion?
    var consent: LocalizationsDictionary<ConsentContent>?
    var visibility: StudyVisibility?
    var enrollmentCondition: EnrollmentConditions?
}


final class Study: Model, @unchecked Sendable {
    static let schema = "studies"

    @ID(key: .id) var id: UUID?

    @Parent(key: "group_id") var group: Group

    @Field(key: "locales") var locales: Set<LocalizationKey>

    @Field(key: "icon") var icon: String

    @Field(key: "details") var details: LocalizationsDictionary<StudyDetailContent>

    @Field(key: "participation_criterion") var participationCriterion: StudyDefinition.ParticipationCriterion

    @Field(key: "consent") var consent: LocalizationsDictionary<ConsentContent>

    @Field(key: "visibility") var visibility: StudyVisibility

    @Field(key: "enrollment_condition") var enrollmentCondition: EnrollmentConditions

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$study) var components: [Component]

    @Children(for: \.$study) var publishedStudies: [PublishedStudy]

    @Children(for: \.$study) var enrollments: [Enrollment]

    @Children(for: \.$study) var invitationCodes: [InvitationCode]

    init() {}

    init(
        groupId: UUID,
        locales: Set<LocalizationKey>,
        icon: String,
        details: LocalizationsDictionary<StudyDetailContent> = .init(),
        participationCriterion: StudyDefinition.ParticipationCriterion = .all([]),
        consent: LocalizationsDictionary<ConsentContent> = .init(),
        visibility: StudyVisibility = .public,
        enrollmentCondition: EnrollmentConditions = .none,
        id: UUID? = nil
    ) {
        self.id = id
        self.$group.id = groupId
        self.locales = locales
        self.icon = icon
        self.details = details
        self.participationCriterion = participationCriterion
        self.consent = consent
        self.visibility = visibility
        self.enrollmentCondition = enrollmentCondition
    }

    func apply(_ patch: StudyPatch) {
        func apply<T>(_ otherKeyPath: KeyPath<StudyPatch, T?>, to selfKeyPath: ReferenceWritableKeyPath<Study, T>) {
            if let value = patch[keyPath: otherKeyPath] {
                self[keyPath: selfKeyPath] = value
            }
        }

        apply(\.locales, to: \.locales)
        apply(\.icon, to: \.icon)
        apply(\.details, to: \.details)
        apply(\.participationCriterion, to: \.participationCriterion)
        apply(\.consent, to: \.consent)
        apply(\.visibility, to: \.visibility)
        apply(\.enrollmentCondition, to: \.enrollmentCondition)
    }
}
