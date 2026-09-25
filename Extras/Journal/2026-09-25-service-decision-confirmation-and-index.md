# 2026-09-25 Service Decision Confirmation and Index

[Decision 0022](../Decisions/0022-service-state-api-and-provider-shape.md) was
confirmed after comparing it with the earlier command and service decisions.
It refines [Decision 0001](../Decisions/0001-engine-command-boundary.md) by
specifying view-facing state injection and command-facing API access. It
partially supersedes [Decision 0014](../Decisions/0014-narrow-command-providers-and-services.md):
commands still depend on narrow capabilities, but the engine now vends each
service's API, and views receive a state projection that may include bindings
and view-owned UI methods.

The new [decision index](../Decisions/index.md) lists all current decisions in
number order, with short summaries and notes about later refinements. The
individual decision files remain authoritative.
