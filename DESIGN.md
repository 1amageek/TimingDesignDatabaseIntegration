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

Source bindings retain one exact base revision and exact facet roots.
[Package.swift](Package.swift) is the authority for the exact dependency closure
shared with Xcircuite. Adopted TimingEngine contracts include
[TimingCore strict source characterization](../TimingEngine/Sources/TimingCore/DESIGN.md).
Domain semantics remain owned by those dependencies; this package preserves its
schema and runtime-adapter source bytes without asserting that transitive
dependency source or behavior is unchanged.

TimingCore source inventory v2 is preserved canonically without reinterpreting
D_NET declarations as loads or dropping complete CAP endpoints, owning nets,
physical source identifiers, mirrored listings or same-net records. Reduction is
owned by TimingCore; database encoding cannot manufacture approximation evidence.
The nested v2 schema rejects legacy parasitic JSON. Sorting changes record order
only, retaining all identifiers/values and exact parasitic facet binding.

## Verification and Change Impact

Manifest inspection checks every exact requirement before host resolution.
Xcircuite compiles and exercises the consumed products against that closure.
Existing schema/runtime behavioral tests own state admission and publication;
dependency source-contract changes require the corresponding composing host
verification and remain distinct from process qualification.

TimingDatabaseState schema v2 rejects legacy v1 canonical state. Its canonicalization preserves CAP source IDs, endpoints, owners, values, D_NET declarations and resistance inventory without equipotential reduction.

## Exact PDK Identity Dependency Adoption

[Package.swift](Package.swift) owns the exact revisions consumed by this package.
This adoption consumes the updated PDKCore product directly or transitively.
[Checked PDK identity values](../PDKKit/Sources/PDKCore/Identity/DESIGN.md)
and their immutable schema-2 representation remain owned by the lower contract.
Manifest discovery/exact loading remains owned by
[PDKDiscovery](../PDKKit/Sources/PDKDiscovery/ManifestLoading/DESIGN.md).
Transitive revisions must agree with the composing Xcircuite graph without overrides.
This dependency change preserves this package's domain implementation; lower
behavioral evidence and host identity/provenance tests establish the consumed
contract, not process qualification or unexecuted domain test coverage.
