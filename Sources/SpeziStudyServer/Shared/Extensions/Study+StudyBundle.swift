//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziStudyDefinition

extension Study {
    func createBundle() throws -> URL {
        do {
            let bundleUrl = temporaryBundleUrl(for: self.id!)
            let bundle = try StudyBundle.writeToDisk(at: bundleUrl, definition: definition, files: assembleFiles())
            return bundle.bundleUrl
        } catch {
            throw ServerError.internalError(message: "Unexpected directory in file input")
        }
    }

    private func temporaryBundleUrl(for bundleId: UUID) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("\(bundleId.uuidString).spezistudybundle", isDirectory: true)
    }
}
