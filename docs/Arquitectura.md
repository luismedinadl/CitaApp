# Arquitectura de CitaApp

## Componentes

| Componente | Responsabilidad |
|---|---|
| `lib/main.dart` | Interfaz Flutter, navegación, estados de carga, mensajes y pantallas de cliente o administrador. |
| `lib/api.dart` | Modelos `Service` y `Appointment`, autenticación, operaciones de Firestore y cálculo de horarios. |
| `lib/holiday_api.dart` | Solicitud HTTPS y conversión del JSON de Nager.Date. |
| Firebase Authentication | Registro, inicio de sesión con correo o Google y administración de sesión. |
| Cloud Firestore | Servicios, citas, disponibilidad y horario del negocio. |
| Nager.Date | Feriados nacionales de México usados para bloquear reservas. |

## Flujo de información

1. La persona inicia sesión con Firebase Authentication.
2. La app consulta los servicios en Cloud Firestore.
3. Al elegir fecha, CitaApp consulta Nager.Date para saber si es un feriado nacional.
4. Si no es feriado, consulta Firestore para obtener la disponibilidad y calcula los horarios libres.
5. Al confirmar, guarda la cita y la disponibilidad en un lote de Firestore.
6. Cuando se cancela una cita, actualiza su estado y elimina el bloque de disponibilidad.

## Roles

- **Cliente:** consulta servicios, reserva, consulta sus propias citas y las cancela.
- **Administrador:** además puede agregar, eliminar y ordenar servicios, cambiar horarios y consultar la agenda completa.

El rol se muestra en la interfaz con el correo del administrador y se protege en Firestore mediante `firestore.rules`.
