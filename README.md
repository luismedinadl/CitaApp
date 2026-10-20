# CitaApp

Aplicación móvil sencilla para organizar citas de un pequeño negocio.

## Funciones

- Cliente: registrarse, iniciar sesión, consultar servicios y horarios, reservar y cancelar citas.
- Administrador: iniciar sesión, consultar la agenda, agregar servicios y cambiar el horario.
- API propia: guarda usuarios, servicios y citas en una base SQLite.
- API pública: consulta los feriados nacionales de México con Nager.Date. En un feriado no muestra horarios disponibles.

## Ejecutar

Se necesita Python 3 y Flutter.

En una terminal, desde esta carpeta:

```powershell
python backend/server.py
```

En otra terminal:

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8080/api
```

Para Android con emulador:

```powershell
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api
```

La conexión HTTP se habilita únicamente para esta prueba local. Antes de publicar la aplicación se debe usar una API con HTTPS.

## Administrador

Antes de usar las opciones de administración, crea una cuenta de administrador:

```powershell
python backend/server.py --create-admin admin@tunegocio.com
```

El programa pedirá una contraseña. Después inicia el servidor normalmente e inicia sesión con esa cuenta. La base de datos se crea cuando inicias el servidor.
