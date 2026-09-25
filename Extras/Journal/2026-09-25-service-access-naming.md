# 2026-09-25 Service Access Naming and Layout

Two follow-ups to the service refactor refined
[Decision 0022](../Decisions/0022-service-state-api-and-provider-shape.md),
which was still proposed.

The nested `State`, `API`, and command-centre protocols now live in a same-file
extension after each service's primary definition. Declared at the top of the
class, they obscured the service's own state and behaviour. The swift plugin's
`organization.md` gained a general rule (swift 0.8.1): declare nested types after
the members that give a type its purpose, preferably in a same-file extension.
The existing rule for nested error types was a special case of this.

The command-centre protocol was renamed from `Provider` to `Access`, and the
property it requires from `xxxService` to `xxxAPI`. Bookish already uses
"provider" for recognition and lookup providers, and `xxxAPI` names what is
vended. The decision's filename keeps `provider` so existing links still work.
Test names such as `CommandProviderTests` were left unchanged.
