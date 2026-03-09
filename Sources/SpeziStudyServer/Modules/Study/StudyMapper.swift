//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLocalization
import SpeziStudyDefinition


extension Study {
    convenience init(_ schema: Components.Schemas.StudyCreateInput, groupId: UUID) {
        self.init(
            groupId: groupId,
            locales: [.enUS],
            icon: schema.icon,
            details: .init([.enUS: StudyDetailContent(title: schema.title)]),
            id: UUID()
        )
    }
}

extension StudyPatch {
    init(_ schema: Components.Schemas.StudyPatchInput) {
        self.init(
            locales: schema.locales.map(Set.init),
            icon: schema.icon,
            details: schema.details,
            participationCriterion: schema.participationCriterion.map { .init($0) },
            consent: schema.consent,
            enrollmentConditions: schema.enrollmentConditions.map { .init($0) }
        )
    }
}

extension Components.Schemas.StudyListItem {
    init(_ model: Study) throws {
        let title = model.details[.enUS]?.title ?? model.details.first?.value.title ?? ""
        self.init(
            id: try model.requireId().uuidString,
            title: title
        )
    }
}

extension Components.Schemas.StudyResponse {
    init(_ model: Study) throws {
        self.init(
            id: try model.requireId().uuidString,
            locales: model.locales.sorted(using: KeyPathComparator(\.description)),
            icon: model.icon,
            details: model.details,
            participationCriterion: try .init(model.participationCriterion),
            consent: model.consent,
            enrollmentConditions: .init(model.enrollmentConditions)
        )
    }
}

extension Components.Schemas.PublishedStudyResponse {
    init(_ model: PublishedStudy) throws {
        self.init(
            id: try model.requireId().uuidString,
            studyId: model.$study.id.uuidString,
            revision: model.revision,
            visibility: .init(rawValue: model.visibility.rawValue)!,
            bundleURL: model.bundleURL.absoluteString,
            publishedAt: model.publishedAt ?? Date()
        )
    }
}


// MARK: - ParticipationCriterion Mapping

extension Components.Schemas.ParticipationCriterion {
    init(_ model: StudyDefinition.ParticipationCriterion) throws {
        switch model {
        case .ageAtLeast(let age):
            self = .ageAtLeast(.init(_type: .ageAtLeast, age: age))
        case .isFromRegion(let region):
            self = .isFromRegion(.init(_type: .isFromRegion, region: region.identifier))
        case .speaksLanguage(let language):
            self = .speaksLanguage(.init(_type: .speaksLanguage, language: language.minimalIdentifier))
        case .custom:
            throw ServerError.internalServerError("Custom participation criteria are not supported by the API")
        case .not(let criterion):
            self = .not(.init(_type: .not, criterion: try .init(criterion)))
        case .all(let criteria):
            self = .all(.init(_type: .all, criteria: try criteria.map { try .init($0) }))
        case .any(let criteria):
            self = .any(.init(_type: .any, criteria: try criteria.map { try .init($0) }))
        }
    }
}

extension StudyDefinition.ParticipationCriterion {
    init(_ schema: Components.Schemas.ParticipationCriterion) {
        switch schema {
        case .ageAtLeast(let value):
            self = .ageAtLeast(value.age)
        case .isFromRegion(let value):
            self = .isFromRegion(Locale.Region(value.region))
        case .speaksLanguage(let value):
            self = .speaksLanguage(Locale.Language(identifier: value.language))
        case .not(let value):
            self = .not(.init(value.criterion))
        case .all(let value):
            self = .all(value.criteria.map { .init($0) })
        case .any(let value):
            self = .any(value.criteria.map { .init($0) })
        }
    }
}


// MARK: - EnrollmentConditions Mapping

extension Components.Schemas.EnrollmentConditions {
    init(_ model: StudyDefinition.EnrollmentConditions) {
        switch model {
        case .none:
            self = .none
        case .requiresInvitation:
            self = .requiresInvitationCode
        }
    }
}

extension StudyDefinition.EnrollmentConditions {
    init(_ schema: Components.Schemas.EnrollmentConditions) {
        switch schema {
        case .none:
            self = .none
        case .requiresInvitationCode:
            self = .requiresInvitation(verificationEndpoint: URL(string: "https://placeholder.invalid")!)  // swiftlint:disable:this force_unwrapping
        }
    }
}
