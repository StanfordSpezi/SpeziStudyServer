# SpeziStudyServer

A Vapor-based server for managing clinical research studies, built as part of the Spezi ecosystem.

## Project Structure

```
Sources/SpeziStudyServer/
├── API/                          # Feature modules (Controller, Service, Repository)
│   ├── Controller.swift          # Main controller with all route handlers
│   ├── Study/                    # Study management
│   ├── Component/                # Study components
│   │   ├── Informational/        # Informational component type
│   │   ├── Questionnaire/        # Questionnaire component type
│   │   └── HealthData/           # Health data collection component type
│   └── ComponentSchedule/        # Scheduling for components
├── Migrations/                   # Fluent database migrations
├── Models/                       # Fluent database models
├── Shared/                       # Shared utilities, extensions, mappers, errors
└── configure.swift               # App configuration and dependency registration
```

## Architecture

### Layered Architecture

Each feature follows a three-layer pattern:

1. **Controller** - HTTP request handling, input validation, response mapping
2. **Service** - Business logic, orchestration between repositories
3. **Repository** - Database access via Fluent ORM

### Dependency Injection

Uses SpeziVapor's dependency injection system:

```swift
final class MyService: VaporModule, @unchecked Sendable {
    @Dependency(OtherService.self) var otherService: OtherService
}
```

Dependencies are registered in `configure.swift`:

```swift
app.registerModule(DatabaseMyRepository(database: app.db), as: MyRepository.self)
app.registerModule(MyService())
```

### Component Types

Studies contain multiple component types, each with their own table:

- **InformationalComponent** - Static informational content
- **QuestionnaireComponent** - Survey/questionnaire definitions
- **HealthDataComponent** - Health data collection configuration

The `ComponentService` aggregates operations across all component types.

### OpenAPI Code Generation

API types are generated from `openapi.yaml` using swift-openapi-generator.

- Generated types: `Components.Schemas.*`, `Operations.*`
- Configuration: `openapi-generator-config.yaml`
- Regenerate after schema changes: `swift build`

## Conventions

### File Organization

- Protocol and implementation in the same file
- Protocol at the bottom, implementation at the top
- One model/service/repository per file

### Naming

- Database models: `Study`, `Component`, `ComponentSchedule`
- Repositories: `DatabaseXxxRepository` implementing `XxxRepository` protocol
- Services: `XxxService` conforming to `VaporModule`
- Controllers: Extensions on `Controller`

### Error Handling

Use `ServerError` for domain errors:

```swift
throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
throw ServerError.internalError(message: "Description")
```

### Fluent Queries

When using Fluent's query builder with multiple filters, add swiftlint disable comment:

```swift
// swiftlint:disable:next first_where
try await Model.query(on: database)
    .filter(\.$id == id)
    .filter(\.$study.$id == studyId)
    .first()
```

## Dependencies

- **Vapor** - Web framework
- **Fluent** - ORM
- **SpeziVapor** - Dependency injection and utilities
- **SpeziStudyDefinition** - Study definition types
- **SpeziLocalization** - Localized content support

## Commands

```bash
# Build
swift build

# Run server
swift run

# Run tests
swift test

# Lint
swiftlint
```
