//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import SpeziStudyDefinition
@testable import SpeziStudyServer
import VaporTesting


/// Shared test utilities for SpeziStudyServer tests
enum TestUtilities {
    /// Runs a test with a configured test application
    /// Migrations run once, data is cleaned between tests, app is properly shut down per test
    static func withApp(_ test: @escaping @Sendable (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await Study.query(on: app.db).delete()
            try await app.asyncShutdown()
        } catch {
            try await Study.query(on: app.db).delete()
            try await app.asyncShutdown()
            throw error
        }
    }

    /// Creates test metadata with given ID and title
    static func createTestMetadata(title: String, id: UUID) -> StudyDefinition.Metadata {
        StudyDefinition.Metadata(
            id: id,
            title: title,
            shortTitle: String(title.prefix(3)),
            icon: nil,
            explanationText: "Test explanation",
            shortExplanationText: "Test",
            participationCriterion: true,
            enrollmentConditions: .none
        )
    }

    /// Creates a test questionnaire component with given ID
    static func createTestQuestionnaireComponent(
        filename: String,
        id: UUID = UUID()
    ) -> StudyDefinition.Component {
        let fileRef = StudyBundle.FileReference(
            category: .questionnaire,
            filename: filename,
            fileExtension: "json"
        )
        let questionnaire = StudyDefinition.QuestionnaireComponent(
            id: id,
            fileRef: fileRef
        )
        return .questionnaire(questionnaire)
    }

    /// Creates a test file with a component owner
    static func createTestFile(
        componentId: UUID,
        name: String = "test-file",
        locale: String = "en-US",
        content: String = "# Test Content",
        type: String = "md"
    ) -> StoredFile {
        StoredFile(
            componentId: componentId,
            name: name,
            locale: locale,
            content: content,
            type: type
        )
    }

    /// Creates a test file with a study owner
    static func createTestStudyFile(
        studyId: UUID,
        name: String = "test-file",
        locale: String = "en-US",
        content: String = "# Test Content",
        type: String = "md"
    ) -> StoredFile {
        StoredFile(
            studyId: studyId,
            name: name,
            locale: locale,
            content: content,
            type: type
        )
    }

    /// Helper to encode request body from Swift type
    static func encodeRequestBody<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }
}
