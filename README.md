# CitaApp

CitaApp es una aplicacion movil para organizar las citas de un pequeno negocio, como una barberia.

## Objetivo

Permitir que los clientes consulten servicios y horarios, reserven una cita y la cancelen cuando sea necesario. La persona administradora puede agregar, borrar y cambiar el orden de los servicios, modificar la disponibilidad y consultar la agenda.

## Funciones principales

- Registro e inicio de sesion con correo y contrasena.
- Inicio de sesion con Google.
- Consulta de servicios disponibles.
- Reserva y cancelacion de citas.
- Panel de administracion para administrar servicios, agenda y horarios.
- Datos guardados en Firebase Authentication y Cloud Firestore.
- Consulta de feriados nacionales mexicanos con la API pública Nager.Date.

## Herramientas utilizadas

- Flutter y Dart para la aplicacion movil.
- Firebase Authentication para las cuentas de usuario.
- Cloud Firestore para los servicios, horarios y citas.
- Nager.Date para evitar reservas en feriados nacionales de México.
- Git y GitHub para el control de versiones.
- GitHub Actions para la integracion continua.

## Ejecutar el proyecto

1. Instala Flutter y Android Studio o un dispositivo Android configurado para desarrollo.
2. Clona el repositorio y abre la carpeta del proyecto.
3. Ejecuta los siguientes comandos:

```powershell
flutter pub get
flutter run
```

La aplicacion ya contiene la configuracion de Firebase para el proyecto de demostracion. Para usar otro proyecto de Firebase, registra una aplicacion Android con el paquete `com.example.citaapp` y reemplaza `android/app/google-services.json`.

Para ejecutar en Chrome, agrega `localhost` en Firebase Authentication > Configuración > Dominios autorizados y ejecuta:

```powershell
flutter run -d chrome
```

## Seguridad de Firestore

Las reglas fuente están en `firestore.rules`. Copia su contenido en Firebase Console > Firestore Database > Reglas y publícalas. Estas reglas permiten que cada cliente consulte solamente sus propias citas y reservan la administración de servicios y horarios para `admin@citaapp.com`.

## API externa

CitaApp consulta Nager.Date mediante `GET https://date.nager.at/api/v3/PublicHolidays/{año}/MX`. Si la fecha elegida es un feriado nacional, muestra su nombre y no permite reservar. No requiere clave ni token; si el servicio no responde, se informa el error y se ofrece Reintentar.

La documentación técnica de esta integración está en `docs/Practica_API.md` y los casos de prueba sugeridos están en `docs/Pruebas.md`.

## Validaciones locales

Antes de subir cambios, se pueden ejecutar estas validaciones:

```powershell
flutter analyze
flutter build apk --debug
```

## Integracion continua

El flujo de GitHub Actions se ejecuta automaticamente en cada `push` y en cada pull request hacia la rama `main`. El flujo descarga dependencias, revisa el codigo con `flutter analyze` y compila una APK de depuracion para verificar que el proyecto se pueda construir.
