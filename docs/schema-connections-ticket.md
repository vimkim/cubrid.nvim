# N636. CSQL-backed schema connections

The user wants table and column completion after selecting a CSQL connection in Neovim. The central exporter owns catalog acquisition. This ticket delivers Neovim connection controls using that exporter and the existing snapshot/LSP transport.

The exact dispatch is `/tmp/cubrid-schema-implementation-EMmkLi/contract.md`, synthesized from two design candidates. Read it with `docs/spec.md` and `AGENTS.md` before implementation. The starting plugin baseline is `44dfe90`. Work in `/home/vimkim/gh/cubrid.nvim-schema-completion` on `schema/csql-completion`; main is the integration destination. Central source is a read-only dependency at `/home/vimkim/gh/cubrid-language-tools-schema-export`.

Deliver trusted exporter/CSQL options, optional first-buffer prompting, connect/refresh/disconnect/status commands, actual-client-scoped generation state, private atomic snapshots, a null clear/reload barrier across connections, offline restoration, and cancellation/cleanup. The frozen CLI request carries command and password through stdin. Lua owns JSON transport and editor state, while the central adapter owns CSQL parsing and catalogs. Explicit live selection applies to all buffers of that client until disconnect.

Use public-interface TDD and real headless Neovim. Verify completion values, original CSQL input, skip, refresh/stale failure, failed switching, old callbacks, multiple roots, setup/native settings, private files, redaction, process cleanup, and portable regressions. Keep current tests and offline behavior intact. Add reproducible feature cases to the test runner and update help plus both READMEs. Record exact checks and remaining limits in `docs/acceptance.md` with a focused report if needed.

Local task commits are authorized. Commit meaningful changes before review. Main integration and publication follow AGENTS.md. Root owns the native CSQL environment and final cross-repository verification. Work item 636 tracks the paired delivery.
