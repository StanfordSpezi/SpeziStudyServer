//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
@testable import SpeziStudyServer


enum ResearchGroupFixtures {
    @discardableResult
    static func createResearchGroup(
        on database: any Database,
        id: UUID = UUID(),
        name: String = "Test Research Group",
        icon: String = "heart.fill"
    ) async throws -> ResearchGroup {
        let group = ResearchGroup(name: name, icon: icon, id: id)
        try await group.save(on: database)
        return group
    }
}
