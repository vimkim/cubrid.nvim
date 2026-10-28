# Keep queued menu cancellation with its owner

Work item 582 follow-up, baseline `b02e13e0a5aa8996bef435f91f4f3d7ad8cdd7cb`.
The repaired Ctrl-Y completion path and extracted suite pass, but the coordinator reproduced a remaining ownership race through real public editor APIs.

Repro `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/root-neovim/foreign-menu.lua` starts a visible CUBRID menu, changes filetype to `sql` (which detaches CUBRID), and immediately shows a different provider's public `complete()` menu. The deferred CUBRID cancellation then sends CTRL-E to that replacement menu. `foreign-profile/menu-observed.txt` shows the foreign menu visible before and gone afterward, exit 5.

The scheduled callback in `completion.lua` `invalidate()` must verify that the displayed menu still belongs to the captured CUBRID epoch/generation before cancelling it. Reuse the existing opaque item identity; never guess language/token boundaries or touch another provider's handler.
Do not rely only on the current slot existing: the old owned popup still needs cancellation after detach. Do not cancel a replacement or mixed-provider menu based on one matching item.
This preserves the existing adapter shape and is confined to its deferred ownership check, not a new completion architecture.

## Acceptance

1. Commit a genuine failing public-menu regression before the guard fix.
2. Prove the replacement foreign menu survives after filetype detach in a fresh real headless editor.
3. Prove a still-displayed old owned menu is cancelled on detach and a new CUBRID generation's menu is not cancelled by an old callback.
4. Rerun actual Ctrl-Y suffix replacement and the full extracted-package suite; inspect source/artifact correspondence.
5. Clarify that Ctrl-Y is the supported full-span acceptance key. Space/Escape are native discard exits and may retain preview suffixes; do not claim those apply the authoritative edit. Keep multiline/unsupported forms explicit.
6. Add practical shared-engine installation links to both README languages, using the existing core guides at `https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.md` and `install.en.md`.

Own this isolated worktree and `/home/vimkim/temp/cubrid-editor-alpha-aiYISe/neovim-ownership/` only. Read AGENTS/spec/design/ticket and exact dispatch first.
Use the existing fixed core candidate and read-only native inputs. No changes to other worktrees, user config, core or SDKs.
Local commits are authorized; no integration or publication. Return a clean committed candidate, rebuilt archive/hash, and exact red/green ownership, menu and full-suite evidence.
