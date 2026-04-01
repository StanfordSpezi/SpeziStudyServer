//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import SpeziLocalization
import SpeziStudyDefinition
import SpeziStudyPlatformAPIServer


final class PublishedStudy: Model, @unchecked Sendable {
    static let schema = "published_studies"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Field(key: "revision") var revision: UInt

    @Field(key: "visibility") var visibility: StudyVisibility

    @Field(key: "enrollment_condition") var enrollmentCondition: EnrollmentConditions

    @Field(key: "bundle_url") var bundleURL: URL

    @Field(key: "metadata") var metadata: StudyDefinition.Metadata

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        studyId: UUID,
        revision: UInt,
        visibility: StudyVisibility,
        enrollmentCondition: EnrollmentConditions,
        bundleURL: URL,
        metadata: StudyDefinition.Metadata,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.revision = revision
        self.visibility = visibility
        self.enrollmentCondition = enrollmentCondition
        self.bundleURL = bundleURL
        self.metadata = metadata
    }
}
