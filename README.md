# TimingDesignDatabaseIntegration

Host-only persistence integration for timing design, constraints, libraries, and exact
dependency bindings.

| Product | Responsibility |
|---|---|
| `TimingDesignDatabaseSchema` | Canonical timing state, validation, paging, and source contracts |
| `TimingDesignDatabaseRuntimeAdapter` | Exact-base plan compilation and bounded snapshot projection |

Timing verdicts remain exact-revision evidence. The adapter admits canonical state only
when logic, standard-cell, and parasitic bindings match the selected dependency roots.

## Verification

```bash
swift build --build-tests -j 4 \
  -Xswiftc -Xfrontend -Xswiftc -disable-round-trip-debug-types
```
