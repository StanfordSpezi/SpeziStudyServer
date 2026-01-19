//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

struct DownloadService: Sendable {
    let repository: any StudyRepository

    func buildZipData(for id: UUID) async throws -> Data {
        let study = try await repository.findWithComponentsAndFiles(id: id)

        let bundleUrl = try study.createBundle()

        return try bundleUrl.zipped()
    }
}
