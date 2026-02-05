//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation
import SpeziHealthKit
import SpeziLocalization
import SpeziStudyDefinition
@testable import SpeziStudyServer

/// Test fixtures for Component entities.
enum ComponentFixtures {
    /// Creates and persists a health data component.
    @discardableResult
    static func createHealthDataComponent(
        on database: any Database,
        studyId: UUID,
        name: String = "Test Health Data"
    ) async throws -> (Component, HealthDataComponent) {
        let component = Component(
            studyId: studyId,
            type: .healthDataCollection,
            name: name
        )
        try await component.save(on: database)

        let componentId = try component.requireID()
        let healthData = HealthDataComponent(
            componentId: componentId,
            data: .init(
                id: componentId,
                sampleTypes: SampleTypesCollection([
                    SampleTypeProxy.quantity(.heartRate),
                    SampleTypeProxy.quantity(.stepCount)
                ]),
                optionalSampleTypes: SampleTypesCollection(),
                historicalDataCollection: .disabled
            )
        )
        try await healthData.save(on: database)

        return (component, healthData)
    }

    /// Creates and persists a questionnaire component.
    @discardableResult
    static func createQuestionnaireComponent(
        on database: any Database,
        studyId: UUID,
        name: String = "Test Questionnaire"
    ) async throws -> (Component, QuestionnaireComponent) {
        let component = Component(
            studyId: studyId,
            type: .questionnaire,
            name: name
        )
        try await component.save(on: database)

        let componentId = try component.requireID()
        let questionnaire = QuestionnaireComponent(
            componentId: componentId,
            data: LocalizedDictionary([.enUS: QuestionnaireContent(questionnaire: "{}")])
        )
        try await questionnaire.save(on: database)

        return (component, questionnaire)
    }

    /// Creates and persists an informational component.
    @discardableResult
    static func createInformationalComponent(
        on database: any Database,
        studyId: UUID,
        name: String = "Test Informational"
    ) async throws -> (Component, InformationalComponent) {
        let component = Component(
            studyId: studyId,
            type: .informational,
            name: name
        )
        try await component.save(on: database)

        let componentId = try component.requireID()
        let informational = InformationalComponent(
            componentId: componentId,
            data: LocalizedDictionary([.enUS: InformationalContent(title: "Test", lede: nil, content: "Content")])
        )
        try await informational.save(on: database)

        return (component, informational)
    }
}
