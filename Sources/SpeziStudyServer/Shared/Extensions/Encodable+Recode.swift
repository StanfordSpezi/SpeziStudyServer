//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

extension Encodable {
    /// Converts this value to another Codable type by encoding to JSON and decoding back.
    /// The return type is inferred from context, so no explicit type parameter is needed.
    ///
    /// Example:
    /// ```swift
    /// let dto: SomeDTO = try domainModel.recode()
    /// let model: DomainModel = try dto.recode()
    /// ```
    func recode<T: Decodable>(
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        do {
            let data = try encoder.encode(self)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ServerError.validation(message: error.localizedDescription)
        }
    }
}
