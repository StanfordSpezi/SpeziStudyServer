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
@testable import SpeziStudyServer


enum PublishedStudyFixtures {
    @discardableResult
    static func createPublishedStudy(
        on database: any Database,
        studyId: UUID,
        revision: Int = 1,
        visibility: StudyVisibility = .public,
        title: String = "Test Study",
        icon: String = "heart"
    ) async throws -> PublishedStudy {
        let metadata = PublishedStudyMetadata(
            locales: [.enUS],
            icon: icon,
            details: .init([.enUS: StudyDetailContent(title: title)]),
            participationCriterion: .all([]),
            consent: .init(),
            enrollmentConditions: .none
        )
        let published = PublishedStudy(
            studyId: studyId,
            revision: revision,
            visibility: visibility,
            bundleURL: URL(string: "https://example.com/bundle.zip")!,
            metadata: metadata
        )
        try await published.save(on: database)
        return published
    }
}
