//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLocalization


struct ParticipantProfileInput: Sendable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var gender: GenderIdentity?
    var dateOfBirth: Date?
    var region: String?
    var language: String?
    var phoneNumber: String?

    init(_ schema: Components.Schemas.ParticipantProfileInput) {
        self.firstName = schema.firstName
        self.lastName = schema.lastName
        self.email = schema.email
        self.gender = schema.gender.flatMap { GenderIdentity(rawValue: $0.rawValue) }
        self.dateOfBirth = schema.dateOfBirth.flatMap { Self.dateOnlyFormatter.date(from: $0) }
        self.region = schema.region
        self.language = schema.language
        self.phoneNumber = schema.phoneNumber
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}


extension Components.Schemas.ParticipantProfile {
    init(_ model: Participant) throws {
        self.init(
            id: try model.requireId().uuidString,
            firstName: model.firstName,
            lastName: model.lastName,
            email: model.email,
            gender: model.gender.flatMap { Components.Schemas.GenderIdentity(rawValue: $0.rawValue) },
            dateOfBirth: model.dateOfBirth.map { Self.dateOnlyFormatter.string(from: $0) },
            region: model.region,
            language: model.language,
            phoneNumber: model.phoneNumber
        )
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}


extension Components.Schemas.PublishedStudyListItem {
    init(_ model: PublishedStudy) throws {
        self.init(
            id: model.$study.id.uuidString,
            metadata: model.metadata
        )
    }
}
