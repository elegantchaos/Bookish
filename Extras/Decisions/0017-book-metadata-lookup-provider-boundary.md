# 0017: Keep book metadata lookup providers storage-neutral

- Status: Accepted
- Date: 2026-09-18

## Context

Bookish needs metadata from multiple sources and may also search the user's
existing catalogue. The legacy implementation combined source adaptors,
persistence access, request coordination, and candidate-to-record mapping in
one model layer. That makes sources difficult to test and couples lookup to a
specific persistence implementation.

## Decision

`BookishLookup` owns provider-neutral lookup queries, metadata candidates,
provider failures, and the concurrent provider coordinator. Providers conform
to `BookLookupProvider` and return candidates without writing records or
depending on the Bookish datastore. The package depends on `BookishRecord` so
each candidate can include a canonical record snapshot without acquiring
storage responsibilities.

Candidates carry provider identity, source identity, bibliographic metadata,
cover URLs, optional raw provider data, and a canonical record snapshot. The
application is responsible for reviewing candidates, choosing whether to persist
them, and preserving import provenance.

A provider that reads the existing catalogue must depend on a narrow, read-only
catalogue-query protocol. It must not make the lookup package depend directly
on the app or a concrete store implementation.

The application selects provider instances and passes them to the lookup
coordinator. Ownership of settings and credentials follows
[decision 0018](0018-application-owned-service-configuration.md).

## Alternatives considered

Putting all providers in `BookishApp` was rejected because it would make
provider behavior harder to test and reuse. Making `BookishLookup` depend on
the datastore immediately was rejected because only self lookup needs it; that
would impose persistence coupling on every remote provider. Keeping only direct
provider calls without a coordinator was rejected because the product needs to
combine results and partial failures from several sources.

## Consequences

- Provider unit tests use injected sessions or fakes and never require live
  networking.
- Adding a source requires only a `BookLookupProvider` adaptor.
- The coordinator supports provider replacement so the application can apply
  changed configuration without restarting.
- Self lookup has an explicit dependency-design step before implementation.
- Candidate persistence remains an application integration concern.
