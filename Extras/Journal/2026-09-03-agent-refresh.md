# Agent Refresh

Ran the `refresh` maintenance workflow for the Bookish repository.

## Summary

- Installed `agt` through Mint because the shared refresh workflow requires it and it was not on `PATH`.
- Synced shared skills and refreshed runtime skill links from `~/.local/share/agents`.
- Cleared redundant runtime-only Codex approval rules from `~/.codex/rules/default.rules`.
- Synced shared Codex rules into generated runtime copies.
- Refreshed `AGENTS.md` to match the shared baseline and current installed skill names.
- Replaced remaining old validation skill references with `swift-validation` in Bookish package guides and shared agent guidance.

## Notes

- `agt skills status` reported all public skills clean with runtime links ok.
- `agt rules status` reported generated shared rule copies unchanged after synchronization.
- `default.rules` is intentionally empty after removing narrower approvals covered by shared `git`, `swift`, and `tools` rules.
