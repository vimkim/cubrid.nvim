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

## Candidate server result

The complete suite passed against server source commit `d5a571eb03d543af1438b85933fcad3aed60f9f0`, which fixes the initialize decoder. Its checkout had advanced to `3efe03b49a037041fe6e667acb990fc8403c3ab0` at the run; the intervening commit changes only its report. The candidate server was `/home/vimkim/temp/cubrid-lsp-enums-venv/bin/cubrid-language-server` using Python 3.14.6. It remains a candidate until integrated separately. The plugin sends Neovim's standard initialize request unchanged.

The tested archive is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/artifacts/cubrid.nvim-alpha.tar.gz`. Its SHA-256 is `1fd0f6b6b059e134b3dd2e9a28640d5075017b3e5d52274c16b89250ca7b2b30`. The installed runtime path is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/candidate-installed-final`. The isolated profile is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/candidate-profile-final`. The command was:

```sh
CUBRID_TEST_SERVER=/home/vimkim/temp/cubrid-lsp-enums-venv/bin/cubrid-language-server \
CUBRID_TEST_DIR=/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/candidate-profile-final \
/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/candidate-installed-final/tests/run.sh
```

The captured output is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/candidate-output-final.txt`. The LSP trace is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim/candidate-profile-final/state/nvim/lsp.log`. To repeat from a new checkout, build and extract the package as above, choose an empty test directory, and set `CUBRID_TEST_SERVER` to the candidate or a server containing its fix.

The installed package passed these checks:

- `.CSQL` detection, default exclusion and explicit opt-in for `.sql`, lexical keyword group, indentation, and buffer-local undo.
- Missing server reporting, retry, and `CUBRID-T1001` with keyword completion when the runtime is missing.
- Native `CUBRID-S1001` and `CUBRID-U1002` diagnostics. The syntax diagnostic started at UTF-16 position line 0, character 13. The unsupported diagnostic started on line 1.
- A completion edit after Korean and emoji text replaced UTF-16 characters 14 through 20, including the suffix after the cursor. The test applied it through `vim.lsp.util.apply_text_edits`.
- A CRLF file was opened, edited, and saved with CRLF bytes. Neovim exposed buffer lines without terminators. Its `didOpen` and full `didChange` wire text contained CRLF in this run.
- Schema availability, failed reload retaining stale metadata, recovery, explicit disable, and native worker settings retained after a schema-only update.
- One client for two nested project files with separate snapshots, per-document reload results, repeated setup, filetype detach and reattach, restart, settings and restart during startup, and close clearing.
- Normal shutdown removed the direct server child while the editor remained alive. A separate Neovim exit recorded direct child PID `3365595`; it was gone after the editor exited. Neovim displayed its bounded shutdown wait. No server or worker process was found in a subsequent host process listing.

The first initialize root was `file:///home/vimkim/gh/cubrid.nvim-alpha`, the editor working directory used for the test. In the separate project test the initialize root was the nested project directory. Neovim used `file://` for the unnamed buffer. The candidate server treated its empty path as the root and found the parent directory's snapshot. The test verified that behavior rather than changing the URI.

The direct-child checks do not establish descendant cleanup after a forced server kill. They also do not establish which signal ended the child during editor exit. The interactive completion menu, lower Neovim versions, and other platforms remain unverified.
