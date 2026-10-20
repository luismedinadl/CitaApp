"""Prueba mínima de la API: registro, consulta y reserva."""
import datetime
import json
import threading
import urllib.request
from pathlib import Path

import server

server.DB = Path(__file__).parent / 'test.db'
server.DB.unlink(missing_ok=True)
server.setup()
http = server.ThreadingHTTPServer(('127.0.0.1', 0), server.Handler)
thread = threading.Thread(target=http.serve_forever)
thread.start()
base = f'http://127.0.0.1:{http.server_port}/api'

def call(method, path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token: headers['Authorization'] = f'Bearer {token}'
    request = urllib.request.Request(base + path, method=method,
        data=json.dumps(body).encode() if body else None, headers=headers)
    return json.loads(urllib.request.urlopen(request).read())

try:
    user = call('POST', '/register', {'name': 'Prueba', 'email': 'prueba@citaapp.local', 'password': 'ClaveSegura1'})
    services = call('GET', '/services')['data']
    tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).isoformat()
    slots = call('GET', f"/slots?service_id={services[0]['id']}&date={tomorrow}")['data']
    result = call('POST', '/appointments', {'service_id': services[0]['id'], 'date': tomorrow, 'time': slots[0]}, user['token'])
    appointments = call('GET', '/appointments', token=user['token'])['data']
    assert result['message'] == 'Cita reservada.' and len(appointments) == 1
    print('Prueba correcta: registro, servicios, horarios y reserva.')
finally:
    http.shutdown()
    thread.join()
    server.DB.unlink(missing_ok=True)
