//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation


extension Model where IDValue == UUID {
    func requireId() throws -> UUID {
        guard let id = self.id else {
            throw ServerError.internalError(message: "\(Self.self) missing ID")
        }
        return id
    }
}
