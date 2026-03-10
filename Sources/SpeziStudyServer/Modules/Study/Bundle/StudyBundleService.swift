//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziFoundation
import SpeziLocalization
import SpeziStudyDefinition
import ZIPFoundation


final class StudyBundleService: Module, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService
    @Dependency(StudyRepository.self) var studyRepository

    init() {}

    func buildBundle(studyId: UUID) async throws -> Data {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)
        let study = try await studyRepository.findWithComponentsAndSchedules(id: studyId)

        let (metadata, consentFiles) = try await buildMetadata(from: study)
        let (components, componentFiles) = try buildComponents(from: study.components)
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

    func buildMetadata(
        from study: Study
    ) async throws -> (StudyDefinition.Metadata, [StudyBundle.FileResourceInput]) {
        try await studyService.checkHasAccess(to: study.requireId(), role: .researcher)
        
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
            enrollmentConditions: study.enrollmentConditions,
            consentFileRef: consentRef
        )

        return (metadata, consentFiles)
    }

    private func buildConsentFiles(
        from consent: LocalizationsDictionary<ConsentContent>
    ) throws -> (StudyBundle.FileReference?, [StudyBundle.FileResourceInput]) {
        guard !consent.isEmpty else {
            return (nil, [])
        }

        // TODO: Update versioning
        let version = Version(1, 0, 0)
        
        let ref = StudyBundle.FileReference(category: .consent, filename: "Consent", fileExtension: "md")
        let files = try consent.map { locale, definition in
            let markdown = "---\ntitle: \(definition.title)\nversion: \(version)\n---\n\(definition.content)"
            return try StudyBundle.FileResourceInput(fileRef: ref, localization: locale, contents: markdown)
        }
        return (ref, files)
    }

    // MARK: - Components

    private func buildComponents(
        from components: [Component]
    ) throws -> ([StudyDefinition.Component], [StudyBundle.FileResourceInput]) {
        var definitions: [StudyDefinition.Component] = []
        var files: [StudyBundle.FileResourceInput] = []

        for component in components {
            let componentId = try component.requireId()

            switch component.data {
            case .informational(let content):
                let (definition, componentFiles) = try buildInformational(
                    id: componentId,
                    name: component.name,
                    content: content
                )
                definitions.append(definition)
                files += componentFiles

            case .questionnaire(let content):
                let (definition, componentFiles) = try buildQuestionnaire(
                    id: componentId,
                    name: component.name,
                    content: content
                )
                definitions.append(definition)
                files += componentFiles

            case .healthDataCollection(let data):
                definitions.append(.healthDataCollection(data))
            }
        }

        return (definitions, files)
    }

    private func buildInformational(
        id: UUID,
        name: String,
        content: LocalizationsDictionary<InformationalContent>
    ) throws -> (StudyDefinition.Component, [StudyBundle.FileResourceInput]) {
        let fileRef = StudyBundle.FileReference(category: .informationalArticle, filename: name, fileExtension: "md")
        let definition = StudyDefinition.Component.informational(.init(id: id, fileRef: fileRef))

        let files = try content.map { locale, item in
            var markdown = "---\nid: \(id.uuidString)\ntitle: \(item.title)\n"
            if let lede = item.lede {
                markdown += "lede: \(lede)\n"
            }
            markdown += "---\n\(item.content)"
            return try StudyBundle.FileResourceInput(fileRef: fileRef, localization: locale, contents: markdown)
        }

        return (definition, files)
    }

    private func buildQuestionnaire(
        id: UUID,
        name: String,
        content: LocalizationsDictionary<QuestionnaireContent>
    ) throws -> (StudyDefinition.Component, [StudyBundle.FileResourceInput]) {
        let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: name, fileExtension: "json")
        let definition = StudyDefinition.Component.questionnaire(.init(id: id, fileRef: fileRef))

        let files = content.map { locale, item in
            StudyBundle.FileResourceInput(fileRef: fileRef, localization: locale, contents: Data(item.questionnaire.utf8))
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
