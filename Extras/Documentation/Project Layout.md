# Project Layout

This document describes a reusable project layout for Swift application projects.

The style is similar in spirit to extreme packaging: most reusable application code lives in Swift packages, while the Xcode app target stays thin and focuses on product assembly, platform entry points, entitlements, and bundled app resources.

## Goals

- Keep domain logic testable without launching the app.
- Keep app and extension targets thin.
- Make package boundaries explicit and durable.
- Keep feature work local to the package or service that owns it.
- Allow owned dependencies to be edited locally while retaining normal package identity.
- Support command-driven UI actions that can be reused from menus, toolbars, buttons, shortcuts, context menus, and automation.
- Keep localisation close to the module that owns the text.
- Keep project metadata, planning, assets, scripts, screenshots, and legacy material outside the production source tree.

## Top-Level Shape

Use `Sources/` for root app source and package source directories. This follows SwiftPM conventions and should be treated as the standard spelling for the template.

Use this shape as the starting template:

```text
ProjectName/
  ProjectName.xcodeproj
  ProjectName.xcworkspace
  Package.swift
  README.md
  AGENTS.md
  Sources/
    ProjectName/
      ProjectNameApp.swift
      Resources/
  Tests/
  Dependencies/
    ProjectCore/
      Package.swift
      Sources/
      Tests/
    Commands/
      Package.swift
      Sources/
      Tests/
    OwnedDependency/
      Package.swift
  Extras/
    Documentation/
    Journal/
    Scripts/
    Assets/
    Screenshots/
    Legacy/
```

Not every project needs every folder. Smaller projects may have one package under `Dependencies/`; larger projects may split product logic into many packages and targets.

## Root App Target

The root Xcode project owns the final application product. Its source should be deliberately small:

- app entry points;
- platform-specific application delegates or scene setup;
- entitlements and host-level property lists;
- app icons and resources that truly belong to the shipping app bundle;
- composition of package-provided views, services, command centres, and model containers.

Avoid placing domain logic, service implementations, persistence models, or reusable UI components directly in the app target. Those should live in packages under `Dependencies/`.

## Root Package

A root `Package.swift` is usually not required. The app target and packages under `Dependencies/` should remain the main build and architecture boundaries.

If tooling needs an aggregate package for local development, indexing, previews, or integration tests, prefer generating or managing that through a ReleaseTools (`rt`) command rather than maintaining it by hand. Do not use a root package as a dumping ground for product code.

## Dependencies Directory

`Dependencies/` contains Swift packages that the app works on directly.

There are two common kinds:

- **Product packages**: project-owned packages such as `ProjectCore`, `ProjectUI`, or feature services.
- **Owned external packages**: reusable packages maintained separately, but checked out locally for development.

For owned external packages, prefer adding them as Git submodules. This keeps development simple when changes span app code and shared libraries, while preserving each package's standalone repository and release history.

When a package should work both inside and outside the parent app checkout, prefer a local-or-remote dependency helper in `Package.swift`: use the local sibling package when it exists, otherwise fall back to the released Git URL.

## Package Layering

Use directional package dependencies. Lower layers should not import higher layers.

Recommended layers:

- **Core/domain**: storage-independent models, value types, validation, parsing, import/export records, and pure transformations.
- **Persistence**: SwiftData models, migrations, repositories, and mapping to/from domain or interchange records.
- **Services**: feature orchestration, state, side effects, and command provider implementations.
- **UI**: reusable SwiftUI views, feature screens, view models, preview fixtures, and command-backed controls.
- **Host**: the app and extension targets that assemble services and UI.

For a small app, these may be targets within one package. For a larger app, prefer service-based packages or service-based targets under `Dependencies/` so feature ownership stays explicit.

## Service Packages

Service packages own feature-specific state and operations. They are the preferred structure for larger apps. Typical service targets include model, persistence, sheets, appearance, hot keys, search, suggestions, accounts, settings, and reusable UI helpers.

Use service packages when a feature has:

- its own state lifecycle;
- its own commands;
- testable behavior independent of the app host;
- platform integration that should be isolated behind a small API.

Do not create a service package just to move one or two files. A package boundary should reduce coupling or improve testability enough to justify the extra manifest and dependency management.

## Command-Driven Actions

Adopt a command-driven approach for user actions.

Use the standard `Commands` and `CommandsUI` packages:

- define each action as a command;
- keep availability and execution on the command;
- make commands generic over provider protocols instead of concrete app objects;
- let a command centre satisfy provider protocols by forwarding to services;
- build buttons, menu items, toolbar items, shortcuts, importer flows, and confirmation flows from command UI helpers.

This makes the same action reusable from multiple UI surfaces and keeps side effects explicit.

