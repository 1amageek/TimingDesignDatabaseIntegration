# Timing DesignDatabase Integration

## Purpose and Scope

Host-only package integrating canonical TimingCore values with exact database
facets. Parent: [LSI](../DESIGN.md). Existing schema and runtime-adapter targets
retain their public responsibilities; this adoption changes dependency identity.

## Responsibilities and Boundaries

The schema validates and canonically encodes timing state with exact logic,
library and optional parasitic facet bindings. The runtime adapter validates
candidate publication against the exact base revision and dependency roots.
TimingEngine owns timing semantics; DesignDatabase owns database persistence.

## Related Designs

| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [LSI](../DESIGN.md) | parent | Domain integration boundary | Host-only composition | Portable engines remain independent |
| [TimingEngine](../TimingEngine/DESIGN.md) | depends on | TimingCore value types and canonical validator | Domain state admission | Adopt the same exact revision as the composing host |
| [DesignDatabase](../DesignDatabase/DESIGN.md) | depends on | Exact revision, facet and candidate validation | Immutable state publication | Exact base and source roots remain required |
| [Xcircuite](../Xcircuite/DESIGN.md) | used by | Schema and runtime adapter products | Host composition | Revision requirements must resolve without overrides |

## Architecture

```text
TimingCore + exact source facet bindings -> TimingDesignDatabaseSchema
    -> TimingDesignDatabaseRuntimeAdapter -> DesignDatabase candidate validation
```

## Contracts and Invariants

Timing state remains bound to one exact base revision and source facet roots.
The package adopts TimingEngine `fc21d6abe40e2888e595bcb58ed76f2733497e1d`
so Xcircuite can compose manifest-bound STA with this integration. That revision
leaves the consumed TimingCore source/API unchanged from `c009525`; STA request
schema and process/corner admission belong to TimingEngine and are not copied
into the database schema. No database API, state schema or source changes are
part of this dependency adoption.

## Verification and Change Impact

The dependency adoption is checked by manifest decoding and an unchanged
TimingCore source diff. Xcircuite's dedicated host build compiles both consumed
products against the exact adopted revision, and focused native STA tests prove
the composing host path. [TimingDatabaseSchemaTests](Tests/TimingDesignDatabaseIntegrationTests/TimingDatabaseSchemaTests.swift)
owns schema canonical round-trip and invalid-state rejection; those unchanged
behaviors are not reimplemented by this adoption.
