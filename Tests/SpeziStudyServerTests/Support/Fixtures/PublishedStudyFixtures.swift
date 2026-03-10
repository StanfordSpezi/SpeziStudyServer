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
        let metadata = StudyDefinition.Metadata(
            id: studyId,
            title: .init([.enUS: title]),
            icon: .systemSymbol(icon),
            explanationText: .init([.enUS: ""]),
            shortExplanationText: .init([.enUS: ""]),
            participationCriterion: .all([]),
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
