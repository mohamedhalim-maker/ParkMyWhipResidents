# Park My Whip Resident App - Documentation

> **Purpose**: This documentation folder provides comprehensive context for AI agents to understand and work with the codebase effectively.

## Quick Start for AI Agents

When working on this project, read the relevant documentation files based on the task:

| Task Type | Read These Files |
|-----------|------------------|
| **New Feature** | `FEATURE_GUIDE.md` → `STATE_MANAGEMENT.md` → `CONVENTIONS.md` |
| **UI Changes** | `DESIGN_SYSTEM.md` → `CORE_LAYER.md` |
| **Data/API Work** | `DATA_LAYER.md` → `SUPABASE.md` |
| **Bug Fixes** | `ARCHITECTURE.md` → relevant domain file |
| **Refactoring** | `ARCHITECTURE.md` → `CONVENTIONS.md` |

## Documentation Index

| File | Description |
|------|-------------|
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | High-level architecture, patterns, and project structure |
| [`FEATURE_GUIDE.md`](./FEATURE_GUIDE.md) | Step-by-step guide to create new features |
| [`CORE_LAYER.md`](./CORE_LAYER.md) | Core layer components: helpers, widgets, routes, DI |
| [`DATA_LAYER.md`](./DATA_LAYER.md) | Models, services, and networking |
| [`STATE_MANAGEMENT.md`](./STATE_MANAGEMENT.md) | Cubit/BLoC patterns and state design |
| [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) | Colors, typography, and reusable widgets |
| [`SUPABASE.md`](./SUPABASE.md) | Database schema, multi-app architecture, auth |
| [`CONVENTIONS.md`](./CONVENTIONS.md) | Coding standards and naming conventions |

## Project Overview

**App Name**: Park My Whip - Resident  
**App ID**: `park_my_whip_resident`  
**Platform**: Cross-platform (iOS, Android, Web)  
**Backend**: Supabase (Auth, Database, Storage)  
**State Management**: BLoC (Cubit)  
**DI**: GetIt  

## Current Features

- ✅ Authentication (Login, Signup, Forgot Password)
- ✅ Multi-app architecture (users can belong to multiple apps)
- ✅ Dashboard (basic layout)
- 🚧 Parking Management (planned)
- 🚧 Vehicle Management (planned)
- 🚧 Guest Pass Management (planned)
- 🚧 Violations (planned)

## Key Architecture Decisions

1. **Clean Architecture**: Separation of concerns with presentation, domain, and data layers
2. **Feature-Based Structure**: Code organized by features, not by layers
3. **Functional Error Handling**: Using `Either<AppException, T>` from dartz package instead of throwing exceptions
4. **Single Responsibility Cubits**: One cubit per flow (LoginCubit, SignupCubit, etc.)
5. **Dependency Injection**: GetIt for managing dependencies
6. **Multi-App Support**: Single codebase supporting multiple apps via `user_apps` junction table

1. **Clean Architecture** - Separation into `data/domain/presentation` layers
2. **One Cubit Per Flow** - LoginCubit, SignupCubit, ForgotPasswordCubit (not one giant AuthCubit)
3. **Multi-App User Model** - Users table + user_apps junction table for app-specific roles
4. **Centralized Error Handling** - `NetworkExceptions` class for all Supabase errors
5. **Theme-First Design** - All colors/styles defined centrally, never hardcoded

## Directory Structure

```
lib/
├── main.dart                      # Entry point
├── park_my_whip_resident_app.dart # App widget
├── auth/                          # Auth manager interface & implementation
├── supabase/                      # Supabase configuration
└── src/
    ├── core/                      # Shared core modules
    │   ├── app_style/             # Theme configuration
    │   ├── config/                # Dependency injection
    │   ├── constants/             # Colors, strings, text styles, app config
    │   ├── helpers/               # Spacing, shared preferences
    │   ├── models/                # Core data models (User, UserApp)
    │   ├── networking/            # Error handling
    │   ├── routes/                # Navigation
    │   ├── services/              # Core services
    │   └── widgets/               # Reusable UI components
    └── features/                  # Feature modules
        ├── auth/                  # Authentication feature
        └── dashboard/             # Dashboard feature
```
