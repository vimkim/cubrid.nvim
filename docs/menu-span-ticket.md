# Preserve the LSP replacement span through actual completion acceptance

This is a historical ticket record. Its baselines, paths, planned steps, and authorization describe that work. For current behavior and setup, read the [consumer specification](spec.md) and [README](../README.en.md). See the [acceptance evidence scope](acceptance.md#current-status-and-evidence-scope) for the completed checks and their limits.

Work item 582 follow-up. Baseline is `453c091e102b3d7c6649d37c55983ace06067bd5`.
The original installed artifact passes direct text-edit tests but fails its documented native completion menu.
The independent executable repro is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-independent/run-probe.sh menu-visible`.
Its `menu-visible.lua` and menu-observed output show a visible SELECT candidate accepted with CTRL-N/CTRL-Y, producing `SELECTect` from `SEL|ect` after Korean and emoji text.
The server supplies the correct full UTF-16 replacement range. VS Code accepts it correctly.
Enabling `vim.lsp.completion.enable` alone was independently tested and does not fix this host's behavior.

## Required behavior

The documented native menu accepts exactly the server's full replacement span, including the suffix after the original cursor, without changing text outside the span.
Keep the shared engine authoritative. Do not infer token boundaries or add language completion logic in the plugin.
Use Neovim's public LSP, completion UI and editing APIs. Do not patch runtime internals, alter the engine, or globally replace handlers for unrelated clients.
The coordinator provides a bounded adapter sketch before implementation.

Model a completion context with buffer, owned client identity, source/request identity, original position/span and proposed text. Handle selection, cancellation, stale callbacks, restarted clients and repeated accept events explicitly.
Preserve original Unicode/UTF-16 mapping, CRLF disk behavior, cursor placement and undo. Do not restore an entire captured document over unrelated edits.
Any stale-context refusal must preserve user text and be tested on a legitimate asynchronous path.

## Acceptance

1. Commit the actual menu regression before the fix and observe its suffix failure on the baseline.
2. Use a visible native menu with public input events, choose and accept the engine item, and assert exact final text, cursor and suffix removal.
3. Exercise Unicode, no suffix, a suffix, quoted/qualified candidates, multiple choices, cancellation, rapid re-request/stale response, client restart and buffer switch. Assert text outside the server range is preserved.
4. Check undo behavior and CRLF save through the real editor.
5. Rebuild/extract the package, rerun existing editor acceptance against fixed core `d5a571eb03d543af1438b85933fcad3aed60f9f0`, and rerun the independent public menu probe.
6. Update help, documented completion entry points and acceptance evidence. Keep any remaining limits explicit.

Own this isolated consumer worktree and `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/` only.
Read AGENTS.md, docs/spec.md, docs/design.md, this ticket and the exact dispatch first.
Local commits are authorized. No rebase/integration, push or publication. No edits to original alpha worktree, core, user profile or shared host inputs.
