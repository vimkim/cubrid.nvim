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

The original alpha completion test applied the server edit with `vim.lsp.util.apply_text_edits`. It did not test an interactive completion menu selection. The follow-up below adds that test. The cleanup test observes the direct server process and graceful LSP shutdown. It does not prove cleanup of orphaned descendants after a forced server kill. The plugin provides lexical highlighting and basic indentation, not SQL formatting or complete grammar coverage.

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

The direct-child checks do not establish descendant cleanup after a forced server kill. They also do not establish which signal ended the child during editor exit. That original run did not verify the interactive menu. Lower Neovim versions and other platforms remain unverified.

## Completion menu follow-up

The follow-up dispatch was `9cf5bb620efed783ccfa0bee76da814181eccb3d`, based on consumer commit `453c091e102b3d7c6649d37c55983ace06067bd5`. Regression commit `d02adc8` exercised the visible native menu on Neovim 0.12.5. It failed with `expected SELECT '가😀'; SELECT; got SELECT '가😀'; SELECTect`. The server supplied the full UTF-16 range; Neovim's native menu inserted its word only through the request cursor.

The fixed menu uses the CUBRID client's plain single-line `textEdit` range and text. It reports and refuses unsupported response forms, including multiline edits. The actual server returns a multiline edit for an unclosed quoted identifier at end of file. Closed quoted and qualified identifiers are covered by the menu tests. The menu uses only the owned CUBRID client. The previous buffer-local omnifunc is restored on detach if it has not since been changed.

The following archive was built with `scripts/package.sh` and extracted into an empty directory. Its SHA-256 is `fb8e0eb4443d37e960913fe278883251485dd35d5a39d8e05478de971df27b01`.

```sh
scripts/package.sh /home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/artifact/cubrid.nvim-menu-release.tar.gz
tar -xzf /home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/artifact/cubrid.nvim-menu-release.tar.gz -C /home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/installed-release
CUBRID_TEST_SERVER=/home/vimkim/temp/cubrid-lsp-enums-venv/bin/cubrid-language-server \
CUBRID_TEST_DIR=/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/release-profile \
/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/installed-release/tests/run.sh
```

The installed suite passed with server source `d5a571eb03d543af1438b85933fcad3aed60f9f0` and server checkout report tip `3efe03b49a037041fe6e667acb990fc8403c3ab0`. The worker and runtime paths remain those in the host section. Output is `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/release-output.txt`. Use new empty extraction and profile directories when repeating the commands.

The visible menu tests cover Korean and emoji before the range, suffix and no suffix, closed quoted and qualified names, multiple choices, cancellation, cursor position, one undo after repeated selection, and CRLF save. A proxy delays the real server response to test intervening input, overlapping requests, client restart, and a buffer switch. A menu-open edit on another row cancels the menu and preserves that edit. The proxy also supplies two test items with identical labels and different edit starts to verify selection identity. The multiline refusal and omnifunc ownership have separate tests.

The independent `neovim-independent/menu-visible.lua` probe also passed against the extracted archive. Its fresh profile and observed menu are in `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/independent-release/menu-observed.txt`; it recorded `accepted=SELECT '가😀'; SELECT`. The probe used the same headless command as `neovim-independent/run-probe.sh`, with `CUBRID_PLUGIN_ROOT` set to the extracted archive and all XDG paths set under that fresh profile.

To rerun the independent probe with a fresh profile:

```sh
profile=/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/independent-release
mkdir -p "$profile"
CUBRID_TEST_DIR="$profile" \
CUBRID_TEST_SERVER=/home/vimkim/temp/cubrid-lsp-enums-venv/bin/cubrid-language-server \
CUBRID_PLUGIN_ROOT=/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-menu/installed-release \
XDG_CONFIG_HOME="$profile/config" XDG_DATA_HOME="$profile/data" \
XDG_CACHE_HOME="$profile/cache" XDG_STATE_HOME="$profile/state" \
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' \
  -c 'luafile /home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-independent/menu-visible.lua'
```

The test suite does not replay a duplicate accepted `CompleteDone` event. The adapter clears its context before applying the suffix deletion.

The adapter deliberately rejects snippets, insert/replace edits, completion commands, additional edits, resolution-dependent items, multiline text, and multiline ranges. It does not claim complete support for every possible server completion response. A stale refusal after native insertion preserves the current text; it cannot undo an insertion that Neovim has already made. Lower Neovim versions, other platforms, and forced descendant cleanup remain unverified.

## Deferred menu ownership follow-up

The dispatch was `e1cb28dd10990356c5bc6b9ec6f41af9d5332a6b`, descended from `b02e13e0a5aa8996bef435f91f4f3d7ad8cdd7cb`. Regression commit `ffaedbd` reproduced the foreign menu cancellation in Neovim 0.12.5. Its fresh profile recorded `foreign-before` with `pum_visible = 1`, `foreign-after` with `pum_visible = 0`, and `FAIL foreign menu cancelled after filetype detach`, exit 5. The output is in `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-ownership/red/menu-observed.txt`.

Commit `6673f8f3a5d1c16650410baee412bfc783a7069e` checks every displayed item's existing CUBRID epoch, generation, and choice identity before cancelling. Fresh headless tests preserved a replacement foreign menu and a mixed menu, and cancelled the old owned menu after detach. The profile records are in `neovim-ownership/final-profile/menu-observed.txt`. The existing overlapping-request test covers a newer request and completion, but does not establish that its popup was already visible before the old scheduled callback ran.

The archive was built from commit `6673f8f3a5d1c16650410baee412bfc783a7069e`. Its SHA-256 is `94ea53e891e261693f1c1472cb8929cb8dbb3190fbb3c18ee55f110ef140f824`. The extracted package matched every packaged source path using `diff -qr`. The candidate server and read-only worker and runtime inputs are the same as in the candidate server result above.

```sh
base=/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-ownership
scripts/package.sh "$base/artifact/cubrid.nvim-final.tar.gz"
mkdir -p "$base/final-installed" "$base/final-profile"
tar -xzf "$base/artifact/cubrid.nvim-final.tar.gz" -C "$base/final-installed"
CUBRID_TEST_SERVER=/home/vimkim/temp/cubrid-lsp-enums-venv/bin/cubrid-language-server \
CUBRID_TEST_DIR="$base/final-profile" "$base/final-installed/tests/run.sh"
```

Use new empty extraction and profile directories to repeat the test. The full suite output is `neovim-ownership/final-output.txt`. The independent `menu-visible.lua` probe used the final extracted package and a fresh XDG profile. It recorded `accepted=SELECT '가😀'; SELECT` and `PASS menu suffix replacement` in `neovim-ownership/final-independent/menu-observed.txt`.
