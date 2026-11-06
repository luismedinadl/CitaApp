# Seguridad de CitaApp

## Medidas implementadas

- Firebase Authentication administra las contraseñas y los tokens de sesión; CitaApp no almacena contraseñas en Firestore.
- El inicio con Google usa Firebase Authentication y no solicita ni guarda la contraseña de Google.
- `firestore.rules` restringe los cambios de servicios y horarios al correo administrador.
- Cada cliente solamente puede leer sus propias citas, crear citas con su propio identificador y cancelar sus propias citas.
- El formulario valida nombre, duración, precio y horarios antes de guardar datos.
- La API Nager.Date se consulta por HTTPS y no requiere una clave privada.
- Los errores mostrados a la persona usuaria son mensajes generales; no incluyen tokens ni detalles internos de Firebase.

## Riesgos y controles

| Riesgo | Control |
|---|---|
| Una persona intenta administrar servicios sin permiso. | Las reglas de Firestore verifican el correo de administrador. |
| Dos personas intentan reservar un horario ocupado. | La app vuelve a consultar disponibilidad antes de guardar y registra el bloque de horario. |
| La API de feriados no está disponible. | Se informa el error y se permite reintentar; no se reserva sin validar la fecha. |
| Se publica información sensible. | `.gitignore` excluye bases locales, archivos `.env` y compilaciones. No se deben subir cuentas de servicio ni contraseñas. |

## Configuración necesaria

Antes de publicar o entregar el código, se deben revisar y publicar las reglas de `firestore.rules` en Firebase Console. También se debe confirmar que Google Sign-In está habilitado y que el SHA-1 del APK de prueba está registrado en Firebase.
