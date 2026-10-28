# Neovim editor alpha

Build a locally installable runtime-path plugin that uses Neovim's built-in LSP and the existing CUBRID stdio server.
Engine baseline is `3bb70e492efe7bcb7de58a801281f7a088a9c39e` in `/home/vimkim/gh/cubrid-language-tools`.
The canonical task acceptance is `/home/vimkim/gh/cubrid-language-tools-editor-alpha/docs/tickets/editor-alpha-contract.md`.
The coordinator supplies a selected design and exact dispatch commit before implementation.

The plugin owns `.csql` detection, opt-in `.sql`, native lexical highlighting, buffer-local indentation, trusted Lua setup, native client lifecycle, schema reload commands, help, packaging and editor tests.
The engine owns every completion and diagnostic decision.
Pass complete effective settings replacements and preserve original UTF-16 edit positions.
Do not assume an empty diagnostics list certifies SQL outside qualified native coverage.

Use the real `nvim --headless` with isolated user configuration and data directories.
The installed Neovim is 0.12.5. Exercise any lower declared minimum or label it unverified.
Do not add a dependency on nvim-lspconfig merely to start the existing server.

Test an installed runtime-path artifact, including `.csql` case handling, generic `.sql` exclusion, highlighting/indentation, missing server/runtime, complete settings updates, schema reload failure/recovery, Unicode/CRLF edits, native diagnostics, close clearing, multiple buffers/roots, repeated setup, restart and owned process cleanup.
Record reusable commands, actual editor results, exact versions, artifact inventory, checks, baseline and limitations in `docs/acceptance.md`.
Keep the user's real Neovim configuration and all native source/build/runtime inputs unchanged.
Local source and artifact creation is authorized. Integration and publication retain their approval gates.
