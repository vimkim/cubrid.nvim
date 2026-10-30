#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
testroot=${CUBRID_TEST_DIR:?Set CUBRID_TEST_DIR}
export CUBRID_PLUGIN_ROOT="$root"
mkdir -p "$testroot/config" "$testroot/data" "$testroot/cache" "$testroot/state"
export XDG_CONFIG_HOME="$testroot/config" XDG_DATA_HOME="$testroot/data" XDG_CACHE_HOME="$testroot/cache" XDG_STATE_HOME="$testroot/state"
socket="$testroot/nvim.sock"
case_name=${CUBRID_SCHEMA_CASE:-schema-flow}
case "$case_name" in schema-flow|schema-prompt|schema-exit) ;; *) exit 1 ;; esac
export CUBRID_SCHEMA_CASE="$case_name"
nvim --headless --listen "$socket" -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' </dev/null > "$testroot/stdout.log" 2> "$testroot/stderr.log" &
pid=$!
trap 'kill "$pid" 2>/dev/null || true' EXIT
for i in $(seq 1 100); do [ -S "$socket" ] && break; sleep 0.05; done
nvim --server "$socket" --remote-send ":lua dofile(vim.env.CUBRID_PLUGIN_ROOT .. '/tests/' .. vim.env.CUBRID_SCHEMA_CASE .. '.lua')<CR>"
for i in $(seq 1 400); do
  [ -f "$testroot/schema-flow-result" ] && break
  kill -0 "$pid" 2>/dev/null || break
  sleep 0.05
done
[ -f "$testroot/schema-flow-result" ] || { cat "$testroot/stderr.log" >&2; exit 1; }
wait "$pid"
if [ "$case_name" = schema-exit ]; then
  child=$(cat "$testroot/slow-pid")
  case "$child" in *[!0-9]*|'') exit 1 ;; esac
  for i in $(seq 1 100); do
    kill -0 "$child" 2>/dev/null || exit 0
    sleep 0.05
done
  printf 'CSQL child survived editor exit: %s\n' "$child" >&2
  exit 1
fi
