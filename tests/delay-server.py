#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import threading

server = subprocess.Popen([os.environ['CUBRID_TEST_SERVER']], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
requests = set()
lock = threading.Lock()


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
    body = stream.read(int(headers['content-length']))
    return json.loads(body)


def write(stream, message, guard):
    body = json.dumps(message, separators=(',', ':')).encode()
    with guard:
        stream.write(b'Content-Length: ' + str(len(body)).encode() + b'\r\n\r\n' + body)
        stream.flush()


def output():
    while (message := read(server.stdout)) is not None:
        if message.get('id') in requests:
            requests.remove(message['id'])
            if os.environ.get('CUBRID_TEST_COMPLETION_FIXTURE') and message.get('result'):
                item = message['result']['items'][0]
                item['label'] = 'same'
                other = json.loads(json.dumps(item))
                other['textEdit']['range']['start']['character'] += 1
                other['textEdit']['newText'] = 'ZZ'
                message['result']['items'] = [item, other]
            threading.Timer(1.5, write, args=(sys.stdout.buffer, message, lock)).start()
        else:
            write(sys.stdout.buffer, message, lock)


threading.Thread(target=output, daemon=True).start()
input_lock = threading.Lock()
while (message := read(sys.stdin.buffer)) is not None:
    if message.get('method') == 'textDocument/completion':
        requests.add(message['id'])
    write(server.stdin, message, input_lock)
server.stdin.close()
server.wait()
