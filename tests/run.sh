#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
testroot=${CUBRID_TEST_DIR:?Set CUBRID_TEST_DIR to a fresh disposable directory}
mkdir -p "$testroot"
testroot=$(CDPATH= cd -- "$testroot" && pwd)
CUBRID_TEST_DIR="$testroot/portable" "$root/tests/run-portable.sh"
export CUBRID_PLUGIN_ROOT="$root"
for case in integration startup discovery-doctor doctor-display; do
  case_dir="$testroot/native-$case"
  mkdir "$case_dir"
  mkdir "$case_dir/config" "$case_dir/data" "$case_dir/cache" "$case_dir/state"
  export CUBRID_TEST_DIR="$case_dir"
  export XDG_CONFIG_HOME="$case_dir/config" XDG_DATA_HOME="$case_dir/data" XDG_CACHE_HOME="$case_dir/cache" XDG_STATE_HOME="$case_dir/state"
  printf 'running native %s\n' "$case"
  if timeout --kill-after=5s 120s nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)' -l "$root/tests/$case.lua" > "$case_dir/stdout.log" 2> "$case_dir/stderr.log"; then
    printf 'passed\n' > "$case_dir/result.txt"
  else
    status=$?
    printf 'failed %s\n' "$status" > "$case_dir/result.txt"
    cat "$case_dir/stderr.log" >&2
    exit "$status"
  fi
done
