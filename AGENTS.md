<!--

This source file is part of the SpeziStudyServer open source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

# SpeziStudyServer

A Vapor-based server for managing clinical research studies, built as part of the Spezi ecosystem.

## Project Structure

```
Sources/SpeziStudyServer/
├── openapi.yaml                  # API specification
├── openapi-generator-config.yaml # Generator config
├── App/                          # Application bootstrap
│   ├── entrypoint.swift          # @main entry point
│   ├── configure.swift           # App configuration and DI registration
│   └── routes.swift              # Route registration
│
├── Modules/                      # Feature modules
│   ├── Controller.swift          # Base controller protocol
│   ├── Study/                    # Study management
│   │   ├── StudyController.swift
│   │   ├── StudyService.swift
│   │   ├── StudyRepository.swift
│   │   └── StudyMapper.swift
│   ├── Component/                # Component operations
│   │   ├── ComponentController.swift
│   │   ├── ComponentService.swift
│   │   ├── ComponentRepository.swift
│   │   ├── HealthData/           # Health data collection
│   │   ├── Informational/        # Informational content
│   │   └── Questionnaire/        # Questionnaires
│   └── ComponentSchedule/        # Schedule management
│
├── Models/                       # Fluent database models
│   ├── Study.swift
│   ├── Component.swift
│   ├── ComponentType.swift
│   ├── ComponentSchedule.swift
│   ├── InformationalComponent.swift
│   ├── QuestionnaireComponent.swift
│   └── HealthDataComponent.swift
│
├── Migrations/                   # Fluent database migrations
│
└── Core/                         # Shared infrastructure
    ├── DatabaseConfiguration.swift  # Injectable DB config
    ├── VaporModule.swift
    ├── Errors/
    │   ├── ServerError.swift
    │   ├── ServerError+Defaults.swift
    │   └── ProblemDetails+ServerError.swift
    ├── Extensions/
    │   ├── Encodable+Recode.swift
    │   ├── Model+RequireID.swift
    │   └── String+RequireID.swift
    └── Middleware/
        └── ErrorMiddleware.swift
```

## Architecture

### Module-Based Architecture

Each module (feature) contains its own:

1. **Controller** - HTTP request handling, input validation, response mapping
2. **Service** - Business logic, orchestration
3. **Repository** - Database access via Fluent ORM
4. **Mapper** - Conversion between API schemas and domain types

### Dependency Injection

Uses Spezi's dependency injection system:

```swift
final class StudyService: VaporModule, @unchecked Sendable {
    @Dependency(StudyRepository.self) var repository: StudyRepository
}
```

Dependencies are registered in `App/configure.swift`:

```swift
await app.spezi.configure {
    // Services
    StudyService()
    ComponentService()
    // Repositories
    StudyRepository(database: app.db)
    ComponentRepository(database: app.db)
}
```

### Database Configuration

Database configuration is injectable via `DatabaseConfiguration`:

```swift
// Production (PostgreSQL from environment)
try await configure(app, database: .production)

// Testing (in-memory SQLite)
try await configure(app, database: .testing)
```

### Component Types

Studies contain multiple component types, each with their own table:

- **InformationalComponent** - Static informational content
- **QuestionnaireComponent** - Survey/questionnaire definitions
- **HealthDataComponent** - Health data collection configuration

### OpenAPI Code Generation

API types are generated from `Sources/SpeziStudyServer/openapi.yaml` using swift-openapi-generator.

- Spec: `openapi.yaml` at target root
- Config: `openapi-generator-config.yaml` at target root
- Generated types: `Components.Schemas.*`, `Operations.*`
- Regenerate after schema changes: `swift build`

## StudyDefinition JSON Format

The server uses SpeziStudyDefinition types which encode with specific JSON patterns:

### Localized Strings

`LocalizedDictionary` encodes as locale-keyed objects:

```json
{
  "title": { "en-US": "My Study Title" },
  "explanationText": { "en-US": "Study description here" }
}
```

### Swift Enums with Associated Values

