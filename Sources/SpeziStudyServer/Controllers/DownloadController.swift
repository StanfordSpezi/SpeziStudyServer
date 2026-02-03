////
//// This source file is part of the SpeziStudyServer open source project
////
//// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
////
//// SPDX-License-Identifier: MIT
////
//import Foundation
//import SpeziStudyDefinition
//
//extension Controller {
//    func getDownloadId(_ input: Operations.GetDownloadId.Input) async throws -> Operations.GetDownloadId.Output {
//        let uuid = try input.path.id.toUUID()
//        let zipData = try await downloadService.buildZipData(for: uuid)
//        return .ok(.init(
//            headers: .init(contentDisposition: "attachment; filename=\"\(uuid.uuidString).spezistudybundle.zip\""),
//            body: .applicationZip(.init(zipData))
//        ))
//    }
//}
