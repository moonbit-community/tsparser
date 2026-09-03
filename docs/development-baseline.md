# Development baseline

This is an audit record, not a permanent minimum-version lock. It was captured
on 2026-07-16 before MoonBit implementation work began.

```text
moon 0.1.20260713 (75c7e1f 2026-07-13) ~/.moon/bin/moon
moonc v0.10.4+2cc641edf (2026-07-15) ~/.moon/bin/moonc
moonrun 0.1.20260713 (75c7e1f 2026-07-13) ~/.moon/bin/moonrun

Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

Reproduce the current environment record with:

```sh
moon version --all
```

TypeScript is independently frozen at npm version 6.0.3 and git commit
`050880ce59e30b356b686bd3144efe24f875ebc8`; see
[`upstream-source-manifest.json`](upstream-source-manifest.json).

The reference schemas, complete-corpus checks, native streaming design, and
pressure-budget workflow are documented in
[`reference-and-diff.md`](reference-and-diff.md).
