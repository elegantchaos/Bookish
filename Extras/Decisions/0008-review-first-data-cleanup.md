# 0008: Make data cleanup review-first

- Status: Accepted
- Date: 2026-09-08

## Context

Catalogue cleanup can identify inconsistencies, duplicate records, and values
stored in unsuitable fields, but incorrect automated changes could lose user
intent, provenance, or relationship data.

## Decision

Cleanup rules analyse record snapshots and produce immutable, reviewable issues
and proposals. A proposal includes its evidence, confidence, expected target
values, and whether confirmation is required.

No cleanup proposal performs a durable mutation until the user has reviewed and
accepted it. Applying an accepted proposal re-reads its targets and rejects a
stale precondition rather than overwriting a later edit.

Deterministic rules produce initial candidates. Foundation Models may assist with
bounded, ambiguous review tasks only; their output is validated and presented as
a confirmation-only suggestion, never as a mutation authority.

## Alternatives considered

Unattended cleanup and model-authorised mutations were rejected because they can
lose user intent, provenance, or relationship data. Making Foundation Models a
required first-pass matcher was rejected in favour of deterministic candidate
generation with optional, bounded assistance for ambiguous cases.

## Consequences

- Cleanup remains explainable, inspectable, and safe to revisit.
- Accepted edits are protected from stale-plan overwrites.
- Deterministic rules establish a reliable baseline without AI availability.
- AI-assisted results require the same validation and user confirmation as all
  other proposals.
