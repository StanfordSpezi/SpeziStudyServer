<!--

This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

# Spezi Study Server

[![Build and Test](https://github.com/StanfordSpezi/SpeziStudyServer/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziStudyServer/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziStudyServer/branch/main/graph/badge.svg?token=X7BQYSUKOH)](https://codecov.io/gh/StanfordSpezi/SpeziStudyServer)
[![DOI](https://zenodo.org/badge/573230182.svg)](https://zenodo.org/badge/latestdoi/573230182)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziStudyServer%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziStudyServer)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziStudyServer%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziStudyServer)

A Vapor-based server for managing clinical research studies, built as part of the Spezi ecosystem.


## Overview

Spezi Study Server provides a REST API for managing clinical research studies, including:

- **Studies** - Create and manage study definitions with metadata
- **Components** - Configure study components (questionnaires, health data collection, informational content)
- **Schedules** - Define when components should be presented to participants

The server integrates with [SpeziStudy](https://github.com/StanfordSpezi/SpeziStudy) for study configuration types and [SpeziVapor](https://github.com/StanfordSpezi/SpeziVapor) for dependency injection.


## Requirements

- Swift 6.0+
- PostgreSQL (production) or SQLite (development/testing)
- Docker (optional, for local PostgreSQL)


## Getting Started

### Run with Docker

```bash
# Start PostgreSQL
docker-compose up -d db

# Run the server
swift run
```

### Run Tests

```bash
swift test
```

Tests use an in-memory SQLite database and require no external dependencies.


## API Documentation

The API is defined using OpenAPI. See [`Sources/SpeziStudyServer/openapi.yaml`](Sources/SpeziStudyServer/openapi.yaml) for the full specification.

### Example: Create a Study

```bash
curl -X POST http://localhost:8080/studies \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "title": {"en-US": "My Study"},
      "explanationText": {"en-US": "Study description"},
      "shortExplanationText": {"en-US": "Short description"},
      "participationCriterion": {"all": {"_0": []}},
      "enrollmentConditions": {"none": {}}
    }
  }'
```

### API Testing with Bruno

API requests for manual testing are available in `tools/bruno/`. [Bruno](https://www.usebruno.com) is an open-source API client.


## Architecture

The server follows a module-based architecture:

```
Sources/SpeziStudyServer/
├── App/              # Application bootstrap and configuration
├── Modules/          # Feature modules (Study, Component, etc.)
├── Models/           # Fluent database models
├── Migrations/       # Database migrations
└── Core/             # Shared infrastructure
```

Each module contains its own Controller, Service, Repository, and Mapper.

For detailed architecture documentation, see [AGENTS.md](AGENTS.md).


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziStudyServer/tree/main/LICENSES) for more information.


## Contributors

This project is developed as part of the Stanford Mussallem Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordSpezi/SpeziStudyServer/tree/main/CONTRIBUTORS.md) for a full list of all Spezi Study Server contributors.

![Stanford Mussallem Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Mussallem Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
