# API de terceros: Nager.Date

## Propósito

CitaApp consulta los feriados nacionales de México antes de mostrar los horarios disponibles. Así se evita que una persona reserve una cita en un día no laborable del negocio.

## Proveedor y endpoint

| Dato | Valor |
|---|---|
| Proveedor | Nager.Date |
| Endpoint | `https://date.nager.at/api/v3/PublicHolidays/{año}/MX` |
| Método | `GET` |
| Parámetros | Año de la fecha seleccionada y el código de país `MX` |
| Encabezado | `Accept: application/json` |
| Autenticación | No requiere clave, token ni cuenta |
| Respuesta correcta | `200 OK` con una lista JSON de feriados |

Ejemplo de solicitud:

```http
GET /api/v3/PublicHolidays/2026/MX HTTP/1.1
Host: date.nager.at
Accept: application/json
```

Ejemplo simplificado de respuesta:

```json
[
  {
    "date": "2026-09-16",
    "localName": "Día de la Independencia",
    "name": "Independence Day"
  }
]
```

## Procesamiento en CitaApp

El archivo `lib/holiday_api.dart` realiza la solicitud HTTPS, convierte el JSON en objetos `Holiday` y guarda el resultado por año durante la sesión. `lib/api.dart` consulta ese servicio al cargar los horarios y devuelve un `SlotsResult`.

- Si la fecha coincide con un feriado, no se muestran horarios y se indica el nombre del feriado.
- Si no coincide, CitaApp consulta Firestore y calcula los horarios libres.
- Antes de guardar una cita, vuelve a validar que la fecha no sea feriado.

## Manejo de errores y límites

Nager.Date no requiere autenticación para este endpoint. La aplicación espera un máximo de ocho segundos. Si hay falta de conexión, una respuesta inválida, un error HTTP o una espera excesiva, muestra un mensaje claro y el botón **Reintentar**. No guarda ni expone credenciales para esta API.

## Justificación

La API es pertinente porque añade una validación real de calendario al proceso de reservar una cita. La información no se simula: se consulta desde el proveedor externo y se presenta dentro de la pantalla de horarios.
