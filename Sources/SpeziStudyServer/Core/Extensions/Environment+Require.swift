//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Vapor


extension Environment {
    /// Returns the value of the environment variable with the given key, or throws if it is not set.
    static func require(_ key: String) throws -> String {
        guard let value = Environment.get(key) else {
            throw ConfigurationError(message: "Missing required environment variable: \(key)")
        }
        return value
    }
}


struct ConfigurationError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
}
