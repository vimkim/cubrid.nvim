#!/usr/bin/env python3
import os
import fcntl
import struct
import termios
import pathlib
import pty
import select
import subprocess
import sys
import time

root = pathlib.Path(__file__).resolve().parent.parent
testroot = pathlib.Path(os.environ['CUBRID_TEST_DIR'])
if testroot.exists() and any(testroot.iterdir()):
    raise SystemExit('CUBRID_TEST_DIR must be empty; use a fresh test directory')
testroot.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, CUBRID_PLUGIN_ROOT=str(root), TERM='xterm-256color')
for name in ('CONFIG', 'DATA', 'CACHE', 'STATE'):
    path = testroot / name.lower()
    path.mkdir(exist_ok=True)
    env['XDG_' + name + '_HOME'] = str(path)
master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 160, 0, 0))
process = subprocess.Popen(['nvim', '-u', 'NONE', '-i', 'NONE', '-n', '--cmd', 'lua vim.opt.runtimepath:prepend(vim.env.CUBRID_PLUGIN_ROOT)', '-c', 'luafile ' + str(root / 'tests/visible-command.lua')], stdin=slave, stdout=slave, stderr=slave, env=env, start_new_session=True)
os.close(slave)
output = bytearray()
deadline = time.monotonic() + 30
while process.poll() is None and time.monotonic() < deadline:
    if select.select([master], [], [], 0.1)[0]:
        try:
            output.extend(os.read(master, 65536))
        except OSError:
            break
if process.poll() is None:
    process.kill()
process.wait()
try:
    while select.select([master], [], [], 0)[0]:
        output.extend(os.read(master, 65536))
except OSError:
    pass
os.close(master)
(testroot / 'terminal.log').write_bytes(output)
assert process.returncode == 0, 'Neovim failed; inspect terminal.log'
assert (testroot / 'visible-result').exists(), 'native flow failed; inspect terminal.log'
assert b'csql\x1b[C-udba\x1b[C-pInlineSecret\x1b[Cdemodb\x1b[C-C' in output, 'command text was not visible'
assert b'****************' in output and b'PasswordSentinel' not in output, 'password was not masked'
print('visible command and masked password passed')
