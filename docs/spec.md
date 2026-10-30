# Neovim consumer specification

The runtime-path plugin uses Neovim's built-in LSP and the separately installed [shared CUBRID server](https://github.com/vimkim/cubrid-language-tools). Current setup is in the [English README](../README.en.md) and [Korean README](../README.md). The original alpha design and dispatch are historical records. Each new ticket supplies its exact baseline and acceptance contract.

The shared engine owns [qualified coverage](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/coverage.en.md). Upgrade its core and matching worker, manifest, and runtime together using the [installation guide](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md). Completion and authoring warnings do not imply native validity. [Acceptance evidence](acceptance.md#current-status-and-evidence-scope) records which engine each editor check used.

The plugin owns default `.csql` and `.sql` detection with independent selection via `file_extensions`, native lexical highlighting, buffer-local indentation, trusted Lua setup, native client lifecycle, schema reload commands, help, packaging and editor tests.
The engine owns every completion and diagnostic decision.
Pass complete effective settings replacements and preserve original UTF-16 edit positions.
Do not assume an empty diagnostics list certifies SQL outside qualified native coverage.

Use the real `nvim --headless` with isolated user configuration and data directories.
The installed Neovim is 0.12.5. Exercise any lower declared minimum or label it unverified.
Do not add a dependency on nvim-lspconfig merely to start the existing server.

Test an installed runtime-path artifact, including `.csql` case handling, both extension defaults and independent selection, highlighting/indentation, missing server/runtime, complete settings updates, schema reload failure/recovery, Unicode/CRLF edits, native diagnostics, close clearing, multiple buffers/roots, repeated setup, restart and owned process cleanup.
Record reusable commands, actual editor results, exact versions, artifact inventory, checks, baseline and limitations in `docs/acceptance.md`.
Keep the user's real Neovim configuration and all native source/build/runtime inputs unchanged.
Local source and artifact creation is authorized. Integration and publication retain their approval gates.
