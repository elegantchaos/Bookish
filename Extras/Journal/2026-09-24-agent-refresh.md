# Agent Refresh

Ran the `baseline:refresh` maintenance workflow for Bookish.

## Summary

- The shared agents repository was already current.
- Refreshed shared skills, runtime links, plugins, and generated Codex rules.
- Regenerated `AGENTS.md` around the shared `COMMON.md` baseline while retaining Bookish-specific storage, validation, records, and scratch-file policies.
- Updated the skill names to the installed `baseline:*` and `swift:*` forms.

## Verification

- All shared public skills were clean and linked in Codex and Claude Code.
- The Claude Code CLI was unavailable, so its plugins were skipped.
- Generated Codex rule copies matched their shared sources; runtime-only `default.rules` remains empty.
