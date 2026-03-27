# simplex_cli

A Dart CLI tool to scaffold Clean Architecture feature modules for Flutter projects using the [Simplex](https://pub.dev/packages/simplex) library.

## Installation

```bash
dart pub global activate simplex_cli
```

## Quick Start

```bash
# 1. Run once in your Flutter project root
cd your_flutter_project
simplex init

# 2. Generate a new feature
simplex make feature

# 3. Run code generation
dart run build_runner build --delete-conflicting-outputs
```

## Commands

### `simplex init`

Initializes `simplex.yaml` in the current project root. Prompts for:
- Project/package name
- Features and test directory paths
- Default API type (`graphql` | `rest`)

```bash
simplex init
# or non-interactively:
simplex init --project-name my_app --package-name my_app --default-api graphql
```

---

### `simplex make feature`

Scaffolds a complete Clean Architecture feature module with interactive prompts.

```
? Feature name (snake_case): product_detail
? API type [graphql/rest]: graphql
? Enable pagination (PagingCubit)? y
? Generate test stubs? y
```

**Generated structure:**
```
lib/features/product_detail/
├── data/
│   ├── graphql/         product_detail_query.graphql   (GraphQL only)
│   ├── models/          product_detail_model.dart
│   ├── sources/         product_detail_remote_source_impl.dart
│   └── repositories/    product_detail_repository_impl.dart
├── domain/
│   ├── sources/         product_detail_source.dart
│   └── repositories/    product_detail_repository.dart
└── presentation/
    ├── cubit/           product_detail_cubit.dart + _state.dart
    ├── pages/           product_detail_page.dart
    └── widgets/
test/features/product_detail/
    ├── data/source/     product_detail_remote_source_test.dart
    └── presentation/    product_detail_cubit_test.dart
```

**Non-interactive flags:**
```bash
simplex make feature --name product_detail --api graphql --paging --tests
simplex make feature --name notification --api rest --no-paging --no-tests
```

---

### `simplex convert`

Converts an existing feature's **data layer** between GraphQL and REST without touching domain or presentation.

```bash
# Preview changes (no files written)
simplex convert product_detail --to rest --dry-run

# Perform the conversion
simplex convert product_detail --to rest

# Convert back to GraphQL
simplex convert product_detail --to graphql
```

> ⚠️ Only `data/sources/` and `data/repositories/` impl files are overwritten.  
> Domain contracts and presentation layer are **never modified**.

---

## simplex.yaml Reference

```yaml
project_name: my_app
package_name: my_app
features_path: lib/features
test_path: test/features
default_api: graphql  # graphql | rest

# Auto-maintained feature registry
features:
  product_detail:
    api: graphql
    paging: true
  notification:
    api: rest
    paging: false
```

---

## Generated File Conventions

Follows strict Simplex architecture rules:
- `@freezed` for all models and state classes
- `@injectable` / `@lazySingleton` for all DI-registered classes
- `EitherResponse<T>` for all repository methods
- `SimplexCubit<State>` extended by all cubits
- `handleAPICall` (non-paged) or `PagingCubit` fetch function (paged)
- `processApiCall` in all repository impls

## License

MIT
