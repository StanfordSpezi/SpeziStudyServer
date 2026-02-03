////
//// This source file is part of the SpeziStudyServer open source project
////
//// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
////
//// SPDX-License-Identifier: MIT
////
//
//import Foundation
//
//extension Controller {
//    func getStudiesIdFiles(
//        _ input: Operations.GetStudiesIdFiles.Input
//    ) async throws -> Operations.GetStudiesIdFiles.Output {
//        let studyUUID = try input.path.id.toUUID()
//
//        let dtos = try await studyFileService.listFiles(studyId: studyUUID)
//        return .ok(.init(body: .json(dtos)))
//    }
//
//    func postStudiesIdFiles(
//        _ input: Operations.PostStudiesIdFiles.Input
//    ) async throws -> Operations.PostStudiesIdFiles.Output {
//        let studyUUID = try input.path.id.toUUID()
//
//        guard case .json(let fileDTO) = input.body else {
//            throw ServerError.defaults.jsonBodyRequired
//        }
//
//        let responseDTO = try await studyFileService.createFile(
//            studyId: studyUUID,
//            dto: fileDTO
//        )
//        return .created(.init(body: .json(responseDTO)))
//    }
//
//    func getStudiesIdFilesLocale(
//        _ input: Operations.GetStudiesIdFilesLocale.Input
//    ) async throws -> Operations.GetStudiesIdFilesLocale.Output {
//        let studyUUID = try input.path.id.toUUID()
//        let locale = input.path.locale
//
//        let dto = try await studyFileService.getFile(
//            studyId: studyUUID,
//            locale: locale
//        )
//        return .ok(.init(body: .json(dto)))
//    }
//
//    func putStudiesIdFilesLocale(
//        _ input: Operations.PutStudiesIdFilesLocale.Input
//    ) async throws -> Operations.PutStudiesIdFilesLocale.Output {
//        let studyUUID = try input.path.id.toUUID()
//        let locale = input.path.locale
//
//        guard case .json(let fileDTO) = input.body else {
//            throw ServerError.defaults.jsonBodyRequired
//        }
//
//        let responseDTO = try await studyFileService.updateFile(
//            studyId: studyUUID,
//            locale: locale,
//            dto: fileDTO
//        )
//        return .ok(.init(body: .json(responseDTO)))
//    }
//
//    func deleteStudiesIdFilesLocale(
//        _ input: Operations.DeleteStudiesIdFilesLocale.Input
//    ) async throws -> Operations.DeleteStudiesIdFilesLocale.Output {
//        let studyUUID = try input.path.id.toUUID()
//        let locale = input.path.locale
//
//        try await studyFileService.deleteFile(
//            studyId: studyUUID,
//            locale: locale
//        )
//        return .noContent(.init())
//    }
//}
