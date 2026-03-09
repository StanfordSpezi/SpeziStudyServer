//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziLocalization
import SpeziStudyDefinition
import ZIPFoundation


final class StudyBundleService: Module, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService
    @Dependency(StudyRepository.self) var studyRepository
    @Dependency(InformationalComponentRepository.self) var informationalRepository
    @Dependency(QuestionnaireComponentRepository.self) var questionnaireRepository
    @Dependency(HealthDataComponentRepository.self) var healthDataRepository

    init() {}

    func buildBundle(studyId: UUID) async throws -> Data {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)
        let study = try await studyRepository.findWithComponentsAndSchedules(id: studyId)

        let (metadata, consentFiles) = try buildMetadata(from: study)
        let (components, componentFiles) = try await buildComponents(from: study.components)
        let schedules = study.components.flatMap { $0.schedules.map(\.scheduleData) }

        let definition = StudyDefinition(
            studyRevision: 1,
            metadata: metadata,
            components: components,
            componentSchedules: schedules
        )

        return try writeBundleZip(studyId: studyId, definition: definition, files: consentFiles + componentFiles)
    }

    // MARK: - Metadata

    private func buildMetadata(
        from study: Study
    ) throws -> (StudyDefinition.Metadata, [StudyBundle.FileResourceInput]) {
        var titles = LocalizationsDictionary<String>()
        var shortTitles = LocalizationsDictionary<String>()
        var explanationTexts = LocalizationsDictionary<String>()
        var shortExplanationTexts = LocalizationsDictionary<String>()

        for (locale, content) in study.details {
            titles[locale] = content.title
            shortTitles[locale] = content.shortTitle
            explanationTexts[locale] = content.explanationText
            shortExplanationTexts[locale] = content.shortExplanationText
        }

        let (consentRef, consentFiles) = try buildConsentFiles(from: study.consent)

        let metadata = StudyDefinition.Metadata(
            id: try study.requireId(),
            title: titles,
            shortTitle: shortTitles,
            icon: .none,
            explanationText: explanationTexts,
            shortExplanationText: shortExplanationTexts,
            participationCriterion: study.participationCriterion,
            enrollmentConditions: .none,
            consentFileRef: consentRef
        )

        return (metadata, consentFiles)
    }

    private func buildConsentFiles(
        from consent: LocalizationsDictionary<String>
    ) throws -> (StudyBundle.FileReference?, [StudyBundle.FileResourceInput]) {
        guard !consent.isEmpty else {
            return (nil, [])
        }

        let ref = StudyBundle.FileReference(category: .consent, filename: "Consent", fileExtension: "md")
        let files = try consent.map { locale, text in
            try StudyBundle.FileResourceInput(fileRef: ref, localization: locale, contents: text)
        }
        return (ref, files)
    }

    // MARK: - Components

    private func buildComponents(
        from components: [Component]
    ) async throws -> ([StudyDefinition.Component], [StudyBundle.FileResourceInput]) {
        var definitions: [StudyDefinition.Component] = []
        var files: [StudyBundle.FileResourceInput] = []

        for component in components {
            let componentId = try component.requireId()

            switch component.type {
            case .informational:
                let (definition, componentFiles) = try await buildInformational(id: componentId, name: component.name)
                definitions.append(definition)
                files += componentFiles

            case .questionnaire:
                let (definition, componentFiles) = try await buildQuestionnaire(id: componentId, name: component.name)
                definitions.append(definition)
                files += componentFiles

            case .healthDataCollection:
                if let healthData = try await healthDataRepository.find(id: componentId) {
                    definitions.append(.healthDataCollection(healthData.data))
                }
            }
        }

        return (definitions, files)
    }

    private func buildInformational(
        id: UUID,
        name: String
    ) async throws -> (StudyDefinition.Component, [StudyBundle.FileResourceInput]) {
        let fileRef = StudyBundle.FileReference(category: .informationalArticle, filename: name, fileExtension: "md")
        let definition = StudyDefinition.Component.informational(.init(id: id, fileRef: fileRef))

        guard let informational = try await informationalRepository.find(id: id) else {
            return (definition, [])
        }

        let files = try informational.data.map { locale, content in
            var markdown = "---\nid: \(id.uuidString)\ntitle: \(content.title)\n"
            if let lede = content.lede {
                markdown += "lede: \(lede)\n"
            }
            markdown += "---\n\(content.content)"
            return try StudyBundle.FileResourceInput(fileRef: fileRef, localization: locale, contents: markdown)
        }

        return (definition, files)
    }

    private func buildQuestionnaire(
        id: UUID,
        name: String
    ) async throws -> (StudyDefinition.Component, [StudyBundle.FileResourceInput]) {
        let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: name, fileExtension: "json")
        let definition = StudyDefinition.Component.questionnaire(.init(id: id, fileRef: fileRef))

        guard let questionnaire = try await questionnaireRepository.find(id: id) else {
            return (definition, [])
        }

        let files = questionnaire.data.map { locale, content in
            StudyBundle.FileResourceInput(fileRef: fileRef, localization: locale, contents: Data(content.questionnaire.utf8))
        }

        return (definition, files)
    }

    // MARK: - Bundle Writing

    private func writeBundleZip(
        studyId: UUID,
        definition: StudyDefinition,
        files: [StudyBundle.FileResourceInput]
    ) throws -> Data {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let bundleURL = tempDir.appendingPathComponent("\(studyId).spezistudybundle", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        do {
            _ = try StudyBundle.writeToDisk(at: bundleURL, definition: definition, files: files)
        } catch {
            throw ServerError.internalServerError("Failed to build study bundle: \(error)")
        }

        return try zipDirectory(at: bundleURL)
    }

    private func zipDirectory(at directoryURL: URL) throws -> Data {
        let archive = try Archive(accessMode: .create)

        let resolvedDirectory = directoryURL.resolvingSymlinksInPath()
        let baseName = resolvedDirectory.lastPathComponent
        let basePath = resolvedDirectory.path

        guard let enumerator = FileManager.default.enumerator(
            at: resolvedDirectory,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            throw ServerError.internalServerError("Failed to enumerate bundle directory")
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            let resolvedFile = fileURL.resolvingSymlinksInPath()
            let relativePath = resolvedFile.path.replacingOccurrences(of: basePath + "/", with: "")
            let entryPath = "\(baseName)/\(relativePath)"

            if resourceValues.isDirectory == true {
                try archive.addEntry(
                    with: entryPath + "/",
                    type: .directory,
                    uncompressedSize: Int64(0),
                    provider: { (_: Int64, _: Int) in Data() }
                )
            } else {
                let fileData = try Data(contentsOf: fileURL)
                try archive.addEntry(
                    with: entryPath,
                    type: .file,
                    uncompressedSize: Int64(fileData.count),
                    compressionMethod: .deflate,
                    provider: { (position: Int64, size: Int) in
                        fileData[Int(position)..<(Int(position) + size)]
                    }
                )
            }
        }

        guard let data = archive.data else {
            throw ServerError.internalServerError("Failed to create ZIP archive")
        }

        return data
    }
}
