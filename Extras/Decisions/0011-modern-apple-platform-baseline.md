# 0011: Use a modern Apple-platform Swift baseline

- Status: Accepted, deployment target provisional
- Date: 2026-09-14

## Context

Bookish is a native Apple-platform application. Its implementation baseline
should support modern Swift language features, SwiftUI, structured concurrency,
and the Foundation Models APIs planned for recognition and review workflows.

## Decision

Bookish supports macOS and iOS, including both iPhone and iPad.

The application uses Swift 6.4 or later, SwiftUI, modern Swift `async`/`await`
concurrency, and Swift Testing for Bookish-owned tests.

The current minimum deployment target is macOS 26.0 and iOS 26.0. Before the
first release, the project expects to raise both minimums to 27.0 so the Cloud
Foundation Models APIs are part of the supported platform baseline.

Foundation Models capability may still be unavailable at runtime because of
device eligibility, account state, system settings, or model readiness. Bookish
must continue to present an explicit unavailable state where appropriate.

## Alternatives considered

UIKit-first UI, callback-based asynchronous code, and XCTest for Bookish-owned
tests were not adopted because they do not match the chosen modern Swift
baseline. Supporting operating systems earlier than 26.0 is outside the planned
release scope. Keeping 26.0 permanently remains possible, but the expected move
to 27.0 before release makes Cloud Foundation Models APIs part of the platform
baseline while retaining runtime availability checks.

## Consequences

- New code may use the selected modern Swift and SwiftUI baselines directly.
- Bookish-owned tests use Swift Testing rather than XCTest.
- Supporting earlier operating systems is not part of the planned release scope.
- Features using Foundation Models still need runtime availability handling.
