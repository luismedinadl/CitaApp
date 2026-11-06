# Pruebas y resultados de CitaApp

Completa esta tabla con capturas al preparar la entrega final. Cada resultado debe corresponder con una ejecución real de la aplicación.

| Caso | Procedimiento | Resultado esperado | Evidencia |
|---|---|---|---|
| Registro | Crear una cuenta con correo y contraseña válida. | La persona entra a la pantalla de servicios. | Captura pendiente |
| Inicio con Google | Elegir **Continuar con Google** y seleccionar una cuenta. | La sesión se inicia con el nombre de Google. | Captura pendiente |
| Rol administrador | Entrar con `admin@citaapp.com`. | Aparecen Agenda y Negocio; un cliente no ve esas opciones. | Captura pendiente |
| Crear servicio | Como administrador, agregar nombre, duración y precio. | El servicio se guarda en Firestore y aparece ordenado. | Captura pendiente |
| Eliminar servicio | Como administrador, eliminar un servicio y confirmar. | El servicio desaparece de la lista. | Captura pendiente |
| Reservar cita | Elegir servicio, fecha libre y horario. | Se crea una cita confirmada y el horario deja de estar disponible. | Captura pendiente |
| Cancelar cita | Abrir Mis citas y confirmar cancelación. | La cita cambia a cancelada y libera el horario. | Captura pendiente |
| Feriado nacional | Elegir una fecha que Nager.Date marque como feriado, por ejemplo `2026-11-16`. | Se muestra el nombre del feriado y no se permite reservar. | Captura pendiente |
| Error de API | Desactivar Internet y cargar horarios. | Se muestra un mensaje de conexión y el botón Reintentar. | Captura pendiente |
| Prueba automática | Ejecutar `flutter test`. | Las pruebas de conversión del JSON finalizan correctamente. | Captura pendiente |

## Limitaciones conocidas

- La disponibilidad depende de que Firebase y Nager.Date estén disponibles en Internet.
- El rol de administrador está asignado al correo `admin@citaapp.com` y debe coincidir con las reglas publicadas en Firestore.
- La API de feriados cubre los feriados nacionales; no incluye días de cierre interno que el negocio no registre en Firebase.
