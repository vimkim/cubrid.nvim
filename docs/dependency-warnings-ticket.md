# Dependency warnings, N631

The ticket starts at plugin `7b156c529af54736f5fadbcceb79c35a31c09134` on `fix/missing-binary-warnings` in `/home/vimkim/gh/cubrid.nvim-binary-warnings`. The destination is local `main` in `/home/vimkim/gh/cubrid.nvim`. The worktree was clean, and the dispatch baseline was verified as HEAD and its own ancestor before edits. Origin is `https://github.com/vimkim/cubrid.nvim.git`. Integration and publication remain unperformed.

The read-only core baseline is `ad9d9434f6f8d74b8c44d9cadba0faf2362e6606`. The real server is `/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server`, importing that checkout's `src/cubrid_language/lsp.py`. The host runs Linux, Neovim 0.12.5, LuaJIT 2.1.1788856981, and Python 3.14.0.

## Behavior

Activation warns at `vim.log.levels.WARN` when the server is absent or not executable. The notice names `cubrid-language-server`, links the GitHub installation guide, and gives PATH, trusted path, and `:CubridRestart` guidance. Native discovery failures and unavailable configured worker, manifest, or runtime paths produce equivalent installation guidance. Native notices state that strict syntax diagnostics are unavailable while keyword completion can continue.

Unchanged failures do not repeat across buffers or setup updates. Repair clears the warning state. An explicit restart permits another attempt and notice. Checks use effective trusted setup and `vim.lsp.config` settings. Native failures retain the language-server session and server diagnostics. `auto_start=false` stays silent until native activation. No SQL execution, installation, download, or native protocol changes were added.

## Failing-before evidence

All evidence is under `/home/vimkim/temp/cubrid-nvim-N631-rwGk3w`. `baseline` is a `git archive` extraction of the dispatch commit. The new tests ran against that runtime through real `nvim --headless -u NONE` with separate XDG directories.

```sh
python3 /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/run-focused.py /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/baseline tests/missing-default.lua red-severity-receipt
python3 /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/run-focused.py /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/baseline tests/missing.lua red-guide
python3 /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/run-focused.py /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/baseline tests/dependencies.lua red-native-receipt configured
```

Each command exited 1. The failures were `missing server uses warning severity`, `missing server asks for installation with GitHub guide`, and a timeout waiting for the missing-worker warning. The native case started the real server successfully before waiting for the absent notice. Each case retains `command.txt`, `output.log`, and `result.txt`.

## Passing-after evidence

The source portable suite passed in `green-portable-2`. The final package adds the native argv failure and recovery case. Build and source correspondence commands were:

```sh
scripts/package.sh /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/cubrid.nvim-N631.tar.gz
python3 scripts/verify-package.py /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/cubrid.nvim-N631.tar.gz
```

The archive contains 43 files, all verified against the staged source. Its SHA-256 is `48a911e941f9bd6569795a1d91a9099966b725c1703ccc5dccd93c745164bfbd`. The extraction is `installed`; its inventory is `package-inventory.txt`.

```sh
CUBRID_TEST_DIR=/home/vimkim/temp/cubrid-nvim-N631-rwGk3w/installed-portable \
CUBRID_TEST_SERVER=/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server \
/home/vimkim/temp/cubrid-nvim-N631-rwGk3w/installed/tests/run-portable.sh
python3 /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/run-focused.py /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/installed /home/vimkim/temp/cubrid-nvim-N631-rwGk3w/installed/tests/dependencies-native.lua installed-native-qualified
```

All 24 extracted portable cases passed. The suite covers absent PATH and explicit servers, a non-executable server replacement, native argv overrides, repair and restart, default discovery failure, configured absent and non-executable workers, absent manifests and runtime directories, deduplication, completion preservation, and opt-out behavior. Existing completion menu, settings, roots, ownership, metadata, discovery, and direct-child cleanup cases also pass. Logs and per-case results are in `installed-portable` and `installed-portable.log`.

The focused native run passed with the existing qualified worker `/home/vimkim/temp/cubrid-followup-execution-6_7fcyif/native/qualified-build/parser-worker`, its adjacent manifest, and `/home/vimkim/.cub/install/develop/debug`. It verifies no warning for available native overrides despite unavailable setup paths, real `CUBRID-S1001` diagnostics, one WARN and `CUBRID-T1001` after a missing worker path replaces the effective setting, recovery to strict diagnostics, and a new warning after recurrence. Its records are in `installed-native-qualified`, including `dependency-notices.json`. The source counterpart passed in `green-native-qualified`.

The worker SHA-256 is `c2b89a8f7d539934f0b68cf2af66199d3889baa541859d30809cca9c91ccabd3`. The manifest SHA-256 is `c93879150d6ecb4a62414876f097b029e2bec06725292bbe6673133c46bb7efc`. It declares `bounded-query-dml-schema-engineer-ordered-v4` for `cubrid-11.5.0.2704-cc94778`.

`git diff --check` passed. Personal editor profiles, central source, and native inputs were unchanged.

## Limits

Consumer preflight checks file availability, executable permission, readable JSON manifests, and runtime directories. The server and worker retain qualification, library compatibility, and protocol checks. The portable configured case uses a disposable executable fixture only to test prerequisite presence. It does not establish native validity.

The healthy static-root activation path remains unchanged. An attempted asynchronous root check failed the existing immediate completion-menu case; that approach was removed, and the full portable menu tests pass. Native argv startup failures may also produce Neovim's own spawn error alongside the actionable plugin WARN. A custom RPC function owns its executable selection, so the plugin cannot infer or verify that executable.

This ticket does not run the full native matrix, the older host-specific native suite, Blink, LazyVim, personal configuration, other operating systems, or other Neovim versions. It does not prove descendant cleanup after a forced kill. The final local commit contains the acceptance record and is ready for integration review.