Prefer command definitions near the feature or service that owns the behavior. The root app should mostly compose commands into platform menus and scene commands.

## Command Centre

Use a command centre as the runtime integration object. It should:

- conform to command provider protocols;
- own or reference the feature services needed by commands;
- provide SwiftUI environment injection;
- track running command state when needed;
- offer convenience helpers for command-backed controls.

Avoid making the command centre a general-purpose global object. If it grows too broad, split provider protocols and services so each command only sees the capabilities it needs.

## Localisation

Use module-owned localisation by default.

Each module that owns user-visible text should own its `Resources/Localizable.xcstrings` catalog and declare it as a processed resource in its package target.

Use generated string catalog symbols wherever possible instead of passing string literals or raw keys. String literals are still acceptable when:

- the API cannot accept generated symbols;
- the key is genuinely dynamic;
- the generated symbol tooling is not available for that target yet.

For command names and help text, prefer deriving localisation keys from stable command IDs. Avoid passing arbitrary strings or localisation keys into command constructors unless the name is truly unbounded.

Centralised app-level localisation is still useful for text that belongs only to the host app: app name, app menus, onboarding, root settings, entitlement descriptions, and platform-specific host screens. Package-owned feature text should stay with the package.

## Resources

Keep resources with the module that owns them:

- package-local string catalogs, fixtures, icons, and sample data belong under the package target's `Resources/`;
- app icons, entitlements, launch assets, and host-specific property lists belong under the root app target resources;
- documentation assets, marketing screenshots, raw artwork, and design files belong under `Extras/`.

This keeps package previews, tests, and reusable modules self-contained.

## Extras Directory

`Extras/` is for project material that is important but not part of the shipping source layout:

- `Extras/Documentation/` for architecture, specifications, design notes, and planning documents;
- `Extras/Journal/` for dated implementation and research notes;
- `Extras/Scripts/` for project-maintained automation;
- `Extras/Assets/`, `Extras/Artwork/`, or `Extras/Screenshots/` for supporting visual material;
- `Extras/Legacy/` for archived code or data used as migration reference.

Keep `Extras/` documented enough that future maintainers know whether a file is authoritative, historical, generated, or raw source material.

## Tests

Prefer package-level tests for package behavior. Domain, persistence, service, and importer tests should live next to their package targets.

Use root `Tests/` for integration tests, UI tests, and host-level behavior that genuinely crosses package boundaries.

Migration work should include stable fixtures, preferably owned by the persistence package tests or an explicit fixture package.

## Automation and Validation

Keep reusable project scripts in `Extras/Scripts/`. For Swift projects, prefer Swift-based scripts or Swift package plugins when the task benefits from typed access to project structure.

Expected automation includes:

- formatting and linting;
- target validation;
- full project validation;
- release/upload support.

The template should make the common commands discoverable from README or documentation, not hidden in tribal knowledge.

## Submodules

Use Git submodules for owned packages that are edited alongside the app, especially packages shared across multiple projects.

Recommended conventions:

- keep submodules under `Dependencies/`;
- use SSH Git URLs for private or owner-controlled repositories when appropriate;
- pin submodules normally, but use integration branches when a parent project intentionally tracks in-progress shared-library work;
- keep package manifests able to fall back to released remote dependencies when the local sibling package is absent.

Submodules add operational overhead, so reserve them for owned packages where local co-development matters. For ordinary third-party dependencies, normal SwiftPM URL dependencies are simpler.

## Unclear or Unsettled Parts

- Root `Package.swift` support should be handled by tooling if it is needed. It should not be part of the required hand-maintained template.
- The right granularity for package splitting is contextual. A large app should use service-based packages or targets; a small app may only need protocol, implementation, and facade targets in one package.
- The localisation generation story is still evolving. Xcode generates string catalog symbols automatically, while command-line builds may need an explicit plugin or validation step.
- Distributed module-owned localisation needs a reliable generation and validation workflow before it can be treated as fully mechanical.
- Submodules are useful for owned packages, but the exact policy for branches, update cadence, and release tagging should be standardised.

## Template Improvements to Consider

- Add an `rt` command to create or maintain any aggregate root package needed for tooling.
- Create a reusable package manifest helper for local-or-remote owned dependencies instead of copying the helper into each package.
- Provide a standard `Commands` dependency and starter command centre in the template.
- Provide a standard localisation setup: per-target string catalogs, generated symbols, and a validation script that catches raw UI string drift where practical.
- Provide submodule helper scripts for adding, updating, checking status, and syncing integration branches.
- Add a template `Extras/Documentation/Architecture.md`, `Project Layout.md`, and `Journal/index.md`.
- Make validation scripts part of the template from day one, with narrow target validation and full project validation entry points.
