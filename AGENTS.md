# CUBRID Neovim consumer

Read `/home/vimkim/my-cubrid/CUBRID.md` before CUBRID work.
The shared engine is `/home/vimkim/gh/cubrid-language-tools`; its language contracts and native inputs are read-only dependencies.
Read `docs/spec.md` and the coordinator's exact dispatch before implementation.

This project owns Neovim file detection, lexical highlighting, indentation, editor settings, native LSP lifecycle, packaging, and editor tests.
Use the shared stdio server for completion and diagnostics. Never execute submitted SQL or duplicate its completion/parser implementation.
Use `cubrid` as the filetype for `.sql` and `.csql` by default. Select extensions independently through `file_extensions`, a replacement list of `.sql` and `.csql` suffixes.
Executable and native runtime settings come from trusted Lua setup. Project files cannot select commands.

Use one fresh-context implementer and isolated worktree per bounded ticket. Use TDD at public interfaces and verify the real headless editor.
This is a remote Linux host. Never launch desktop GUI programs or forwarded X11. Use `nvim --headless` with isolated configuration.
Keep dependency/build/test outputs narrowly ignored. Preserve unrelated changes.
Commit meaningful task changes before review. Write exact acceptance evidence and limitations in `docs/acceptance.md`.
Local commits are authorized. Request approval before rebasing and integrating into `main`.
Inspect live remotes before publication. Remote creation, pushes, package publication, and deployment require separate authorization.
