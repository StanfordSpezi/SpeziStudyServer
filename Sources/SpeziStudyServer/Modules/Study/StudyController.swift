//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Controller {
    func postGroupsGroupIdStudies(
        _ input: Operations.PostGroupsGroupIdStudies.Input
    ) async throws -> Operations.PostGroupsGroupIdStudies.Output {
        guard case .json(let studyDTO) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let groupId = try input.path.groupId.requireId()
        let responseDTO = try await studyService.createStudy(groupId: groupId, studyDTO)
        return .created(.init(body: .json(responseDTO)))
    }

    func getGroupsGroupIdStudies(
        _ input: Operations.GetGroupsGroupIdStudies.Input
    ) async throws -> Operations.GetGroupsGroupIdStudies.Output {
        let groupId = try input.path.groupId.requireId()
        let studies = try await studyService.listStudies(groupId: groupId)
        return .ok(.init(body: .json(studies)))
    }

    func getStudiesStudyId(_ input: Operations.GetStudiesStudyId.Input) async throws -> Operations.GetStudiesStudyId.Output {
        let studyId = try input.path.studyId.requireId()
        let dto = try await studyService.getStudy(id: studyId)
        return .ok(.init(body: .json(dto)))
    }

    func putStudiesStudyId(_ input: Operations.PutStudiesStudyId.Input) async throws -> Operations.PutStudiesStudyId.Output {
        guard case .json(let studyDTO) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let studyId = try input.path.studyId.requireId()
        let responseDTO = try await studyService.updateStudy(id: studyId, dto: studyDTO)
        return .ok(.init(body: .json(responseDTO)))
    }

    func deleteStudiesStudyId(_ input: Operations.DeleteStudiesStudyId.Input) async throws -> Operations.DeleteStudiesStudyId.Output {
        let studyId = try input.path.studyId.requireId()
        try await studyService.deleteStudy(id: studyId)
        return .noContent(.init())
    }
}
