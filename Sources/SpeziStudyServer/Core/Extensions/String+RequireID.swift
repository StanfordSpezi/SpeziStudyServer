//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension String {
    func requireId() throws -> UUID {
        guard let uuid = Foundation.UUID(uuidString: self) else {
            throw ServerError.invalidUUID(self)
        }
        return uuid
    }
}
