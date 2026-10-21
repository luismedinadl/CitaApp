# Práctica: Integración de una API

## Proyecto y problema

**CitaApp** organiza las citas de pequeños negocios que antes se controlaban con llamadas o mensajes. Evita confusión con los horarios y ayuda a clientes y administradores.

## API seleccionada

La aplicación usa una API propia: `http://127.0.0.1:8080/api`. La URL cambia a `http://10.0.2.2:8080/api` cuando se ejecuta en el emulador Android.

También usa la API pública Nager.Date: `https://date.nager.at/api/v3/PublicHolidays/{año}/MX`. Sirve para no ofrecer horarios en feriados nacionales mexicanos.

## Endpoint principal

| Dato | Valor |
|---|---|
| Endpoint | `/services` |
| Método | GET |
| Headers | `Accept: application/json` |
| Autenticación | No requerida |
| Código esperado | 200 OK |

Request:

```http
GET /api/services HTTP/1.1
Host: 127.0.0.1:8080
Accept: application/json
```

Response:

```json
{"data":[{"id":1,"name":"Corte de cabello","duration":30,"price":150.0}]}
```

La aplicación procesa el JSON en el modelo `Service` y muestra el nombre, duración y precio en la pantalla Servicios. Desde esa pantalla el cliente puede reservar una cita.

## Otros endpoints

| Método | Endpoint | Función |
|---|---|---|
| POST | `/register` | Registrar cliente |
| POST | `/login` | Iniciar sesión |
| GET | `/slots?service_id=1&date=AAAA-MM-DD` | Consultar horarios |
| GET/POST | `/appointments` | Consultar y reservar citas |
| POST | `/appointments/{id}/cancel` | Cancelar cita |
| GET | `/admin/appointments` | Consultar agenda | 

Las rutas protegidas usan el header `Authorization: Bearer TOKEN`.

## Manejo de errores

- Sin conexión: se muestra un mensaje y el botón Reintentar.
- Tiempo de espera: informa que el servidor tardó demasiado.
- Error del servidor: muestra que existe un problema en el servidor.
- Recurso no encontrado: informa que no se encontró la información.
- Respuesta inválida: informa que la respuesta no es válida.
- Error de autenticación: solicita iniciar sesión nuevamente.
- Horario ocupado: informa que el horario ya no está disponible.

## Evidencias pendientes

Después de ejecutar el proyecto, agrega capturas de: servicios cargados, horarios disponibles, cita reservada, cancelación y agenda de administrador.

## Conclusión

La API permite que CitaApp consulte información y guarde las citas. Los datos recibidos se muestran dentro de las pantallas de la aplicación y los mensajes de error ayudan al usuario cuando la conexión o el servidor fallan.
## Inicio con Google

La aplicación envía a la API un `id_token` de Google mediante `POST /api/auth/google`. La API valida ese token con Google, revisa que el correo esté verificado y crea una sesión propia de CitaApp. No guarda la contraseña de Google.

La ruta pide que la variable `GOOGLE_CLIENT_ID` esté configurada y que `google-auth` esté instalado con `py -m pip install -r backend/requirements.txt`.
