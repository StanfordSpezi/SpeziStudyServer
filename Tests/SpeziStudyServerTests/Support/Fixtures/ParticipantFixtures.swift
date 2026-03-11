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
        id: UUID? = nil
    ) async throws -> Participant {
        let participant = Participant(
            identityProviderId: identityProviderId,
            firstName: "Jane",
            lastName: "Doe",
            email: "jane@example.com",
            gender: .female,
            dateOfBirth: DateComponents(calendar: .current, year: 1990, month: 1, day: 1).date!, // swiftlint:disable:this force_unwrapping
            region: "US",
            language: "en",
            phoneNumber: "+1234567890",
            id: id
        )
        try await participant.save(on: database)
        return participant
    }
}
