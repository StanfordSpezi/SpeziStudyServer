//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ZIPFoundation

extension URL {
    func zipped() throws -> Data {
        let archive = try Archive(accessMode: .create)
        let fileManager = FileManager.default
        let bundleName = lastPathComponent

        guard let enumerator = fileManager.enumerator(at: self, includingPropertiesForKeys: [.isRegularFileKey]) else {
            throw ServerError.internalError(message: "Failed to enumerate bundle directory")
        }

        for case let fileUrl as URL in enumerator {
            let resourceValues = try fileUrl.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else {
                continue
            }

            let relativePath = fileUrl.path.replacingOccurrences(of: path + "/", with: "")
            let entryPath = "\(bundleName)/\(relativePath)"
            let fileData = try Data(contentsOf: fileUrl)

            try archive.addEntry(
                with: entryPath,
                type: .file,
                uncompressedSize: Int64(fileData.count),
                provider: { position, size in
                    fileData.subdata(in: Int(position)..<Int(position) + size)
                }
            )
        }

        guard let zipData = archive.data else {
            throw ServerError.internalError(message: "Failed to generate ZIP data")
        }

        try? fileManager.removeItem(at: self)

        return zipData
    }
}
