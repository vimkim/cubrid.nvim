# Neovim editor alpha acceptance

## Baselines and host

The consumer dispatch was `3b341bf57e7ebc90b65bbcdfe20e889b30d8b79a` on `alpha/editor`. The original engine baseline was `3bb70e492efe7bcb7de58a801281f7a088a9c39e`. The host ran Neovim 0.12.5 and Python 3.14.0. No lower Neovim version has been tested.

The server command was `/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server`. The native inputs were `/home/vimkim/gh/cubrid-language-tools/native/parser-worker/build/parser-worker` and `/home/vimkim/.cub/install/develop/debug`. These inputs were read-only.

## Reproduce the package test

```sh
scripts/package.sh /tmp/cubrid.nvim-alpha.tar.gz
mkdir -p /tmp/cubrid-nvim-installed /tmp/cubrid-nvim-test
tar -xzf /tmp/cubrid.nvim-alpha.tar.gz -C /tmp/cubrid-nvim-installed
CUBRID_TEST_DIR=/tmp/cubrid-nvim-test /tmp/cubrid-nvim-installed/tests/run.sh
```

Use fresh empty directories. The script sets isolated XDG config, data, cache, and state paths and invokes `nvim --headless -u NONE`. Its server, worker, and runtime paths are host-specific. Missing prerequisites fail the test. The package contains both READMEs, LICENSE, `lua/`, `ftplugin/`, `indent/`, `syntax/`, `doc/`, and `tests/`.

## Dispatch baseline result

The extracted package passes file detection, SQL opt-in, lexical indentation, buffer-local undo, and invalid native-pair checks in `tests/smoke.lua`. The full suite fails at initialization against the dispatch engine. The actual initialize request is in `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/initialize.json`. The server responded with JSON-RPC error `-32602`, `Invalid parameters for initialize`. The Neovim trace is in `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/red/state/nvim/lsp.log`. The extracted package run is in `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/installed-v2-red.txt`.

A temporary diagnostic probe removed optional Neovim capability and trace fields. With that probe, the real server returned native syntax and unsupported diagnostics, completion, and reload results. The probe is not in the package and its results are not final acceptance. The probe's wire log showed CRLF in `didOpen` and `didChange` for a real CRLF file on this Neovim version. Neovim buffer lines are exposed without line terminators. The edited file retained CRLF on disk. The remaining editor and native criteria require a rerun against a server that accepts the unmodified Neovim initialize request.

## Limits

The completion test applies the server's text edit using Neovim's public `vim.lsp.util.apply_text_edits` API. It does not test an interactive completion menu selection. The cleanup test observes the direct server process and graceful LSP shutdown. It does not prove cleanup of orphaned descendants after a forced server kill. The plugin provides lexical highlighting and basic indentation, not SQL formatting or complete grammar coverage.
