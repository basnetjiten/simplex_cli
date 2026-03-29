# Simplex CLI

[![Pub Version](https://img.shields.io/pub/v/simplex_cli?logo=dart)](https://pub.dev/packages/simplex_cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Style: Simplex](https://img.shields.io/badge/Architecture-Simplex-lightgrey)](https://pub.dev/packages/simplex)

A professional, artisan-style command-line interface for scaffolding **Clean Architecture** feature modules in Flutter. Built specifically to work with the [Simplex](https://pub.dev/packages/simplex) ecosystem, it enforces industry-standard patterns for data/domain/presentation separation.

---

## 🚀 Key Features

- **Artisan-Style Syntax**: Use familiar `make:xxx` commands (e.g., `make:repo`, `make:source`).
- **Path-Aware Resolution**: Run commands from anywhere within a feature folder – the CLI automatically detects the target feature.
- **Snake Case Enforcement**: Input names in `snake_case` (e.g., `user_profile`) and get perfectly converted `PascalCase` code.
- **Selective Scaffolding**: Generate only abstract interfaces (`-a`) or only concrete implementations (`-i`) as needed.
- **Architectural Guardrails**: Enforces `@freezed`, `@injectable`, `EitherResponse<T>`, and `PagingCubit` patterns.

---

## 📥 Installation

Activate the CLI globally using the Dart SDK:

```bash
dart pub global activate --source git https://github.com/basnetjiten/simplex_cli
```

---

## 🏗️ Quick Start

### 1. Initialize your project
Run this once in your Flutter project root to create your `simplex.yaml`.

```bash
simplex init
```

### 2. Scaffold a new feature
```bash
# Creates domain, data, and presentation layers instantly
simplex make:feature user_profile
```

### 3. Generate individual components
```bash
# Add a repository to the current feature
simplex make:repo user_profile

# Add a remote source to the current feature
simplex make:source auth_api
```

---

## 🛠️ Command Reference

### `simplex init`
Sets up the `simplex.yaml` configuration file. Automatically detects your project and package names.

### `simplex make:feature`
Scaffolds a complete feature module with a standard Clean Architecture structure.

**Visual Directory Structure:**
```text
lib/features/product_detail/
├── data/
│   ├── models/          product_detail_model.dart
│   ├── sources/         product_detail_remote_source_impl.dart
│   └── repositories/    product_detail_repository_impl.dart
├── domain/
│   ├── sources/         product_detail_remote_source.dart
│   └── repositories/    product_detail_repository.dart
└── presentation/
    ├── cubit/           product_detail_cubit.dart + _state.dart
    ├── pages/           product_detail_page.dart
    └── widgets/         (reusable widgets for this feature)
```

### `simplex make:repo`
Generates both the **Abstract Interface** (Domain) and **Concrete Implementation** (Data).

- **`--abstract-only` (`-a`)**: Generate only the `domain/` interface.
- **`--impl-only` (`-i`)**: Generate only the `data/` implementation.

### `simplex make:source`
Generates both the **Remote Source Interface** (Domain) and **Implementation** (Data).

- **`--abstract-only` (`-a`)**: Generate only the `domain/` interface.
- **`--impl-only` (`-i`)**: Generate only the `data/` implementation.

### Other Scaffolding
- `simplex make:model`: Generate Freezed-based data models.
- `simplex make:cubit`: Generate Simplex-based Cubits.
- `simplex make:bloc`: Generate Simplex-ready Blocs.
- `simplex make:page`: Generate basic presentation pages.

---

## 📝 Naming Conventions

To ensure absolute consistency, the CLI enforces **snake_case** for all command line arguments:

| Target | Input | Class Name | File Name |
| --- | --- | --- | --- |
| Feature | `auth_profile` | `AuthProfile` | `auth_profile/` |
| Repository | `user_repo` | `UserRepoRepository` | `user_repo_repository.dart` |
| Cubit | `nurse_profile` | `NurseProfileCubit` | `nurse_profile_cubit.dart` |

---

## 🛠️ Simplex.yaml Reference

The `simplex.yaml` file acts as the source of truth for your project structure and feature registry.

```yaml
project_name: my_app
package_name: my_app
features_path: lib/features
test_path: test/features
default_api: graphql  # graphql | rest

# The CLI auto-maintains this registry
features:
  user_profile:
    api: graphql
    paging: true
```

---

## 🤝 Credits & Author

Developed and maintained by **Jiten Basnet**.

Generated code headers included in all files:
```dart
/// Created on: YYYY-MM-DD HH:MM:SS
/// Generated with Simplex CLI
```

---

## 📄 License

MIT © [Jiten Basnet](https://github.com/basnetjiten)
