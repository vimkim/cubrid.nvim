#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
testdir=${CUBRID_TEST_DIR:?Set CUBRID_TEST_DIR to a disposable directory}
mkdir -p "$testdir" "$testdir/config" "$testdir/data" "$testdir/cache" "$testdir/state"
export CUBRID_PLUGIN_ROOT="$root"
export XDG_CONFIG_HOME="$testdir/config" XDG_DATA_HOME="$testdir/data" XDG_CACHE_HOME="$testdir/cache" XDG_STATE_HOME="$testdir/state"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/smoke.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/integration.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -c "luafile $root/tests/menu.lua"
for case in foreign mixed owned; do
  CUBRID_MENU_CASE=$case nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -c "luafile $root/tests/menu-foreign.lua"
done
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -c "luafile $root/tests/menu-cases.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -c "luafile $root/tests/menu-stale.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -c "luafile $root/tests/menu-unsupported.lua"
CUBRID_TEST_COMPLETION_FIXTURE=1 nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -c "luafile $root/tests/menu-choices.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/ownership.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/missing.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/missing-default.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/sql-defaults.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/file-extensions.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/metadata.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/startup.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/exit.lua"
for pid in $(cat "$testdir/exit-children"); do
  attempts=0
  while kill -0 "$pid" 2>/dev/null && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
  done
  if kill -0 "$pid" 2>/dev/null; then
    printf 'Owned child %s survived editor exit\n' "$pid" >&2
    exit 1
  fi
done
printf 'Owned direct children exited with Neovim\n'
