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


/// Whether a published study is visible when browsing or only accessible via invitation code.
enum StudyVisibility: String, Codable, Sendable {
    /// Listed in public study browsing.
    case `public`
    /// Only accessible via an invitation code.
    case unlisted
}


/// Snapshot of study metadata at the time of publishing.
struct PublishedStudyMetadata: Codable, Sendable {
    var locales: Set<LocalizationKey>
    var icon: String
    var details: LocalizationsDictionary<StudyDetailContent>
    var participationCriterion: StudyDefinition.ParticipationCriterion
    var consent: LocalizationsDictionary<String>
    var enrollmentConditions: StudyDefinition.EnrollmentConditions
}


final class PublishedStudy: Model, @unchecked Sendable {
    static let schema = "published_studies"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Field(key: "revision") var revision: Int

    @Field(key: "visibility") var visibility: StudyVisibility

    @Field(key: "bundle_url") var bundleURL: URL

    @Field(key: "metadata") var metadata: PublishedStudyMetadata

    @Timestamp(key: "published_at", on: .create) var publishedAt: Date?

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        studyId: UUID,
        revision: Int,
        visibility: StudyVisibility,
        bundleURL: URL,
        metadata: PublishedStudyMetadata,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.revision = revision
        self.visibility = visibility
        self.bundleURL = bundleURL
        self.metadata = metadata
    }
}
