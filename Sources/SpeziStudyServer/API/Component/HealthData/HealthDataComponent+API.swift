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


extension Components.Schemas.HealthDataComponentData {
    init(from domain: StudyDefinition.HealthDataCollectionComponent) {
        let sampleTypeStrings = domain.sampleTypes.map { $0.id }

        let historicalDataCollection: HistoricalDataCollectionPayload?
        switch domain.historicalDataCollection {
        case .disabled:
            historicalDataCollection = .init(enabled: false)
        case .enabled(let startDate):
            historicalDataCollection = .init(
                enabled: true,
                startDate: .init(from: startDate)
            )
        }

        self.init(
            sampleTypes: sampleTypeStrings,
            historicalDataCollection: historicalDataCollection
        )
    }
}

extension Components.Schemas.ExportSessionStartDate {
    init(from domain: ExportSessionStartDate) {
        switch domain {
        case .oldestSample:
            self = .oldestSample(.init(_type: .oldestSample))
        case .last(let components):
            self = .last(.init(
                _type: .last,
                components: .init(
                    year: components.year,
                    month: components.month,
                    day: components.day
                )
            ))
        case .absolute(let date):
            self = .absolute(.init(_type: .absolute, date: date))
        }
    }
}

// MARK: - API to Domain

extension StudyDefinition.HealthDataCollectionComponent {
    init(id: UUID, from api: Components.Schemas.HealthDataComponentData) {
        let sampleTypes = SampleTypesCollection(
            api.sampleTypes.compactMap { SampleTypeProxy(fromIdentifier: $0) }
        )

        let historicalDataCollection: HistoricalDataCollection
        if let apiHistorical = api.historicalDataCollection,
           apiHistorical.enabled == true {
            if let startDate = apiHistorical.startDate {
                historicalDataCollection = .enabled(ExportSessionStartDate(from: startDate))
            } else {
                historicalDataCollection = .enabled(.oldestSample)
            }
        } else {
            historicalDataCollection = .disabled
        }

        self.init(
            id: id,
            sampleTypes: sampleTypes,
            optionalSampleTypes: [],
            historicalDataCollection: historicalDataCollection
        )
    }
}

extension ExportSessionStartDate {
    init(from api: Components.Schemas.ExportSessionStartDate) {
        switch api {
        case .oldestSample:
            self = .oldestSample
        case .last(let relative):
            var components = DateComponents()
            if let year = relative.components.year {
                components.year = year
            }
            if let month = relative.components.month {
                components.month = month
            }
            if let day = relative.components.day {
                components.day = day
            }
            self = .last(components)
        case .absolute(let absolute):
            self = .absolute(absolute.date)
        }
    }
}

extension SampleTypeProxy {
    init?(fromIdentifier identifier: String) {
        // Try quantity types first (most common)
        let quantityIdentifier = HKQuantityTypeIdentifier(rawValue: identifier)
        if let quantityType = SampleType<HKQuantitySample>(quantityIdentifier) {
            self = .quantity(quantityType)
            return
        }
        // Try category types
        let categoryIdentifier = HKCategoryTypeIdentifier(rawValue: identifier)
        if let categoryType = SampleType<HKCategorySample>(categoryIdentifier) {
            self = .category(categoryType)
            return
        }
        // Try correlation types
        let correlationIdentifier = HKCorrelationTypeIdentifier(rawValue: identifier)
        if let correlationType = SampleType<HKCorrelation>(correlationIdentifier) {
            self = .correlation(correlationType)
            return
        }
        return nil
    }
}
