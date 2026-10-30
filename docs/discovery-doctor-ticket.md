# Installed tool discovery and doctor

This is a historical ticket record. Its baselines, paths, planned steps, and authorization describe that work. For current behavior and setup, read the [consumer specification](spec.md) and [README](../README.en.md). See the [acceptance evidence scope](acceptance.md#current-status-and-evidence-scope) for the completed checks and their limits.

The user wants `just sync` in cubrid-language-tools to remove Neovim CLI and native path configuration. Add a doctor that diagnoses failures. Simplify the user's Neovim setup afterward in a separate configuration checkout.

## Dispatch

Base is cubrid.nvim main b5c0c64. Implementation checkout is `/home/vimkim/gh/cubrid.nvim-discovery-doctor`, branch `feat/discovery-doctor`. Integration destination is local main. This ticket supersedes old alpha dispatch restrictions only for its stated scope. Shared engine and native inputs remain read-only. The coordinator owns the later real configuration change. Commit meaningful task changes before review. Integration, pushes, and publication remain gated.

## Shape and synthesis

Candidate A supplies one internal environment resolver and a separate doctor module. Candidate B agrees on the installation provenance and restart rules. Keep the requested trusted setup separately from the resolution used by the active session. Represent native settings as one optional complete worker/runtime/manifest tuple. Discovery and doctor share the resolver. No additional setup option is necessary.

The design candidates were read in full. Both meet the zero-configuration, trust-boundary, consistency, and small-interface criteria. A is the base because its fixed invalid probe requires positive native parser evidence. Use the existing tested `SELECT ,;` probe and require `CUBRID-S1001` with no tool/unsupported failures. Graft B's explicit distinction between the active session and newly discovered candidate. The empty-document probe was verified against the real server but is weaker than the positive syntax-error evidence. No separate cross-judge ran because every available model belongs to the GPT family.

1. Preserve the absolute explicit server and native-pair overrides and full settings replacement validation.
2. Otherwise resolve the server from trusted Neovim PATH. Follow its canonical executable into its Python installation prefix. Read exactly one installed cubrid-language-tools dist-info direct_url.json under lib/python*/site-packages. Accept only a local absolute directory file URL. Decode escaped paths. No cwd/project, HOME convention, remote URL, executable metadata field, or recursive checkout search.
3. Select only `<installed-source>/native/parser-worker/build/parser-worker` and adjacent manifest.json. Derive the absolute runtimePrefix from that manifest. Bound metadata reads, reject ambiguity/malformed data, and expose precise reasons. File presence is discovery evidence only. The engine retains native qualification.
4. Resolve again on server start and restart. Preserve one editor session. Doctor reports fresh resolution and any active-session difference.
5. Add `:CubridDoctor`, `require('cubrid').doctor()`, and `:checkhealth cubrid`. Report selected paths and provenance, Neovim version, current buffer filetype, active CUBRID client, useful current diagnostics, LSP log path, and actionable failure remedies. Doctor works before opening SQL and with missing dependencies.
6. Run a bounded private LSP probe with fixed synthetic invalid SQL, isolated root and explicit schema disabled. Never submit user buffers. No duplicate native protocol, parser, SQL execution, databases, shell interpolation, or downloads. Verify initialization, expected syntax diagnostic, timeout/exit and owned cleanup. Keep the report available in headless execution and do not modify the user's buffer. Health and command consume one report.
7. Use public-interface TDD and real nvim --headless. Verify actual PATH uv install, explicit precedence, malformed/missing/ambiguous metadata, encoded paths, missing runtime and restart recovery, doctor failures/timeouts and cleanup, and existing tests. Write exact acceptance and limitations in docs/acceptance.md. Update bilingual README and Vim help.

## Throughput checkpoint

- Blocking first steps. Shared CLI and native contract inspection is complete. Baseline tests pass using the installed PATH server. A real private LSP empty-document probe initializes native validation and exits.
- Independent workstreams. The two read-only design candidates used separate output directories. Code is one coupled workstream.
- Shared mutable state. One fresh implementer owns plugin code, tests, and user docs in this checkout. Root owns dispatch and the later config checkout.
- Smallest safe decomposition. Discovery, lifecycle, and doctor share resolution and stay under one code owner. The config change follows verification.
