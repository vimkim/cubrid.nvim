#!/usr/bin/env python3
import json
import os
import sys
import time

request = json.load(sys.stdin)
root = os.environ['CUBRID_TEST_DIR']
with open(os.path.join(root, 'requests.jsonl'), 'a', encoding='utf-8') as output:
    output.write(json.dumps(request) + '\n')
command = request['command']
if 'slow' in command:
    temporary = os.path.join(root, 'slow-pid.tmp')
    with open(temporary, 'w', encoding='ascii') as pidfile:
        pidfile.write(str(os.getpid()))
    os.replace(temporary, os.path.join(root, 'slow-pid'))
    time.sleep(3)
if 'fail' in command or os.path.exists(os.path.join(root, 'fail')):
    sys.exit(3)
name = 'SECOND_TABLE' if 'second' in command else 'FIRST_TABLE'
if os.path.exists(os.path.join(root, 'refresh')):
    name = 'REFRESH_TABLE'
print(json.dumps({'schemaVersion': 1, 'user': 'DBA', 'database': 'demodb',
                  'source': {'endpoint': 'demodb@localhost'},
                  'relations': [{'owner': 'DBA', 'name': name, 'kind': 'CLASS', 'columns': ['ID']}]}))
