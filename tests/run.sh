#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
testdir=${CUBRID_TEST_DIR:?Set CUBRID_TEST_DIR to a disposable directory}
mkdir -p "$testdir" "$testdir/config" "$testdir/data" "$testdir/cache" "$testdir/state"
export CUBRID_PLUGIN_ROOT="$root"
export XDG_CONFIG_HOME="$testdir/config" XDG_DATA_HOME="$testdir/data" XDG_CACHE_HOME="$testdir/cache" XDG_STATE_HOME="$testdir/state"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/smoke.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/integration.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/missing.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/metadata.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/startup.lua"
nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/exit.lua"
for pid in $(cat "$testdir/exit-children"); do
  if kill -0 "$pid" 2>/dev/null; then
    printf 'Owned child %s survived editor exit\n' "$pid" >&2
    exit 1
  fi
done
printf 'Owned direct children exited with Neovim\n'
