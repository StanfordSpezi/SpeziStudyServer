//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation
//import SpeziHealthKitBulkExport
import SpeziStudyDefinition

/// Database model for health data component.
final class HealthDataComponent: Model, @unchecked Sendable {
    static let schema = "health_data_components"

    @ID(custom: "component_id") var id: UUID?

    @Field(key: "data") var data: StudyDefinition.HealthDataCollectionComponent

    init() {}

    init(componentId: UUID, data: StudyDefinition.HealthDataCollectionComponent) {
         self.id = componentId
         self.data = data
     }
}