Enums use `_0` keys for associated values:

```json
{
  "participationCriterion": {
    "all": {
      "_0": [
        { "ageAtLeast": { "_0": 18 } },
        { "isFromRegion": { "_0": "US" } }
      ]
    }
  },
  "enrollmentConditions": { "none": {} }
}
```

### Health Data Sample Types

Sample types encode as `Type;Identifier` strings:

```json
{
  "sampleTypes": [
    "HKQuantityType;HKQuantityTypeIdentifierHeartRate",
    "HKQuantityType;HKQuantityTypeIdentifierStepCount",
    "HKCategoryType;HKCategoryTypeIdentifierSleepAnalysis"
  ]
}
```

### Schedule Definitions

```json
{
  "scheduleDefinition": {
    "once": {
      "_0": {
        "event": {
          "_0": { "activation": {} },
          "offsetInDays": 1,
          "time": { "hour": 9, "minute": 0, "second": 0 }
        }
      }
    }
  }
}
```

## Conventions

### Swift API Design Guidelines

Follow the official Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/

Key points:
- Clarity at the point of use is the most important goal
- Prefer method and property names that make use sites form grammatical English phrases
- Name functions and methods according to their side-effects (mutating vs non-mutating)
- Use terminology consistently throughout the codebase

### File Organization

- One controller/service/repository per file
- Each module folder contains all related files
- Shared code goes in `Core/`

### Naming

- Fluent models: `Study`, `Component`, `HealthDataComponent`
- Repositories: `StudyRepository`, `ComponentRepository` (class, not protocol)
- Services: `StudyService` conforming to `VaporModule`
- Controllers: Extensions on `Controller`

### Error Handling

Use `ServerError` for all errors:

```swift
throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
throw ServerError.validation(message: "Invalid input")
throw ServerError.internalError(message: "Unexpected error")
```

Use `requireID()` instead of force unwrapping:

```swift
// On Fluent models
let id = try model.requireID()

// On String path parameters
let uuid = try input.path.id.requireID()
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

## Testing

### Test Structure

```
Tests/SpeziStudyServerTests/
├── Integration/                    # HTTP endpoint tests
│   ├── StudyIntegrationTests.swift
│   ├── ComponentIntegrationTests.swift
│   ├── HealthDataComponentIntegrationTests.swift
│   ├── QuestionnaireComponentIntegrationTests.swift
│   └── InformationalComponentIntegrationTests.swift
└── Support/
    ├── TestApp.swift               # App lifecycle management
    ├── Request+JSON.swift          # JSON encoding helper
    └── Fixtures/
        ├── StudyFixtures.swift     # Test data factories
        └── ComponentFixtures.swift
```

### Test Patterns

- Uses Swift Testing framework (`@Suite`, `@Test`, `#expect`)
- In-memory SQLite database (configured via `DatabaseConfiguration.testing`)
- Fixtures create data directly via Fluent models (fast, focused tests)
- `TestApp.withApp()` manages app lifecycle and cleanup

### Running Tests

```bash
swift test                    # Run all tests
swift test --filter "Study"   # Run tests matching "Study"
```

## API Testing with Bruno

API requests are defined in `tools/bruno/`. Bruno is an open-source API client (alternative to Postman).

### Structure

```
tools/bruno/
├── environments/Local.bru    # Environment variables
├── Hello.bru                 # Health check + seeding script
├── Study/                    # Study CRUD requests
├── Components/               # Component requests by type
├── ComponentSchedules/       # Schedule requests
└── Auth/                     # Authentication requests
```

### Database Seeding

The `Hello` request (`tools/bruno/Hello.bru`) includes a post-response script that seeds the database:

```javascript
script:post-response {
  await bru.runRequest("Study/Post Study")
  await bru.runRequest("Components/Questionnaire - Create")
  await bru.runRequest("Components/Informational - Create")
  await bru.runRequest("Components/HealthData - Create")
}
```

Run the `Hello` request to create a study with sample components for testing.
