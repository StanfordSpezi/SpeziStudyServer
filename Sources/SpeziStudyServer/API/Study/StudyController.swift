//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

extension Controller {
    func postStudies(_ input: Operations.PostStudies.Input) async throws -> Operations.PostStudies.Output {
        guard case .json(let studyDTO) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let responseDTO = try await studyService.createStudy(studyDTO)
        return .created(.init(body: .json(responseDTO)))
    }

    func getStudies(_ input: Operations.GetStudies.Input) async throws -> Operations.GetStudies.Output {
        let studies = try await studyService.listStudies()
        return .ok(.init(body: .json(studies)))
    }

    func getStudiesId(_ input: Operations.GetStudiesId.Input) async throws -> Operations.GetStudiesId.Output {
        let uuid = try input.path.id.toUUID()
        let dto = try await studyService.getStudy(id: uuid)
        return .ok(.init(body: .json(dto)))
    }

    func putStudiesId(_ input: Operations.PutStudiesId.Input) async throws -> Operations.PutStudiesId.Output {
        guard case .json(let studyDTO) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let uuid = try input.path.id.toUUID()
        let responseDTO = try await studyService.updateStudy(id: uuid, dto: studyDTO)
        return .ok(.init(body: .json(responseDTO)))
    }

    func deleteStudiesId(_ input: Operations.DeleteStudiesId.Input) async throws -> Operations.DeleteStudiesId.Output {
        let uuid = try input.path.id.toUUID()
        try await studyService.deleteStudy(id: uuid)
        return .noContent(.init())
    }
}
