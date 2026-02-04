//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

/// Domain model for health data component content.
/// Note: This type is mapped from Components.Schemas.HealthDataComponent via typeOverrides in openapi-generator-config.yaml
struct HealthDataContent: Hashable, Codable, Sendable {
    let sampleTypes: [String]
    let historicalDataCollection: HistoricalDataCollection?
}

/// Configuration for collecting historical health data.
struct HistoricalDataCollection: Hashable, Codable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case enabled
        case startDate
    }

    let enabled: Bool
    let startDate: ExportSessionStartDate?

    init(enabled: Bool = false, startDate: ExportSessionStartDate? = nil) {
        self.enabled = enabled
        self.startDate = startDate
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        self.startDate = try container.decodeIfPresent(ExportSessionStartDate.self, forKey: .startDate)
    }
}

/// Defines how the start date of an export session is determined.
enum ExportSessionStartDate: Hashable, Codable, Sendable {
    case oldestSample
    case last(components: DateComponents)
    case absolute(date: Date)

    private enum CodingKeys: String, CodingKey {
        case type
        case components
        case date
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "oldestSample":
            self = .oldestSample
        case "last":
            let components = try container.decode(DateComponents.self, forKey: .components)
            self = .last(components: components)
        case "absolute":
            let date = try container.decode(Date.self, forKey: .date)
            self = .absolute(date: date)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown ExportSessionStartDate type: \(type)"
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .oldestSample:
            try container.encode("oldestSample", forKey: .type)
        case .last(let components):
            try container.encode("last", forKey: .type)
            try container.encode(components, forKey: .components)
        case .absolute(let date):
            try container.encode("absolute", forKey: .type)
            try container.encode(date, forKey: .date)
        }
    }
}

/// Database model for health data component.
final class HealthDataComponent: Model, @unchecked Sendable {
    static let schema = "health_data_components"

    @ID(custom: "component_id") var id: UUID?

    @Field(key: "data") var data: HealthDataContent

    init() {}

    init(componentId: UUID, data: HealthDataContent) {
        self.id = componentId
        self.data = data
    }
}
