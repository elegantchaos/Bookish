# 0021: Configure record creation through browser indexes

- Status: Accepted
- Date: 2026-09-25

## Context

The New menu needs to offer the standard catalogue record kinds. The browser
toolbar needs a creation action that fits the active index, including indexes
that can create more than one kind.

## Decision

An index record declares its creatable kinds in `newRecordTypes`. This is
separate from its advisory `types` property, which describes records that the
index may display. The toolbar shows one direct New action when the active
index declares one kind and a type menu when it declares several. The New menu
always offers the standard user-creatable kinds.

Creation is a command. It persists a record, navigates to a configured library
index whose query includes the record, clears the name filter, and selects the
new record.

## Alternatives considered

Using the existing `types` property for creation was rejected because an index
may display records that it should not offer to create. A fixed toolbar kind for
each hard-coded index was rejected because index records already own browser
configuration.

## Consequences

- Standard index seeds declare their creation kinds explicitly.
- Existing standard indexes gain missing creation metadata without replacing
  other stored index properties.
- Custom indexes can configure one or more standard creation kinds.
