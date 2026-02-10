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


enum StudyFixtures {
    @discardableResult
    static func createStudy(
        on database: any Database,
        groupId: UUID,
        id: UUID = UUID(),
        title: String = "Test Study"
    ) async throws -> Study {
        let metadata = StudyDefinition.Metadata(
            id: id,
            title: LocalizedDictionary([.enUS: title]),
            explanationText: LocalizedDictionary([.enUS: "Test explanation"]),
            shortExplanationText: LocalizedDictionary([.enUS: "Test short explanation"]),
            participationCriterion: true,
            enrollmentConditions: .none
        )

        let study = Study(groupId: groupId, metadata: metadata, id: id)
        try await study.save(on: database)
        return study
    }
}
