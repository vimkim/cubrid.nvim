# Standard CUBRID LSP configuration dispatch

This is a historical ticket record. Its baselines, paths, planned steps, and authorization describe that work. For current behavior and setup, read the [consumer specification](spec.md) and [README](../README.en.md). See the [acceptance evidence scope](acceptance.md#current-status-and-evidence-scope) for the completed checks and their limits.

## Goal and baseline

Work item 606. Users configure the shared CUBRID language server through standard Neovim LSP configuration and receive SHOW/hint completion and authoring warnings through Blink. The coordinator supplies this ticket's exact dispatch commit in the implementer prompt. Product baseline is `6714657a0ea4ff19e2f54d61f6994aff1b7ec358`. Worktree is `/home/vimkim/gh/cubrid.nvim-standard-lsp`, branch `feat/standard-lsp-config`. Destination is local main in the primary Neovim checkout.

Read AGENTS.md, docs/spec.md, docs/design.md, this dispatch, and the selected shared design at `/home/vimkim/gh/cubrid-language-tools-show-hints/docs/tickets/show-hint-design.md`. The old alpha dispatch is historical. This dispatch owns the current ticket. The coordinator's engine implementer owns shared language changes. This ticket treats all engine and native inputs as read-only dependencies.

## Shape

Add `lsp/cubrid.lua`. Neovim's native LSP manager is the single activation/process owner. Convenience setup keeps trusted option validation, file detection, discovery, commands and completion hooks. It enables the standard configuration by default. A simple documented setup opt-out leaves activation to native user/LazyVim configuration. Remove the competing manually started process path.

Support standard cmd, capabilities, on_attach and settings overrides with documented native order. Standard configuration must work without setup when a buffer is already marked cubrid. Preserve complete initializationOptions.cubrid and settings replacements, discovery/doctor, repeated setup, settings during startup, restart, schema reload and manual omnifunc ownership. A stable default root retains one shared client across buffers. User root overrides may intentionally change that scope.

## Acceptance

1. Commit focused failing real headless editor regressions before production changes. Demonstrate the missing standard config and inability to use native config overrides, without mocks replacing Neovim.
2. Exercise normal setup and external/native activation, including native config without setup. Prove normal plugin plus explicit enable produces exactly one actual client. The opt-out starts no client until external enable. No mandatory Blink or nvim-lspconfig dependency is introduced.
3. Preserve all existing editor acceptance behavior, including default and selected extensions, discovery/doctor, owned manual completion, repeated setup, native errors, settings replacement/startup races, restart and bounded owned process cleanup. Standard user command, capabilities, callbacks and settings overrides must reach the actual client/server.
4. Test CUBRID SHOW and optimizer-hint completion through the real task server. Parent supplies the final engine tip/server. Preserve UTF-16 full-token replacement, native unsupported warnings, exact authoring diagnostics, correction clearing and close clearing. The parent independently drives Blink with only its ordinary LSP source enabled.
5. Include lsp/ in the packaged artifact and verify the extracted plugin in isolated configuration/data/cache/state directories. Keep real user config and native inputs unchanged. Test only headless/terminal surfaces on this host.
6. Update help and practical Korean-first/English installation docs with native configuration and LazyVim usage, opt-out semantics, override precedence, tested Neovim version and limits. Update docs/acceptance.md with exact commands/results and artifact evidence. Exercise any lower minimum or mark it unverified.
7. Commit meaningful task changes after rereading the diff and staging only task files. Return red/green evidence, committed tip, exact tests, packaging results and remaining limitations. Parent handles independent review and final cross-repository verification.

## Evidence and constraints

The existing full suite passed before edits. Its log is `/home/vimkim/temp/cubrid-show-hints-606-yszqo6t9/evidence/nvim-baseline.log`. The task engine environment is `/home/vimkim/gh/cubrid-language-tools-show-hints/.venv/bin/cubrid-language-server`. Existing native source, worker and runtime paths remain read-only. Use a fresh CUBRID_TEST_DIR for each run. Work item 606 is maintained by the coordinator.

Use one fresh implementer for this bounded ticket. Local commits are authorized. Integration, push, publication and real user-profile changes require separate authorization. VS Code consumer changes, CSQL session enhancements and formatting are deferred.
