#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
testroot=${CUBRID_TEST_DIR:?Set CUBRID_TEST_DIR to a fresh disposable directory}
server=${CUBRID_TEST_SERVER:?Set CUBRID_TEST_SERVER to the real language server}
case "$server" in /*) ;; *) printf 'CUBRID_TEST_SERVER must be absolute\n' >&2; exit 1 ;; esac
[ -x "$server" ] || { printf 'Language server is not executable: %s\n' "$server" >&2; exit 1; }
mkdir -p "$testroot"
testroot=$(CDPATH= cd -- "$testroot" && pwd)
export CUBRID_PLUGIN_ROOT="$root" CUBRID_TEST_SERVER="$server"
nvim --version > "$testroot/nvim-version.txt"
if [ -n "${CUBRID_TEST_NVIM_VERSION:-}" ]; then
  IFS= read -r version < "$testroot/nvim-version.txt"
  [ "$version" = "NVIM v$CUBRID_TEST_NVIM_VERSION" ] || { printf 'Unexpected Neovim version: %s\n' "$version" >&2; exit 1; }
fi
printf 'runtimepath=%s\ncoverage=portable; native parser success not tested\n' "$root" > "$testroot/identity.txt"
printf 'incomplete\n' > "$testroot/result.txt"
run_case() {
  name=$1; form=$2; file=$3; flag=$4
  case_dir="$testroot/$name"
  mkdir "$case_dir"
  mkdir "$case_dir/config" "$case_dir/data" "$case_dir/cache" "$case_dir/state"
  export CUBRID_TEST_DIR="$case_dir"
  export XDG_CONFIG_HOME="$case_dir/config" XDG_DATA_HOME="$case_dir/data" XDG_CACHE_HOME="$case_dir/cache" XDG_STATE_HOME="$case_dir/state"
  export CUBRID_MENU_CASE= CUBRID_TEST_COMPLETION_FIXTURE= CUBRID_NATIVE_CASE= CUBRID_DEPENDENCY_CASE=
  case "$flag" in foreign|mixed|owned) export CUBRID_MENU_CASE="$flag" ;; fixture) export CUBRID_TEST_COMPLETION_FIXTURE=1 ;; native|setup|optout) export CUBRID_NATIVE_CASE="$flag" ;; esac
  case "$flag" in configured|discovery) export CUBRID_DEPENDENCY_CASE="$flag" ;; esac
  printf 'running %s\n' "$name"
  if [ "$form" = command ]; then
    set -- -c "execute 'luafile ' . fnameescape(\"$root/tests/$file\")"
  else
    set -- -l "$root/tests/$file"
  fi
  if timeout --kill-after=5s 120s nvim --headless -u NONE --cmd 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT); assert(vim.opt.runtimepath:get()[1] == vim.env.CUBRID_PLUGIN_ROOT)' "$@" > "$case_dir/stdout.log" 2> "$case_dir/stderr.log"; then
    printf 'passed\n' > "$case_dir/result.txt"
  else
    status=$?
    printf 'failed %s\n' "$status" > "$case_dir/result.txt"
    printf 'Case %s failed with status %s\n' "$name" "$status" >&2
    cat "$case_dir/stderr.log" >&2
    exit "$status"
  fi
}
run_case native-config-native lua native-config.lua native
run_case native-config-setup lua native-config.lua setup
run_case native-config-optout lua native-config.lua optout
run_case native-roots lua native-roots.lua none
run_case smoke lua smoke.lua none
run_case menu command menu.lua none
run_case menu-foreign command menu-foreign.lua foreign
run_case menu-mixed command menu-foreign.lua mixed
run_case menu-owned command menu-foreign.lua owned
run_case menu-cases command menu-cases.lua none
run_case menu-stale command menu-stale.lua none
run_case menu-unsupported command menu-unsupported.lua none
run_case menu-choices command menu-choices.lua fixture
run_case ownership lua ownership.lua none
run_case missing lua missing.lua none
run_case missing-default lua missing-default.lua none
run_case dependencies-configured lua dependencies.lua configured
run_case dependencies-discovery lua dependencies.lua discovery
run_case dependency-server-override lua dependency-server-override.lua none
run_case sql-defaults lua sql-defaults.lua none
run_case file-extensions lua file-extensions.lua none
run_case metadata lua metadata.lua none
run_case discovery-cases lua discovery-cases.lua none
run_case exit lua exit.lua none
children="$testroot/exit/exit-children"
[ -s "$children" ] || { printf 'Missing direct-child receipt\n' >&2; exit 1; }
for pid in $(cat "$children"); do
  case "$pid" in *[!0-9]*|'') printf 'Invalid child PID: %s\n' "$pid" >&2; exit 1 ;; esac
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
printf 'Owned direct children exited with Neovim\n' > "$testroot/exit/children-result.txt"
printf 'passed\n' > "$testroot/result.txt"
