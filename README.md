# CitaApp

Aplicación móvil sencilla para organizar citas de un pequeño negocio.

## Funciones

- Cliente: registrarse, iniciar sesión, consultar servicios y horarios, reservar y cancelar citas.
- Administrador: iniciar sesión, consultar la agenda, agregar servicios y cambiar el horario.
- API propia: guarda usuarios, servicios y citas en una base SQLite.
- API pública: consulta los feriados nacionales de México con Nager.Date. En un feriado no muestra horarios disponibles.
- Inicio con Google: permite entrar como cliente usando una cuenta de Google.

## Ejecutar

Se necesita Python 3 y Flutter.

En una terminal, desde esta carpeta:

```powershell
py -m pip install -r backend/requirements.txt
py backend/server.py
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

## Inicio con Google

Antes de probarlo necesitas crear tus propias credenciales en Google Cloud; no uses una contraseña ni compartas claves en el proyecto.

1. En [Google Cloud Console](https://console.cloud.google.com/), crea o selecciona un proyecto y configura la pantalla de consentimiento OAuth.
2. Crea un cliente OAuth de tipo **Web application**. Copia su Client ID, que termina en `.apps.googleusercontent.com`.
3. Para Android, crea también un cliente OAuth de tipo **Android** con el paquete `com.example.citaapp` y la huella SHA-1 de tu aplicación. Para la app de prueba puedes obtenerla con:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

4. En la terminal de la API, antes de iniciarla, coloca el Client ID web:

```powershell
$env:GOOGLE_CLIENT_ID='PEGA_AQUI_TU_CLIENT_ID.apps.googleusercontent.com'
py backend/server.py
```

5. Ejecuta Flutter con ese mismo Client ID:

```powershell
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api --dart-define=GOOGLE_CLIENT_ID=PEGA_AQUI_TU_CLIENT_ID.apps.googleusercontent.com
```

Para probarlo en Chrome agrega `http://localhost` y `http://localhost:7357` a los orígenes autorizados del cliente web y ejecuta:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=API_URL=http://127.0.0.1:8080/api --dart-define=GOOGLE_CLIENT_ID=PEGA_AQUI_TU_CLIENT_ID.apps.googleusercontent.com
```

Las cuentas que entran con Google se crean como **clientes**. El administrador se sigue creando con el comando indicado abajo.

La conexión HTTP se habilita únicamente para esta prueba local. Antes de publicar la aplicación se debe usar una API con HTTPS.

Para un celular físico, el celular y la computadora deben usar la misma red Wi-Fi. Inicia la API con `py backend/server.py --lan`, consulta la IPv4 de la computadora con `ipconfig` y usa esa dirección al compilar. Ejemplo: `--dart-define=API_URL=http://192.168.1.20:8080/api`.

### Usar la app desde otra red

Para una demostración sin estar en la misma Wi-Fi, deja la API encendida normalmente y abre una tercera terminal:

```powershell
.\scripts\iniciar_tunel.ps1
```

El programa mostrará una URL que inicia con `https://` y termina en `trycloudflare.com`. Copia esa URL y úsala al crear el APK, agregando `/api` al final:

```powershell
flutter build apk --release --dart-define=API_URL=https://TU_URL.trycloudflare.com/api --dart-define=GOOGLE_CLIENT_ID=TU_CLIENT_ID.apps.googleusercontent.com
```

La URL es temporal: deja abiertas la terminal de la API y la del túnel. Si cierras el túnel, al abrirlo otra vez recibirás una URL diferente y tendrás que crear otro APK. Es solo para pruebas: cualquiera que conozca la URL puede intentar conectarse a la API.

### Publicar la API en Render

Para que la aplicación funcione aunque la computadora esté apagada, se puede publicar la API en Render:

1. Entra a [Render](https://render.com/) e inicia sesión con GitHub.
2. Elige **New +** → **Blueprint** y selecciona el repositorio `luismedinadl/CitaApp`.
3. Render leerá el archivo `render.yaml`. En `GOOGLE_CLIENT_ID`, pega el Client ID web de Google.
4. Al terminar, Render mostrará una URL similar a `https://citaapp-api.onrender.com`.
5. Crea un APK nuevo usando esa URL:

```powershell
flutter build apk --release --dart-define=API_URL=https://citaapp-api.onrender.com/api --dart-define=GOOGLE_CLIENT_ID=TU_CLIENT_ID.apps.googleusercontent.com
```

La base SQLite es adecuada para la demostración. En un proyecto real, se debe usar una base de datos administrada para conservar la información aun después de reinicios o nuevas publicaciones.

## Administrador

Antes de usar las opciones de administración, crea una cuenta de administrador:

```powershell
python backend/server.py --create-admin admin@tunegocio.com
```

El programa pedirá una contraseña. Después inicia el servidor normalmente e inicia sesión con esa cuenta. La base de datos se crea cuando inicias el servidor.
