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


enum ParticipantFixtures {
    @discardableResult
    static func createParticipant(
        on database: any Database,
        identityProviderId: String = "test-participant",
        firstName: String? = "Jane",
        id: UUID? = nil
    ) async throws -> Participant {
        let participant = Participant(
            identityProviderId: identityProviderId,
            firstName: firstName,
            id: id
        )
        try await participant.save(on: database)
        return participant
    }
}
