# 2026-09-11 Navigation Selection Commands

User-triggered browser selection now goes through commands rather than directly
mutating `BookishNavigationService` from SwiftUI views. The new commands select
main workflows, browser indexes, records, and the active name filter.

`BookishEngine` remains the only environment object in this pass. Views keep
their existing `commander.navigation` convenience access for reading state;
injecting individual services for direct read access remains a future design
review.

`BookishNavigation` now explicitly includes name-filter mutation, keeping the
command provider contract aligned with the navigation service. Command-provider
tests verify all selection operations are vended through that contract.
