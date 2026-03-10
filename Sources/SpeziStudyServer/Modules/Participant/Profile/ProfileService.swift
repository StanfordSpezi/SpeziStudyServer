//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


final class ProfileService: Module, @unchecked Sendable {
    @Dependency(ProfileRepository.self) var repository: ProfileRepository

    init() {}

    func createProfile(input: ParticipantProfileInput) async throws -> Participant {
        let context = try AuthContext.checkIsParticipant()

        let existing = try await repository.findByIdentityProviderId(context.subject)
        if existing != nil {
            throw ServerError.conflict("Participant profile already exists")
        }

        let participant = Participant(
            identityProviderId: context.subject,
            firstName: input.firstName,
            lastName: input.lastName,
            email: input.email,
            gender: input.gender,
            dateOfBirth: input.dateOfBirth,
            region: input.region,
            language: input.language,
            phoneNumber: input.phoneNumber
        )

        return try await repository.create(participant)
    }

    func getProfile() async throws -> Participant {
        let context = try AuthContext.checkIsParticipant()

        guard let participant = try await repository.findByIdentityProviderId(context.subject) else {
            throw ServerError.notFound("Participant profile not found")
        }

        return participant
    }

    func updateProfile(input: ParticipantProfileInput) async throws -> Participant {
        let context = try AuthContext.checkIsParticipant()

        guard let participant = try await repository.findByIdentityProviderId(context.subject) else {
            throw ServerError.notFound("Participant profile not found")
        }

        participant.firstName = input.firstName
        participant.lastName = input.lastName
        participant.email = input.email
        participant.gender = input.gender
        participant.dateOfBirth = input.dateOfBirth
        participant.region = input.region
        participant.language = input.language
        participant.phoneNumber = input.phoneNumber

        try await repository.update(participant)
        return participant
    }

    func browseStudies(code: String?) async throws -> [PublishedStudy] {
        try AuthContext.checkIsParticipant()

        if let code {
            if let study = try await repository.findPublishedStudyByInvitationCode(code) {
                return [study]
            }
            return []
        }

        return try await repository.listPublicPublishedStudies()
    }
}
