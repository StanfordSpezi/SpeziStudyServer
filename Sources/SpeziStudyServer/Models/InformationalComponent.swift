//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation
import SpeziLocalization

/// Domain model for informational article content.
/// Note: This type is mapped from Components.Schemas.InformationalContent via typeOverrides in openapi-generator-config.yaml
struct InformationalContent: Hashable, Codable, Sendable {
    let title: String
    let lede: String?
    let content: String
}

/// Database model for informational component
final class InformationalComponent: Model, @unchecked Sendable {
    static let schema = "informational_components"

    @ID(custom: "component_id") var id: UUID?

    @Field(key: "data") var data: LocalizedDictionary<InformationalContent>

    init() {}

    init(componentId: UUID, data: LocalizedDictionary<InformationalContent>) {
        self.id = componentId
        self.data = data
    }
}
