# Neovim editor alpha acceptance

## Current status and evidence scope

This report preserves results at their recorded plugin and engine commits. Historical commands and local paths describe those runs. They are not a claim that those temporary environments or published archives contain current main.

The current [core coverage reference](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/coverage.en.md) describes `bounded-query-dml-schema-engineer-ordered-v4`, at core commit `057e41b0c02d85d09905301f6bfccbb7ed0b8965`. Using that coverage requires the matching core, worker, manifest, and qualified runtime described in the [installation guide](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md). The schema-connection checks below verify catalog acquisition and completion. They do not upgrade the existing PATH installation or native assets, or qualify additional v4 syntax coverage.

The evidence has separate scopes:

- [Copilot warning coexistence](#copilot-warning-coexistence) verifies the exact `copilot` client-name exception with real stdio clients on current native LSP ownership. It does not exercise the GitHub Copilot AI service.
- [Dependency warnings, N631](dependency-warnings-ticket.md) verifies WARN install guidance, prerequisite discovery, completion during native unavailability, and recovery on Neovim 0.12.5 with core `ad9d9434f6f8d74b8c44d9cadba0faf2362e6606`. Its focused native check uses a matching v4 worker. It does not requalify the full native coverage matrix.
- [Packaged Blink and LazyVim verification](#independent-packaged-blink-and-lazyvim-verification) used plugin `12feab90dfaae8ce4ca49d45ed8dec6cc875dea7` runtime files and engine `8b1226c8f10686eb29d13d86cdda793df71d6645`. It verified SHOW and hint authoring in isolated profiles with the earlier native inputs. It did not verify v4 or the full personal profile.
- [Approved SHOW/hint integration](#approved-showhint-integration-after-concurrent-ci) records the extracted portable and native suite results for that integration. Its test totals and unchanged-native-coverage statement refer to that earlier engine.
- The [portable workflow](../.github/workflows/ci.yml) pins core `6be5d558efce6e5045d8f7122d4532e4e975192f` for schema connections, including bounded stdout publication. It does not establish v4 native success. Earlier portable results retain their recorded engine identity.
- Older personal-profile checks remain evidence only for their recorded configurations and commits. No personal Neovim profile was changed or retested for this documentation update.

Neovim 0.12.5 on Linux remains the tested platform. Other versions and platforms require their own checks. Current configuration instructions are in the [English README](../README.en.md) and [Korean README](../README.md).

## Copilot warning coexistence

On 2026-10-31, the existing test and fix commits rebased onto `main` commit `8160c40944a0be294fd9f741ae9ef321d85830fd`. Test-first commit `361c16f37fab82d8714d2c9acb0fcf8f7be9958a` changes only `tests/sql-defaults.lua`. Its runtime matches that main commit. Fix commit `69269b439ed44c449709e9bd99310e0281bf7f74` preserves native client ownership and excludes the exact name `copilot` from overlap warnings.

The test starts the real shared stdio server as a client named `copilot`. It checks a client attached before setup, a later attachment, and preservation across `cubrid.restart()`. The existing assertions still verify warnings for other clients, actionable warning text, deduplication, and preservation of those clients across restart.

The evidence directory is `/home/vimkim/temp/cubrid-copilot-657-93AzXBqC`. An archive of the test-first commit failed with exit 1 at `tests/sql-defaults.lua:25`, `preexisting copilot client is quiet`. The extracted fixed package passed with exit 0 and printed `SQL defaults and conflicts passed`. The focused driver uses `nvim --headless -u NONE`, prepends the selected plugin runtime, and isolates XDG configuration, data, cache, and state. Its exact editor invocation is:

```sh
timeout --kill-after=5s 120s /home/linuxbrew/.linuxbrew/bin/nvim --headless -u NONE \
	--cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT); assert(vim.opt.runtimepath:get()[1] == vim.env.CUBRID_PLUGIN_ROOT)' \
	-l "$CUBRID_PLUGIN_ROOT/tests/sql-defaults.lua"
```

The commands below produced the red, focused green, and package checks before local main integration. `run-focused.sh` in the evidence directory contains the complete environment setup and writes separate stdout, stderr, and exit receipts. Its output directories must be fresh when repeating a run.

```sh
evidence=/home/vimkim/temp/cubrid-copilot-657-93AzXBqC
git archive 361c16f > "$evidence/test-first.tar"
mkdir "$evidence/red-plugin"
tar -xf "$evidence/test-first.tar" -C "$evidence/red-plugin"
git diff --exit-code main 361c16f -- lua lsp ftplugin indent syntax \
	> "$evidence/red-runtime-vs-main.diff"
sh "$evidence/run-focused.sh" "$evidence/red-plugin" "$evidence/red"
sh scripts/package.sh "$evidence/cubrid.nvim.tar.gz"
python3 scripts/verify-package.py "$evidence/cubrid.nvim.tar.gz" \
	> "$evidence/inventory.txt" 2> "$evidence/package-verification.log"
mkdir "$evidence/extracted"
tar -xzf "$evidence/cubrid.nvim.tar.gz" -C "$evidence/extracted"
sh "$evidence/run-focused.sh" "$evidence/extracted" "$evidence/green"
PATH=/home/linuxbrew/.linuxbrew/bin:/home/vimkim/.local/bin:$PATH \
CUBRID_TEST_SERVER=/home/vimkim/.local/bin/cubrid-language-server \
CUBRID_TEST_EXPORTER=/home/vimkim/.local/bin/cubrid-schema \
CUBRID_TEST_NVIM_VERSION=0.12.5 CUBRID_TEST_DIR="$evidence/portable" \
	sh "$evidence/extracted/tests/run-portable.sh" > "$evidence/portable.log" 2>&1
```

The package verifier matched all 53 archive files to the tracked source inventory and current file contents. The archive SHA-256 is `752a6e32b585fb73488a5a645a575fdef10ea6df13f9def832f3b04a2bd9fb95`. The archive excludes this acceptance report. The complete extracted portable suite passed with exit 0: all 25 regular cases, four schema flows, and the visible command terminal test passed. The direct-child exit receipt also passed.

The portable result and per-case receipts are under `portable/`, with combined output in `portable.log`. `checks.json` summarizes the receipt values. The focused receipts are `red/result.txt` and `green/result.txt`. Their stderr logs contain the assertion and success message. `red-runtime-vs-main.diff` is empty. The package verifier passed again after the acceptance update, with output in `inventory-final.txt` and `package-verification-final.log`.

The host runs Neovim 0.12.5 with LuaJIT 2.1.1788856981. The server reports `cubrid-language-server 0.1.0.dev0` and uses Python 3.14.0. The server and exporter resolve under `/home/vimkim/.local/share/uv/tools/cubrid-language-tools/bin`. All 22 installed package files match clean engine checkout `f04fafda88ca8ba8ccd8b87760ac51d2917f3b60`. `identity.json` records executable paths, hashes, versions, the installation origin, and the installed package hashes.

This check verifies the warning policy through real Neovim LSP attachment. It does not use the GitHub Copilot AI service. The portable suite does not qualify native parser success. The full native suite, other Neovim versions, other operating systems, and the personal Neovim profile were not tested. The shared engine, native inputs, and personal configuration were unchanged.

## Schema connections, N636

The task starts at plugin `44dfe90` on `schema/csql-completion`. The first public interface check failed before implementation because `schema_prompt` was unknown. The focused checks use Neovim 0.12.5, an isolated XDG profile, the shared task's editable server and `cubrid-schema`, and a controlled CSQL executable. They do not connect to a database or change a personal profile.

The headless flow checks table and column completion after connect, refresh, stale refresh failure, failed switching, and offline restoration. It checks inline and separately entered credentials, input history, private directory and file modes, complete native settings, two clients with distinct roots, an obsolete export, setup replacement, client exit with a replaced native `on_exit`, an obsolete prompt, a rejected clear barrier, and setup replacement with a missing offline snapshot. The last case first failed because live names survived replacement. It passes after setup waits for a clear reload before restoring the offline setting. Separate cases check opt-in prompting, configured project metadata, and CSQL child cleanup on Neovim exit. The fake exporter case checks the original stdin request; the real exporter case runs the shared CLI with a controlled CSQL executable. Neither substitutes for a live database check.

Run the portable suite with a compatible shared server and exporter in the same virtual environment. Use an empty test directory:

```sh
CUBRID_TEST_DIR=/tmp/cubrid-nvim-portable \
CUBRID_TEST_SERVER=/absolute/path/to/cubrid-language-server \
CUBRID_TEST_EXPORTER=/absolute/path/to/cubrid-schema \
tests/run-portable.sh
```

The extracted package passed the complete portable suite in `/tmp/cubrid-nvim-schema-package-v6-check` on Neovim 0.12.5. The package was `/tmp/cubrid-nvim-schema-package-v6.tar.gz`, SHA-256 `a2711ea341729517b09e4f2b6b0543ea0171dc217d70fd12d4b75f9842c19e49`. The editable core tree was at `1beb47a`, whose production code matches `c2fe7c63e214fea42fdc2f8ee047085b4173c3d8`. Package inventory verification matched all 51 files to the task checkout. The setup restoration regression failed before the clear barrier and passed after it. A fixture PID publication race and an asynchronous status assertion were corrected during package verification.

The suite requires an exporter and fails when it is missing. The workflow pins the local core commit `6be5d558efce6e5045d8f7122d4532e4e975192f`, which includes `cubrid-schema`, the `schemaConfigured` reload result, and bounded stdout publication. The core commit must be published before the plugin workflow can fetch it. Earlier Neovim versions and non-POSIX process cleanup are unverified.

### Coordinator verification with the corrected exporter

The coordinator reran the source-matched extracted archive against corrected core production commit `6be5d558efce6e5045d8f7122d4532e4e975192f`. All 25 portable cases and four schema flows passed. The archive is `/tmp/cubrid-schema-implementation-EMmkLi/final-plugin/cubrid.nvim.tar.gz`, SHA-256 `a2711ea341729517b09e4f2b6b0543ea0171dc217d70fd12d4b75f9842c19e49`. Its 51 packaged files match the checkout. Per-case receipts are under `final-plugin/checks`, with the complete output in `final-plugin/checks.log`. Only the CI dependency pin and this acceptance record changed after runtime commit `f5018d73ede2ac279cdab3bb7c6fa11c8477eb15`.

An independent read-only review passed the actual headless exporter/LSP flow. A separate probe delayed an old connection's publish-reload callback until after another connection was ready. Releasing it preserved the second connection's names. The rerunnable probe and result are `/tmp/cubrid-schema-implementation-EMmkLi/review-nvim/run-reload-race.sh` and `review-nvim/reload-race/result`.

The complete real chain also passed on Neovim 0.12.5 and a dedicated CUBRID `11.5.0.2635 debug_gcc` client/server environment. Native command and password prompts drove the actual plugin, LSP, exporter, and CSQL binary. DBA received `schema_people`, `schema_people_view`, and the expected alias columns. `SCHEMA_READER` received only its granted `DBA.schema_people` and columns. Switch removed the old snapshot. Disconnect removed both qualified and unqualified live names and the private snapshot directory. File mode was 0600 and directory mode was 0700. The editor buffer's DDL left the fixture intact.

Rerun instructions and the isolated probe are `/tmp/cubrid-schema-implementation-EMmkLi/native-editor-verify/README.md`. The final observed result is `native-editor-verify/native-flow-run-v20_1igu/result.json`. The first coordinator probe incorrectly read a status notification before its scheduled callback ran. A two-prompt control ruled out input handling; waiting for the new status notification corrected the probe. This was a test-driver issue. Native syntax diagnostics were unavailable in that disposable environment because no parser worker was configured. The verdict covers schema acquisition and completion.

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

## SQL defaults ticket

The selected dispatch is `/home/vimkim/temp/cubrid-nvim-sql-defaults-20261029/decision.md`. The baseline is `4b4c4d9e486f0b02c146d21cb8452b3c45bad754`. The historical central editor contract path in `docs/dispatch.md` was absent in this checkout environment.

On Neovim 0.12.5, `tests/sql-defaults.lua` failed at `SQL enabled by default` against the baseline, then passed after implementation. It exercises default detection and casing, explicit opt-out, invalid setup, pre-setup SQL, a competing autocmd and exact filename override, warning severity and deduplication, configuration at delivery, buffer wipe, and actual foreign LSP clients before and after setup. The foreign client remains attached across an owned restart. `tests/missing-default.lua` exercises a missing PATH executable, one notice per failed attempt, lexical settings, PATH repair and `:CubridRestart`. `tests/missing.lua` covers an explicit missing path and recovery with the real server.

```sh
CUBRID_TEST_DIR=/tmp/cubrid-sql-full \
CUBRID_TEST_SERVER=/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server \
  tests/run.sh
mkdir -p /tmp/cubrid-sql-artifact-final3/extracted
scripts/package.sh /tmp/cubrid-sql-artifact-final3/cubrid.nvim.tar.gz
tar -xzf /tmp/cubrid-sql-artifact-final3/cubrid.nvim.tar.gz -C /tmp/cubrid-sql-artifact-final3/extracted
CUBRID_TEST_DIR=/tmp/cubrid-sql-artifact-final3/run \
CUBRID_TEST_SERVER=/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server \
  /tmp/cubrid-sql-artifact-final3/extracted/tests/run.sh
```

Use fresh disposable directories on repetition. Output from the extracted package is `/tmp/cubrid-sql-artifact-final3/test.log`. The suite uses the existing read-only native worker and runtime. Only observed detection events and attached clients are reported; silent `noautocmd` overrides are outside the contract. Lower Neovim versions and other platforms were not tested.

Independent review repeated `smoke.lua`, `sql-defaults.lua`, and `missing-default.lua` from the extracted package with a fresh profile under `/home/vimkim/temp/cubrid-nvim-sql-defaults-20261029/parent-tests`. All passed. Every extracted file matched its source counterpart. The archive SHA-256 is `dc1ca38e1e52f1067f13429f14c1c7da3b7bb7076674639443c8634ee2c30b87`.

The personal Neovim configuration ticket is commit `30717568d603f9fe3358eaeacdfd89e242cab456`. A copied LazyVim profile loaded plugin commit `ac9cf68b7d910fa83eb883dccb7476de796a5d20` from its task checkout. Both extensions used `cubrid`, shared one initialized client, received `CUBRID-S1001`, and returned `SELECT` completion. Iron retained the `csql.sh` definition for both filetypes without invoking it. A manual `.sql` filetype change produced one WARN with the `sql=false` advice. The check and output are `/home/vimkim/temp/cubrid-nvim-sql-defaults-20261029/combined/headless.lua` and `headless.log` in that directory.

This copied profile isolated writable state and disabled Tree-sitter and Mason to prevent unrelated automatic installations. Their interaction with the plugin is not established by this check. The scoped independent comment review found no issues. Main integration and activation in the live configuration remain separate from these pre-integration checks.

## SQL defaults integration

After explicit approval, both task branches rebased without changes and fast-forwarded into local `main`. The plugin tip was `0f60ec90e9d79799a565d307f7761a543c52b31f`, and the personal configuration tip was `30717568d603f9fe3358eaeacdfd89e242cab456`. Fresh pre-merge smoke, SQL conflict, missing-server recovery, and configuration checks passed.

`bash /home/vimkim/temp/cubrid-nvim-sql-defaults-20261029/merge/live/run.sh` passed against the actual `/home/vimkim/.config/nvim/init.lua` and plugin module at `/home/vimkim/gh/cubrid.nvim/lua/cubrid/init.lua`. Both extensions received native diagnostics and `SELECT` completion through one initialized client. Iron retained both REPL definitions. An observed `.sql` filetype conflict produced one WARN with the opt-out advice. The script uses isolated data, cache, state, and lockfile paths and disables automatic plugin installation, Tree-sitter, and Mason. Its output is `headless.log` in that directory. The existing unrelated `lazyvim.json` edit retained its exact bytes and unstaged status after integration and startup. No remote publication was part of this approval.

The final archive SHA-256 is `dc1ca38e1e52f1067f13429f14c1c7da3b7bb7076674639443c8634ee2c30b87`. The archive contains README files, license, runtime files, help and tests. Historical `docs/design.md` and `docs/dispatch.md` describe the earlier alpha and are superseded for this ticket by the selected dispatch above.

## Explicit file extensions

The selected dispatch is `/home/vimkim/temp/cubrid-nvim-extension-options-20261029/dispatch.md`, based on plugin commit `9a8b068cf67574022d6841c41e67b834f3526bc4`. The earlier `sql` option and its examples in this acceptance history are superseded by `file_extensions`.

On Neovim 0.12.5, `tests/file-extensions.lua` failed against the baseline with `unknown cubrid option: file_extensions` and passed after implementation. It checks both defaults, each suffix alone, neither, mixed-case filenames, replacement and default reset, existing-buffer retention, malformed and duplicate lists, unsupported suffixes, and migration errors retaining the last valid selection. `tests/sql-defaults.lua` checks conflicts for enabled and disabled suffixes, scheduled delivery against current settings, deduplication, foreign clients and owned restart. The suite also exercises missing-server recovery and completion.

```sh
base=/home/vimkim/temp/cubrid-nvim-extension-options-20261029
server=/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server
CUBRID_TEST_SERVER="$server" CUBRID_TEST_DIR="$base/source-final" tests/run.sh
scripts/package.sh "$base/final.tar.gz"
mkdir -p "$base/final-extracted"
tar -xzf "$base/final.tar.gz" -C "$base/final-extracted"
CUBRID_TEST_SERVER="$server" CUBRID_TEST_DIR="$base/final-profile" "$base/final-extracted/tests/run.sh"
```

Both full suites passed using separate isolated profiles and the existing read-only server, worker and runtime. Logs are `red.log`, `green.log`, `source-final.log`, and `final.log` under the dispatch directory. The extracted archive contains both READMEs, license, runtime files, help and tests. Its SHA-256 is `92e9f1792bc6e3b6b69b7615d471b0b4cfce2df386b14a98a08d7011c27f9594`. Use fresh profile and extraction directories to repeat these commands. Only observed filetype and client events are covered; silent `noautocmd` overrides, other platforms, and lower Neovim versions were not tested. The personal config migration is commit `90957f7` in its isolated worktree; combined and live configuration checks are separate.

Independent review repeated the extracted `file-extensions.lua` and `sql-defaults.lua` tests with a fresh profile under `verification/artifact-profile` in the dispatch directory. Both passed, and all 27 extracted files matched the source. The scoped comment review found no issues.

Both branches rebased without changes and fast-forwarded into local `main` under the existing integration approval. The plugin implementation is `878db420df273212604997f4f66568ec22d3c0de`, and the personal configuration is `90957f7d04744da5c7bd8a0af0a6179d15bae86d`. The live configuration now explicitly selects `{ ".sql", ".csql" }`.

`bash /home/vimkim/temp/cubrid-nvim-extension-options-20261029/verification/run.sh` passed against the actual user configuration and merged plugin. It checked the configured suffix list, both extensions, native diagnostics, `SELECT` completion, one initialized CUBRID client, Iron definitions, and one conflict WARN naming `file_extensions`. Output is `verification/live/headless.log` in the dispatch directory. The script isolates writable state and disables automatic installation, Tree-sitter, and Mason. The unrelated `lazyvim.json` edit retained its exact bytes and unstaged status. Remote publication was outside this approval.

## Installed discovery and doctor

On 2026-10-29, Neovim 0.12.5 on Linux used the PATH server at `/home/vimkim/.local/bin/cubrid-language-server`. Its canonical executable belonged to the local `just sync` installation, and its package metadata recorded `/home/vimkim/gh/cubrid-language-tools`. The adjacent native manifest selected `/home/vimkim/.cub/install/develop/debug`. The server and native inputs were read-only.

Before implementation, `tests/discovery-doctor.lua` failed because `require('cubrid').doctor` did not exist. The later focused run passed and observed `CUBRID-S1001` from both the private probe and a normal SQL buffer. It also tested restart, explicit native paths, replacing a broken native pair with discovery, and keeping the active native paths when PATH changes. The failure-case test covered escaped source paths, a prefix containing glob characters, invalid and remote URLs, malformed metadata, ambiguous installations, a missing worker, manifest, or runtime, server exit, and a timeout. The timeout fixture checked that its server PID exited. The display test exercised `:CubridDoctor` and `:checkhealth cubrid`.

The source suite passed with a fresh directory:

```sh
CUBRID_TEST_DIR=/home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final-source \
CUBRID_TEST_SERVER=/home/vimkim/.local/bin/cubrid-language-server \
PATH=/home/vimkim/.local/bin:$PATH timeout 240 sh tests/run.sh
```

The extracted package suite used these commands:

```sh
scripts/package.sh /home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final4.tar.gz
mkdir -p /home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final4-extract
tar xzf /home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final4.tar.gz -C /home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final4-extract
CUBRID_TEST_DIR=/home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final4-installed \
CUBRID_TEST_SERVER=/home/vimkim/.local/bin/cubrid-language-server \
PATH=/home/vimkim/.local/bin:$PATH timeout 240 sh /home/vimkim/temp/cubrid-nvim-discovery-601/implementation/final4-extract/tests/run.sh
```

The archive SHA-256 is `10af15d740363fcc600779de19b5d2c0700bbee383f5e7105b71a7c748f5ee5e`. Logs and the failure-before output are under `/home/vimkim/temp/cubrid-nvim-discovery-601/implementation`. Use fresh test and extraction directories when repeating the commands. Other operating systems, Neovim versions, and wheel or index installations were not tested. The private probe tests one fixed syntax error; it does not establish complete SQL coverage. The timeout fixture verifies its direct server PID. A separate successful-probe check recorded the server and native worker PIDs and confirmed that both exited. Its script and log are `/home/vimkim/temp/cubrid-nvim-discovery-601/root-review/verify.lua` and `/home/vimkim/temp/cubrid-nvim-discovery-601/root-review/final4.log`. The separate Neovim configuration change was verified in a headless copy and committed as `a872ae2` in its own checkout.

After explicit user approval, both task branches rebased onto their current local `main` without changes and merged by fast-forward. The plugin implementation is `90bd8994c349903779b8839dc7bf99e38ace0a06`. The configuration is `a872ae2e7295323cafbc01cf5f094e3beab0e484`, which removes the three explicit CLI and runtime paths while retaining the local plugin checkout and extension selection.

`bash /home/vimkim/temp/cubrid-nvim-discovery-601/integration/run-live.sh` verifies the actual configuration and merged plugin through headless Neovim. Its log is `integration/live/headless.log` under that directory. Both `.sql` and `.csql` passed filetype detection, one initialized CUBRID client, canonical PATH executable selection, native `CUBRID-S1001` diagnostics, and `SELECT` completion. `:CubridDoctor` and `:checkhealth cubrid` passed with the ordinary client active. The check observed the ordinary server and native worker PIDs and confirmed that both exited after graceful shutdown. It reads the real configuration and installed plugins with isolated cache and state, and disables automatic installation, update checking, Tree-sitter, and Mason.

The unrelated `lazyvim.json` edit was temporarily stashed during the clean-destination merge, restored, and compared byte-for-byte against its pre-merge copy. It remains unstaged. The temporary preservation stash was dropped after verification. No remote publication was included in this approval.

Live LazyVim startup also generated `doc/tags` in the local plugin checkout. The narrow `/doc/tags` ignore rule keeps this disposable help index out of source control. The generated index is preserved in the primary checkout.

## Portable package CI

The CI implementation starts from `b5c0c6483583ca5d609169cd1b52336040e1292f`. The official Neovim 0.12.5 Linux x86-64 release archive has SHA-256 `bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875`. The release metadata and the downloaded archive matched. The downloaded binary ran on this host.

The package verifier compared all 28 archive files with the checkout. The extracted portable suite passed with Python 3.10.6 and a real language server built from core commit `2a8842c45c4fb219e322afd731c27937a107324f`. The full extracted suite also passed with the existing local server, worker and runtime, including `integration.lua` and `startup.lua`. A missing server, a nonexistent server, an unexpected Neovim version and a changed archive member each produced a failure. Receipts and logs are under `/home/vimkim/temp/cubrid-editor-hardening-c57_w98j/evidence/neovim-ci`.

To repeat the extracted portable check, use a fresh output directory and an absolute server path.

```sh
out=$(mktemp -d)
scripts/package.sh "$out/plugin.tar.gz"
python3 scripts/verify-package.py "$out/plugin.tar.gz" > "$out/inventory.txt"
mkdir "$out/plugin"
tar -xzf "$out/plugin.tar.gz" -C "$out/plugin"
CUBRID_TEST_SERVER=/absolute/path/to/cubrid-language-server \
CUBRID_TEST_NVIM_VERSION=0.12.5 CUBRID_TEST_DIR="$out/results" \
  "$out/plugin/tests/run-portable.sh"
```

`tests/run.sh` also runs the native cases and requires the local qualified worker and runtime. Hosted CI runs only the portable suite, including the missing-runtime diagnostic. Native parser success, other platforms and lower Neovim versions are outside its scope. The workflow had not run on GitHub at the time of this check.

### Timeout escalation

Both test runners now send SIGKILL five seconds after the 120-second deadline if Neovim ignores SIGTERM. A short process-group control reproduced the hang on `bf368ad` and passed after the change. Its script and red and green receipts are in `/home/vimkim/temp/cubrid-editor-hardening-c57_w98j/neovim-deadline-fix`. The control scales both intervals to 0.2 seconds and uses an owned TERM-resistant Python process. It does not establish cleanup of descendants that leave the process group.

The rebuilt archive passed the 28-file source comparison and its extracted headless smoke test. Its SHA-256 is `70f972af4cb1295e738c0203b1778449b1bd318a84cfa5eb434cd5aa818fd5e6`. The full portable and native suites were not repeated for this flag-only change; their previous results are recorded above.

## Post-rebase package qualification

On 2026-10-29, the rebased package verifier matched 34 archive files to the checkout. The extracted package passed 17 portable cases on official Neovim 0.12.5 with the server built from core `2a8842c45c4fb219e322afd731c27937a107324f`. The full extracted suite passed the same 17 cases with the local server and four native cases using the qualified worker and runtime. The portable discovery failure cases use disposable fixtures. The native discovery and doctor display cases require the local server installation metadata and native pair. Hosted CI runs the portable cases only and does not establish native parser success.

Receipts and the source-matched archive are in `/home/vimkim/temp/cubrid-editor-hardening-c57_w98j/integration-neovim`. To repeat the full run, use a fresh output directory and put the official Neovim and local server directories on `PATH`:

```sh
PATH=/path/to/nvim/bin:/home/vimkim/gh/cubrid-language-tools/.venv/bin:$PATH \
CUBRID_TEST_SERVER=/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server \
CUBRID_TEST_NVIM_VERSION=0.12.5 CUBRID_TEST_DIR=/absolute/fresh/output \
  /absolute/extracted/plugin/tests/run.sh
```

## Standard native LSP configuration and SHOW/hint authoring

The bounded ticket starts at dispatch `e8656a8865657df2d88c3895f60e17a833539cd7` on `feat/standard-lsp-config` in `/home/vimkim/gh/cubrid.nvim-standard-lsp`. The shared engine remains read-only for this consumer ticket. The final integration server is `/home/vimkim/gh/cubrid-language-tools-show-hints/.venv/bin/cubrid-language-server`, engine commit `38733ed3485b9065802bc768c19e3e03af60c88a`. Native checks use `/home/vimkim/gh/cubrid-language-tools/native/parser-worker/build/parser-worker` and `/home/vimkim/.cub/install/develop/debug` without changing either input.

Commit `e13f319` records the failing public headless regression before production edits. Its three isolated runs fail because `lsp/cubrid.lua` is missing, setup plus native enable creates competing clients, and `auto_start` is rejected. Logs are `/home/vimkim/temp/cubrid-standard-lsp-evidence/red-native.log`, `red-setup.log`, and `red-optout.log`. The coordinator independently reproduced these failures.

The implementation removes the manually started CUBRID session. The native manager owns activation, attachment, and process shutdown. `setup()` enables the native configuration by default. `auto_start=false` leaves activation external. The default root stays fixed, while explicit native root callbacks may create separate clients. Completion hooks use editor events so a user `on_attach` remains effective. The dedicated doctor probe remains separate from ordinary buffer activation.

The focused acceptance checks exercise these behaviors through real Neovim and the real server:

- `tests/native-config.lua` covers configuration without setup, ordinary setup plus explicit enable, opt-out, invalid opt-out validation, native command/capability/callback/settings overrides, one client across a directory change, repeated enable, actual schema responses, and native disable. Its final assertion includes clients still initializing, after both documents and a real server response.
- `tests/native-settings.lua` uses `tests/record-server.py` to record and forward actual framed traffic. It holds initialization until the test replaces setup options. The initialize message contains complete settings and the native capability override. The first configuration notification contains the newest settings, without removed snapshot and timeout fields. A running replacement removes the native pair, and actual diagnostics change from `CUBRID-S1001` to `CUBRID-T1001`.
- `tests/native-roots.lua` observes two clients only after an explicit root callback selects distinct directories. Restart replaces both clients, and native disable stops both.
- `tests/show-hints.lua` applies real SHOW and hint completion edits, including a hint token after an emoji. It checks `CUBRID-A1001` warning severity/category and exact UTF-16 range 17 through 22 for `BOGUS`. Correcting the hint clears the authoring warning while `CUBRID-U1002` remains. A clean supported statement clears diagnostics, and closing a warning-bearing document clears its diagnostics.
- The existing full suite continues to cover lexical support, extension selection, all manual completion/menu ownership cases, discovery/doctor success and failure, missing runtime/server recovery, schema replacement and reload, startup/restart races, per-document metadata, Unicode/CRLF edits, foreign-client preservation, and owned direct-child exit.

The source suite passed on Linux with Neovim 0.12.5 and LuaJIT 2.1.1788856981. Its isolated test directory is `/home/vimkim/temp/cubrid-standard-final-source-GZlaky`, and its output is `/home/vimkim/temp/cubrid-standard-lsp-evidence/full-green.log`. The final artifact adds an invalid-option assertion and a post-response client-count assertion to the same native regression.

The extracted artifact suite passed with a separate profile under `/home/vimkim/temp/cubrid-standard-artifact-aWXZq9`. The archive is `cubrid.nvim.tar.gz`, the extracted plugin is `extracted/`, and the profile is `profile/`. Its complete file inventory is `inventory.txt`. The archive contains `lsp/cubrid.lua`, both READMEs, help, all runtime modules, and executable headless tests. Its SHA-256 is `cd70fef0f664fc19f956ade6f811a1ad59f5371b4c07f81593e47a3b114778ee`. Output is `/home/vimkim/temp/cubrid-standard-lsp-evidence/artifact-green.log`. The wire capture is `profile/native-settings-wire.jsonl` in the artifact directory.

To repeat the checks, choose new disposable directories:

```sh
server=/home/vimkim/gh/cubrid-language-tools-show-hints/.venv/bin/cubrid-language-server
source_profile=$(mktemp -d)
CUBRID_TEST_DIR="$source_profile" CUBRID_TEST_SERVER="$server" sh tests/run.sh
artifact_dir=$(mktemp -d)
sh scripts/package.sh "$artifact_dir/cubrid.nvim.tar.gz"
mkdir "$artifact_dir/extracted"
tar -xzf "$artifact_dir/cubrid.nvim.tar.gz" -C "$artifact_dir/extracted"
CUBRID_TEST_DIR="$artifact_dir/profile" CUBRID_TEST_SERVER="$server" \
  sh "$artifact_dir/extracted/tests/run.sh"
```

`tests/run.sh` isolates XDG configuration, data, cache, and state. No GUI, real user-profile mutation, database connection, or SQL execution is part of these checks. The cleanup test observes direct children of Neovim. It does not claim general descendant-process cleanup. Lower Neovim versions, other operating systems, and full LazyVim distribution startup remain unverified. User root callbacks retain Neovim's asynchronous attachment behavior. Custom RPC-function commands cannot provide an executable identity for doctor. If users replace the shipped `before_init` or `on_exit`, they must chain the existing callback to retain settings preparation and failure reporting. The coordinator owns independent Blink LSP-only popup verification and integration review.

## Independent packaged Blink and LazyVim verification

The coordinator verified the final runtime files from product commit `12feab90dfaae8ce4ca49d45ed8dec6cc875dea7`, plus README example cleanup, against a separate installed engine wheel from product commit `8b1226c8f10686eb29d13d86cdda793df71d6645`. All 39 packaged files matched their source. The archive is `/home/vimkim/temp/cubrid-show-hints-606-yszqo6t9/evidence/artifacts/cubrid.nvim.tar.gz`, SHA-256 `15e8323c04ea07bef2cbd81660ada7b6482d4704a8c0e5299a04ab93c8c5c99f`.

The installed artifact passed six real completion edits in default setup, explicit native activation, and an isolated LazyVim profile. Blink used only its ordinary LSP source. The cases verify SHOW, hint names after an emoji, bracketed and Unicode arguments, aliases after owner-qualified relations without a snapshot, and manual completion before an existing token. All accepted edits preserve the full token. The same runs checked exact UTF-16 A1001 ranges, correction clearing with U1002 retained, one actual client across buffers, the user attachment callback, and direct-child exit. The three successful runner logs and `delivery-results.json` record exit 0 and cleanup.

The isolated LazyVim run uses installed plugin sources with separate XDG configuration, data, cache and state. It opens a real `.csql` file. Plugin updates, Mason and automatic parser installation are disabled in the successful run. The earlier disposable profile attempted parser downloads before that independent installer was disabled. Its data stayed in that profile's XDG data/site directory. No real user settings or plugin source files changed. This verifies the selected LazyVim integration rather than the full personal configuration. Neovim 0.12.5 on Linux remains the tested platform.

The coordinator's reusable driver and saved results are in `/home/vimkim/temp/cubrid-show-hints-606-yszqo6t9/evidence/`. Repeat a mode with a fresh label:

```sh
python3 /home/vimkim/temp/cubrid-show-hints-606-yszqo6t9/evidence/run-editor-acceptance.py \
  --mode lazyvim --label new-lazyvim-check
```

Use `default` or `external` for the other activation modes. The driver schedules the checks after startup so normal editor events can run. The independent review verified lifecycle and override cases and confirmed that the final engine boundary correction passed through the public API and framed LSP. Native coverage is unchanged, and authoring warnings do not certify complete SQL validity.

The isolated integration used LazyVim commit `999700997f72227187d49d8b92667183dc7fc809` and Blink commit `78336bc89ee5365633bcf754d93df01678b5c08f`. Their source checkouts had no tracked changes after verification.

## Approved SHOW/hint integration after concurrent CI

The approved rebase retains the documentation and CI changes through `8e9f200e881f82241ced6dd01735b104ede0d203`. Runtime files in `lua`, `lsp`, `ftplugin`, `syntax` and `indent` match the independently reviewed `f5ac73b` version exactly. Both acceptance additions were retained. The native configuration tests in three activation modes and custom-root test now run in the portable suite. The native settings-success and SHOW/hint checks run in the full suite. The runners retain their 120-second deadline and five-second termination escalation.

The existing package verifier first rejected `lsp/cubrid.lua`. Commit `ddad76a` adds `lsp` to its source inventory. The red and green logs are in `/home/vimkim/temp/cubrid-show-hints-606-yszqo6t9/evidence/integration/`. The verified archive SHA-256 is `438c48a890e01575b262176279ed2aa2e04571bf58232a50ac1f176549c96386`.

The extracted package passed 21 portable and six native cases using the current engine task server and read-only qualified native inputs. A separate extracted portable run passed all 21 cases with the existing CI server built from core `2a8842c45c4fb219e322afd731c27937a107324f`. Logs, per-case receipts, process-exit receipts, and `checks.json` are under that integration directory. The current engine also passed its complete 120 core, 34 LSP, 46 native-parser and seven native LSP tests. Independent integration review found no blocking issue. These local results do not claim hosted CI coverage or native success from the portable workflow.

## Visible CSQL command entry (N642)

The task starts at `5ee3b019ff1dfda5c28b04fb7ac7101115fa41e3`. On Neovim 0.12.5, the native terminal regression failed on the baseline because the command text was masked. The failure is in `/tmp/n642-red2.log` and the terminal capture is `/tmp/n642-red2/terminal.log`. The same test passed after the prompt change, with its terminal capture in `/tmp/n642-green3/terminal.log`.

The test drives the public connection command through a PTY. It observes command text and password stars, checks exact indexed input and Ex history before and after, and exercises Enter, Escape, and Ctrl-C. It uses the isolated server and exporter under `/tmp/cubrid-schema-implementation-EMmkLi/venv/bin` and a controlled CSQL fixture. It does not start a database or real CSQL. The existing schema flow checks connection, refresh, disconnect, credentials, and status redaction.

The package at `/tmp/n642-package/cubrid.nvim.tar.gz` was extracted and compared to the source files before running `tests/run-portable.sh`. The isolated profile and suite output are under `/tmp/n642-package/profile` and `/tmp/n642-package/portable.log`. These checks cover the local Neovim version; other versions and third-party command-line autocmd interactions remain unverified.

Independent review of `f76c2087a3903580216ba65aabf56336b542d8b3` found no production defect or added explanatory comments. It proved that the new native test runner could accept an old receipt after an editor failure. The runner now rejects nonempty test directories and checks the editor exit status. The coordinator's fresh native prompt test passed at `/tmp/cubrid-visible-command-X42si2/independent-native-final`; the stale directory rejection is in `rejected-stale-marker.log` under the same task root.
