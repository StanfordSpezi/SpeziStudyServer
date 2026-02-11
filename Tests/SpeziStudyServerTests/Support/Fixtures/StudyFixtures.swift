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
@testable import SpeziStudyServer


enum StudyFixtures {
    @discardableResult
    static func createStudy(
        on database: any Database,
        groupId: UUID,
        id: UUID = UUID(),
        title: String = "Test Study"
    ) async throws -> Study {
        let study = Study(
            groupId: groupId,
            title: LocalizedDictionary([.enUS: title]),
            locales: ["en-US"],
            icon: "heart",
            id: id
        )
        try await study.save(on: database)
        return study
    }
}
