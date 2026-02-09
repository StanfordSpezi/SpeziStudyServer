//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import HealthKit
import SpeziHealthKit
import SpeziHealthKitBulkExport
import SpeziStudyDefinition


// MARK: - Model to Schema

extension Components.Schemas.HealthDataComponentData {
    init(_ model: StudyDefinition.HealthDataCollectionComponent) {
        let historicalDataCollection: HistoricalDataCollectionPayload?
        switch model.historicalDataCollection {
        case .disabled:
            historicalDataCollection = .init(enabled: false)
        case .enabled(let startDate):
            historicalDataCollection = .init(
                enabled: true,
                startDate: .init(startDate)
            )
        }

        self.init(
            sampleTypes: model.sampleTypes.map { SampleTypeProxy($0) },
            historicalDataCollection: historicalDataCollection
        )
    }
}

extension Components.Schemas.ExportSessionStartDate {
    init(_ model: ExportSessionStartDate) {
        switch model {
        case .oldestSample:
            self = .oldestSample(.init(_type: .oldestSample))
        case .last(let components):
            self = .last(.init(_type: .last, components: components))
        case .absolute(let date):
            self = .absolute(.init(_type: .absolute, date: date))
        }
    }
}

// MARK: - Schema to Model

extension StudyDefinition.HealthDataCollectionComponent {
    init(id: UUID, _ schema: Components.Schemas.HealthDataComponentData) {
        let historicalDataCollection: HistoricalDataCollection
        if let historical = schema.historicalDataCollection,
           historical.enabled == true {
            if let startDate = historical.startDate {
                historicalDataCollection = .enabled(ExportSessionStartDate(startDate))
            } else {
                historicalDataCollection = .enabled(.oldestSample)
            }
        } else {
            historicalDataCollection = .disabled
        }
        
        self.init(
            id: id,
            sampleTypes: SampleTypesCollection(schema.sampleTypes),
            optionalSampleTypes: [],
            historicalDataCollection: historicalDataCollection
        )
    }
}

extension ExportSessionStartDate {
    init(_ schema: Components.Schemas.ExportSessionStartDate) {
        switch schema {
        case .oldestSample:
            self = .oldestSample
        case .last(let relative):
            self = .last(relative.components)
        case .absolute(let absolute):
            self = .absolute(absolute.date)
        }
    }
}
