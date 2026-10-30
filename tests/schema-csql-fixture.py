#!/usr/bin/env python3
import json
import os
import sys
import time

root = os.environ['CUBRID_TEST_DIR']
endpoint = sys.argv[-1]
database = endpoint.split('@', 1)[0]
with open(os.path.join(root, 'csql-launch.json'), 'w', encoding='utf-8') as output:
    json.dump({'argv': sys.argv[1:], 'pid': os.getpid()}, output)
if endpoint == 'slow':
    temporary = os.path.join(root, 'slow-pid.tmp')
    with open(temporary, 'w', encoding='ascii') as pidfile:
        pidfile.write(str(os.getpid()))
    os.replace(temporary, os.path.join(root, 'slow-pid'))
    time.sleep(3)
if endpoint == 'fail' or os.path.exists(os.path.join(root, 'fail')):
    sys.exit(3)
name = 'SECOND_TABLE' if endpoint == 'second' else 'FIRST_TABLE'
if os.path.exists(os.path.join(root, 'refresh')):
    name = 'REFRESH_TABLE'
print('kind\tlogin_name\towner_name\tclass_name\titem_name\titem_type')
print(f'identity\tDBA\tDBA\t{database}\t{database}\tDATABASE')
print(f'relation\tDBA\tDBA\t{name}\t{name}\tCLASS')
print(f'column\tDBA\tDBA\t{name}\tID\tINSTANCE')
print('user\tDBA\tDBA\tDBA\tDBA\tUSER')
