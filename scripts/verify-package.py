#!/usr/bin/env python3
import hashlib
import pathlib
import subprocess
import sys
import tarfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
INCLUDED = ('README.md', 'README.en.md', 'LICENSE', 'lua', 'ftplugin', 'indent', 'syntax', 'doc', 'tests')


def main():
    if len(sys.argv) != 2:
        raise SystemExit('Usage: verify-package.py ARCHIVE')
    tracked = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z', '--', *INCLUDED]).split(b'\0')
    expected = {name.decode() for name in tracked if name}
    if not expected:
        raise SystemExit('Package source inventory is empty')
    seen = set()
    with tarfile.open(sys.argv[1], 'r:gz') as archive:
        for member in archive:
            name = member.name.rstrip('/')
            if member.isdir():
                continue
            if not member.isfile() or name in seen or name not in expected:
                raise SystemExit(f'Unexpected or duplicate package member: {member.name}')
            seen.add(name)
            packaged = archive.extractfile(member).read()
            source = (ROOT / name).read_bytes()
            if packaged != source:
                raise SystemExit(f'Package differs from checkout: {name}')
            print(hashlib.sha256(packaged).hexdigest(), name)
    missing = expected - seen
    if missing:
        raise SystemExit(f'Missing package members: {sorted(missing)}')
    print(f'Verified {len(seen)} package files against the checkout', file=sys.stderr)


if __name__ == '__main__':
    main()
