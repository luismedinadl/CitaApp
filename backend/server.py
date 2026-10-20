"""API sencilla para CitaApp. Ejecutar: python server.py"""
import hashlib
import hmac
import json
import getpass
import secrets
import sqlite3
import urllib.error
import urllib.request
from datetime import date, datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).parent
DB = ROOT / 'citaapp.db'
SESSIONS = {}

class Connection(sqlite3.Connection):
    def __exit__(self, *args):
        try:
            return super().__exit__(*args)
        finally:
            self.close()

def conn():
    db = sqlite3.connect(DB, factory=Connection)
    db.row_factory = sqlite3.Row
    return db

def hash_password(password, salt=None):
    salt = salt or secrets.token_hex(16)
    value = hashlib.pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 200000)
    return salt + ':' + value.hex()

def valid_password(password, saved):
    salt = saved.split(':')[0]
    return hmac.compare_digest(hash_password(password, salt), saved)

def setup():
    with conn() as db:
        db.executescript('''
        CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, name TEXT, email TEXT UNIQUE, password TEXT, role TEXT);
        CREATE TABLE IF NOT EXISTS services(id INTEGER PRIMARY KEY, name TEXT, duration INTEGER, price REAL);
        CREATE TABLE IF NOT EXISTS appointments(id INTEGER PRIMARY KEY, user_id INTEGER, service_id INTEGER, date TEXT, time TEXT, status TEXT DEFAULT 'confirmada');
        CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT);
        INSERT OR IGNORE INTO settings VALUES('start','09:00');
        INSERT OR IGNORE INTO settings VALUES('end','18:00');
        ''')
        if not db.execute('SELECT id FROM services').fetchone():
            db.executemany('INSERT INTO services(name,duration,price) VALUES(?,?,?)', [
                ('Corte de cabello', 30, 150), ('Arreglo de barba', 30, 100), ('Corte y barba', 60, 230)])

def get_user(headers, admin=False):
    token = headers.get('Authorization', '').removeprefix('Bearer ')
    user_id = SESSIONS.get(token)
    if not user_id: raise ValueError('Inicia sesión nuevamente.')
    with conn() as db:
        user = db.execute('SELECT id,name,email,role FROM users WHERE id=?', (user_id,)).fetchone()
    if not user or (admin and user['role'] != 'admin'): raise PermissionError('No tienes permiso para esta acción.')
    return user

def is_holiday(day):
    """API pública Nager.Date: evita ofrecer citas en feriados nacionales mexicanos."""
    try:
        url = f'https://date.nager.at/api/v3/PublicHolidays/{day.year}/MX'
        with urllib.request.urlopen(url, timeout=3) as response:
            return any(item.get('date') == day.isoformat() for item in json.load(response))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return False

