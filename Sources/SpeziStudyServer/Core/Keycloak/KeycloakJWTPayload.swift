//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import JWTKit


struct KeycloakJWTPayload: JWTPayload {
    var exp: ExpirationClaim
    var roles: [String]?
    var groups: [String]?

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
    }
}
