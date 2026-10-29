#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

server = subprocess.Popen([os.environ['CUBRID_TEST_SERVER']], stdin=subprocess.PIPE, stdout=subprocess.PIPE)


def read(stream):
    headers = {}
    while True:
        line = stream.readline()
        if not line:
            return None
        if line in (b'\r\n', b'\n'):
            break
        key, value = line.decode('ascii').split(':', 1)
        headers[key.lower()] = value.strip()
    return json.loads(stream.read(int(headers['content-length'])))


def write(stream, message):
    body = json.dumps(message, separators=(',', ':')).encode()
    stream.write(b'Content-Length: ' + str(len(body)).encode() + b'\r\n\r\n' + body)
    stream.flush()


def output():
    while (message := read(server.stdout)) is not None:
        write(sys.stdout.buffer, message)


thread = threading.Thread(target=output, daemon=True)
thread.start()
with open(os.environ['CUBRID_WIRE_LOG'], 'a', encoding='utf-8') as log:
    while (message := read(sys.stdin.buffer)) is not None:
        log.write(json.dumps(message) + '\n')
        log.flush()
        if message.get('method') == 'initialize' and os.environ.get('CUBRID_INIT_GATE'):
            deadline = time.monotonic() + 10
            while not Path(os.environ['CUBRID_INIT_GATE']).exists():
                if time.monotonic() >= deadline:
                    raise TimeoutError('test did not release initialize')
                time.sleep(0.01)
        write(server.stdin, message)
server.stdin.close()
server.wait(timeout=5)
thread.join(timeout=5)
