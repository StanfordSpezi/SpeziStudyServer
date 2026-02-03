////
//// This source file is part of the SpeziStudyServer open source project
////
//// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
////
//// SPDX-License-Identifier: MIT
////
//import Foundation
//
//enum FileMapper {
//    static func toModel(
//        _ dto: Components.Schemas.CreateFileRequest,
//        componentId: UUID? = nil,
//        studyId: UUID? = nil
//    ) throws -> StoredFile {
//        try validateLocale(dto.locale)
//        try validateFileType(dto._type)
//
//        return StoredFile(
//            componentId: componentId,
//            studyId: studyId,
//            name: dto.name,
//            locale: dto.locale,
//            content: dto.content,
//            type: dto._type.rawValue
//        )
//    }
//
//    static func toModel(
//        _ dto: Components.Schemas.UpdateFileRequest,
//        locale: String,
//        componentId: UUID? = nil,
//        studyId: UUID? = nil
//    ) throws -> StoredFile {
//        try validateLocale(dto.locale)
//        try validateFileType(dto._type)
//
//        guard dto.locale == locale else {
//            throw ServerError.validation(message: "Locale in body '\(dto.locale)' does not match path parameter '\(locale)'")
//        }
//
//        return StoredFile(
//            componentId: componentId,
//            studyId: studyId,
//            name: dto.name,
//            locale: dto.locale,
//            content: dto.content,
//            type: dto._type.rawValue
//        )
//    }
//
//    static func toDTO(_ file: StoredFile) throws -> Components.Schemas.FileResource {
//        guard let fileType = Components.Schemas.FileResource._TypePayload(rawValue: file.type) else {
//            throw ServerError.internalError(message: "Invalid file type: \(file.type)")
//        }
//
//        return Components.Schemas.FileResource(
//            name: file.name,
//            locale: file.locale,
//            content: file.content,
//            _type: fileType
//        )
//    }
//
//    static func toDTO(_ files: [StoredFile]) throws -> [Components.Schemas.FileResource] {
//        try files.map { try toDTO($0) }
//    }
//
//    private static func validateLocale(_ locale: String) throws {
//        let pattern = "^[a-z]{2}-[A-Z]{2}$"
//        guard locale.range(of: pattern, options: .regularExpression) != nil else {
//            throw ServerError.validation(message: "Invalid locale format: '\(locale)'. Expected format: language-REGION (e.g., en-US, de-DE)")
//        }
//    }
//
//    private static func validateFileType(_ type: Components.Schemas.CreateFileRequest._TypePayload) throws {
//        switch type {
//        case .md, .json:
//            return
//        }
//    }
//
//    private static func validateFileType(_ type: Components.Schemas.UpdateFileRequest._TypePayload) throws {
//        switch type {
//        case .md, .json:
//            return
//        }
//    }
//}
