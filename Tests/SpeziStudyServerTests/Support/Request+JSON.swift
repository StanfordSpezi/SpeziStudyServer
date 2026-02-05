//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Vapor
import VaporTesting

/// Helper for encoding arbitrary JSON in test requests.
extension TestingHTTPRequest {
    /// Encodes a dictionary as JSON request body.
    mutating func encodeJSONBody(_ dictionary: [String: Any]) throws {
        self.headers.contentType = .json
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        self.body = .init(data: data)
    }
}
