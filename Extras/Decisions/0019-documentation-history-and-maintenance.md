# 0019: Preserve historical journals while maintaining current documentation

- Status: Accepted
- Date: 2026-09-18

## Context

Bookish documentation serves different purposes. Core documentation describes
the system as it exists now. Decisions record the rationale and scope of an
architectural choice. Journal entries record work as it happened.

Terminology and implementation names change over time. Rewriting every record
to match the latest vocabulary destroys useful historical context and can make
past validation or design work harder to understand.

## Decision

Journal entries remain unchanged as historical records. Record later changes in
a new entry or a clearly separated follow-up section in the current journal.

Core documentation is maintained to describe current behaviour, terminology,
and paths.

Decisions may receive limited terminology updates when their meaning remains
unchanged. A change that alters a decision's rationale, scope, or consequences
requires a new decision or an explicit supersession. Ask before making an
ambiguous documentation change.

## Consequences

- Documentation readers can distinguish current design from historical work.
- Historical validation records retain the commands, paths, and terminology
  that existed when they were written.
- Terminology migrations update living documentation and add a historical
  record instead of rewriting prior journals.
- Decision history remains trustworthy when architectural direction changes.