def slots(service_id, day):
    try: day = date.fromisoformat(day)
    except ValueError: raise ValueError('La fecha debe tener formato AAAA-MM-DD.')
    if day < date.today(): raise ValueError('No puedes reservar una fecha pasada.')
    if is_holiday(day): return []
    with conn() as db:
        service = db.execute('SELECT duration FROM services WHERE id=?', (service_id,)).fetchone()
        if not service: raise LookupError('El servicio no existe.')
        start = db.execute("SELECT value FROM settings WHERE key='start'").fetchone()['value']
        end = db.execute("SELECT value FROM settings WHERE key='end'").fetchone()['value']
        booked = db.execute("""SELECT a.time,s.duration FROM appointments a
            JOIN services s ON s.id=a.service_id
            WHERE a.date=? AND a.status='confirmada'""", (day.isoformat(),)).fetchall()
    hours = []
    current = datetime.strptime(start, '%H:%M')
    limit = datetime.strptime(end, '%H:%M') - timedelta(minutes=service['duration'])
    while current <= limit:
        hour = current.strftime('%H:%M')
        begin = current.hour * 60 + current.minute
        ends = begin + service['duration']
        occupied = any(begin < (datetime.strptime(row['time'], '%H:%M').hour * 60 + datetime.strptime(row['time'], '%H:%M').minute + row['duration']) and ends > (datetime.strptime(row['time'], '%H:%M').hour * 60 + datetime.strptime(row['time'], '%H:%M').minute) for row in booked)
        if not occupied: hours.append(hour)
        current += timedelta(minutes=30)
    return hours

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def respond(self, code, body):
        data = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(code); self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*'); self.send_header('Content-Length', str(len(data))); self.end_headers(); self.wfile.write(data)
    def body(self):
        length = int(self.headers.get('Content-Length', '0'))
        try: return json.loads(self.rfile.read(length)) if length else {}
        except json.JSONDecodeError: raise ValueError('El JSON enviado no es válido.')
    def do_OPTIONS(self): self.send_response(204); self.send_header('Access-Control-Allow-Origin', '*'); self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization'); self.end_headers()
    def do_GET(self): self.route()
    def do_POST(self): self.route()
    def route(self):
        try:
            parsed = urlparse(self.path); path = parsed.path; query = parse_qs(parsed.query)
            if path == '/api/services' and self.command == 'GET':
                with conn() as db: rows = db.execute('SELECT * FROM services').fetchall()
                return self.respond(200, {'data': [dict(x) for x in rows]})
            if path == '/api/slots' and self.command == 'GET':
                data = slots(int(query.get('service_id',['0'])[0]), query.get('date',[''])[0]); return self.respond(200, {'data': data})
            if path in ('/api/register', '/api/login') and self.command == 'POST':
                data = self.body(); email = str(data.get('email','')).strip().lower(); password = str(data.get('password',''))
                if '@' not in email or len(password) < 10: raise ValueError('Correo inválido o contraseña menor a 10 caracteres.')
                with conn() as db:
                    if path.endswith('register'):
                        name = str(data.get('name','')).strip()
                        if len(name) < 2: raise ValueError('Escribe tu nombre.')
                        try: id = db.execute('INSERT INTO users(name,email,password,role) VALUES(?,?,?,?)', (name,email,hash_password(password),'client')).lastrowid
                        except sqlite3.IntegrityError: raise ValueError('Este correo ya está registrado.')
                    else:
                        user = db.execute('SELECT * FROM users WHERE email=?', (email,)).fetchone()
                        if not user or not valid_password(password, user['password']): raise PermissionError('Correo o contraseña incorrectos.')
                        id = user['id']
                    user = db.execute('SELECT id,name,email,role FROM users WHERE id=?', (id,)).fetchone()
                token = secrets.token_urlsafe(24); SESSIONS[token] = id
                return self.respond(201 if path.endswith('register') else 200, {'token': token, 'user': dict(user)})
            if path == '/api/appointments' and self.command == 'GET':
                user = get_user(self.headers)
                with conn() as db: rows = db.execute('''SELECT a.id,s.name service,a.date,a.time,u.name client,a.status FROM appointments a JOIN services s ON s.id=a.service_id JOIN users u ON u.id=a.user_id WHERE a.user_id=? ORDER BY a.date,a.time''',(user['id'],)).fetchall()
                return self.respond(200, {'data': [dict(x) for x in rows]})
            if path == '/api/appointments' and self.command == 'POST':
                user = get_user(self.headers); data = self.body(); service_id = int(data.get('service_id',0)); day = str(data.get('date','')); time = str(data.get('time',''))
                if time not in slots(service_id, day): return self.respond(409, {'error':'Ese horario ya no está disponible.'})
                with conn() as db:
                    db.execute('INSERT INTO appointments(user_id,service_id,date,time) VALUES(?,?,?,?)',(user['id'],service_id,day,time))
                return self.respond(201, {'message':'Cita reservada.'})
            if path.startswith('/api/appointments/') and path.endswith('/cancel') and self.command == 'POST':
                user = get_user(self.headers); id = int(path.split('/')[3])
                with conn() as db:
                    result = db.execute("UPDATE appointments SET status='cancelada' WHERE id=? AND user_id=? AND status='confirmada'",(id,user['id']))
                if not result.rowcount: return self.respond(404, {'error':'No se encontró una cita activa.'})
                return self.respond(200, {'message':'Cita cancelada.'})
            if path == '/api/admin/appointments' and self.command == 'GET':
                get_user(self.headers, True)
                with conn() as db: rows = db.execute('''SELECT a.id,s.name service,a.date,a.time,u.name client,a.status FROM appointments a JOIN services s ON s.id=a.service_id JOIN users u ON u.id=a.user_id ORDER BY a.date,a.time''').fetchall()
                return self.respond(200, {'data': [dict(x) for x in rows]})
            if path == '/api/admin/services' and self.command == 'POST':
                get_user(self.headers, True); data = self.body(); name = str(data.get('name','')).strip(); duration = int(data.get('duration',0)); price = float(data.get('price',-1))
                if len(name)<2 or duration not in (30,60,90,120) or price<0: raise ValueError('Revisa nombre, duración y precio.')
                with conn() as db: db.execute('INSERT INTO services(name,duration,price) VALUES(?,?,?)',(name,duration,price))
                return self.respond(201, {'message':'Servicio agregado.'})
            if path == '/api/admin/schedule' and self.command == 'POST':
                get_user(self.headers, True); data = self.body(); start, end = str(data.get('start','')), str(data.get('end',''))
                try: valid = datetime.strptime(start,'%H:%M') < datetime.strptime(end,'%H:%M')
                except ValueError: valid = False
                if not valid: raise ValueError('Revisa el horario.')
                with conn() as db: db.execute("UPDATE settings SET value=? WHERE key='start'",(start,)); db.execute("UPDATE settings SET value=? WHERE key='end'",(end,))
                return self.respond(200, {'message':'Horario guardado.'})
            return self.respond(404, {'error':'Recurso no encontrado.'})
        except PermissionError as e: self.respond(401 if 'sesión' in str(e) or 'incorrectos' in str(e) else 403, {'error':str(e)})
        except (ValueError, TypeError) as e: self.respond(400, {'error':str(e)})
        except LookupError as e: self.respond(404, {'error':str(e)})
        except Exception: self.respond(500, {'error':'Error interno del servidor.'})

if __name__ == '__main__':
    setup()
    import sys
    if len(sys.argv) == 3 and sys.argv[1] == '--create-admin':
        email = sys.argv[2].strip().lower()
        password = getpass.getpass('Contraseña (mínimo 10 caracteres): ')
        if '@' not in email or len(password) < 10:
            raise SystemExit('Correo o contraseña inválidos.')
        with conn() as db:
            try:
                db.execute('INSERT INTO users(name,email,password,role) VALUES(?,?,?,?)',
                    ('Administrador', email, hash_password(password), 'admin'))
            except sqlite3.IntegrityError:
                raise SystemExit('Ese correo ya está registrado.')
        raise SystemExit('Administrador creado.')
    print('API lista en http://127.0.0.1:8080/api')
    ThreadingHTTPServer(('127.0.0.1', 8080), Handler).serve_forever()
