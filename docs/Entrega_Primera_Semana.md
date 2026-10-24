# Preparacion del entorno e integracion continua de CitaApp

## Portada

**Alumno:** [Escribe tu nombre completo]  
**Materia:** [Escribe el nombre de la materia]  
**Grupo:** [Escribe tu grupo]  
**Fecha:** [Escribe la fecha de entrega]  

---

## 1. Descripcion y objetivo del proyecto

CitaApp es una aplicacion movil para organizar las citas de un pequeno negocio, como una barberia. Los clientes pueden crear una cuenta, iniciar sesion, consultar los servicios y reservar o cancelar una cita. La persona administradora puede agregar servicios, cambiar su orden, consultar la agenda y modificar los horarios disponibles.

El objetivo del proyecto es facilitar el control de las citas en un solo lugar, evitando que el negocio tenga que anotarlas manualmente. Tambien permite que cada cliente consulte los horarios disponibles antes de reservar.

## 2. Herramientas y versiones utilizadas

| Herramienta | Uso en el proyecto | Version |
| --- | --- | --- |
| Flutter | Desarrollo de la aplicacion movil | [Escribe la version mostrada por `flutter --version`] |
| Dart | Lenguaje principal de la aplicacion | SDK 3.13.5 o compatible |
| Firebase Authentication | Registro e inicio de sesion | Servicio de Firebase |
| Cloud Firestore | Guardar servicios, citas y disponibilidad | Servicio de Firebase |
| firebase_core | Conexion inicial con Firebase | 4.15.0 |
| firebase_auth | Autenticacion con correo y Google | 6.7.0 |
| cloud_firestore | Base de datos en la nube | 6.10.0 |
| google_sign_in | Inicio de sesion con Google | 7.2.0 |
| Git | Control de versiones | [Escribe la version mostrada por `git --version`] |
| GitHub Actions | Integracion continua | Servicio de GitHub |

## 3. Estructura del proyecto

La aplicacion esta organizada para separar la interfaz, la logica y la configuracion de Android.

```text
CitaApp/
|-- android/                 Configuracion de Android y Firebase
|-- lib/                     Codigo Dart de la aplicacion
|   |-- main.dart             Pantallas y navegacion
|   |-- api.dart              Modelos y acceso a Firebase
|   |-- google_auth.dart      Inicio de sesion con Google
|-- docs/                    Documentacion del proyecto
|-- .github/workflows/       Flujo de integracion continua
|-- pubspec.yaml             Dependencias de Flutter
|-- README.md                Instrucciones del proyecto
```

La funcionalidad principal ya se puede ejecutar: una persona puede iniciar sesion, consultar servicios y reservar una cita. La informacion se guarda en Firebase.

**Captura 1.** Inserta aqui una captura del explorador de archivos de Visual Studio Code mostrando las carpetas principales.

## 4. Repositorio de GitHub

El codigo fuente se guarda en un repositorio propio de GitHub:

https://github.com/luismedinadl/CitaApp

Git se utiliza para registrar los cambios realizados durante el desarrollo. Cada commit representa una mejora concreta del proyecto.

## 5. Evidencias de commits

El proyecto debe tener al menos cinco commits significativos. Estos son los commits que se pueden mostrar en la evidencia:

| Numero | Mensaje del commit | Que demuestra |
| --- | --- | --- |
| 1 | `feat: crear CitaApp con API` | Creacion inicial de la aplicacion y su funcionalidad principal. |
| 2 | `feat: permitir API en red local` | Ajuste para probar la aplicacion en otro dispositivo. |
| 3 | `feat: agregar inicio con Google y tunel temporal` | Integracion del inicio de sesion con Google. |
| 4 | `feat: preparar API para Render` | Preparacion de una alternativa de conexion remota. |
| 5 | `feat: migrar CitaApp a Firebase` | Cambio a Firebase Authentication y Cloud Firestore. |
| 6 | `ci: agregar validacion automatica de Flutter` | Creacion del flujo de integracion continua. |
| 7 | `docs: actualizar instrucciones de Firebase` | Actualizacion del README con las instrucciones actuales. |

Los commits 5, 6 y 7 se realizan antes de entregar esta evidencia. Los mensajes se deben usar solo despues de subir los cambios correspondientes.

**Captura 2.** Inserta una captura de la pagina principal del repositorio en GitHub mostrando los commits.

## 6. Flujo de integracion continua

Se configuro GitHub Actions mediante el archivo `.github/workflows/flutter-ci.yml`. El flujo se ejecuta automaticamente cada vez que se suben cambios a la rama `main` o se crea un pull request.

El flujo realiza tres validaciones:

1. Descarga las dependencias con `flutter pub get`.
2. Revisa el codigo con `flutter analyze`.
3. Compila una APK de prueba con `flutter build apk --debug`.

Estas validaciones ayudan a detectar errores antes de continuar con otros cambios o compartir el proyecto.

**Captura 3.** Inserta una captura del archivo `flutter-ci.yml` abierto en Visual Studio Code.

## 7. Ejecucion exitosa del flujo

Despues de subir los cambios, se debe abrir la pestana **Actions** del repositorio en GitHub. Cuando las tres validaciones terminan correctamente, GitHub muestra una marca verde.

La ejecucion exitosa demuestra que el proyecto pudo descargar sus dependencias, revisar el codigo y compilar una APK automaticamente.

**Captura 4.** Inserta una captura de la ejecucion exitosa en GitHub Actions, donde se vea la marca verde y los tres pasos terminados.

## 8. Error provocado y correccion

Para comprobar que el flujo detecta errores, se realizara una prueba controlada. Se puede cambiar temporalmente el nombre de una variable en `lib/api.dart` por un nombre inexistente. Por ejemplo, cambiar una referencia valida por `correoNoExiste` sin declararla.

Al subir ese cambio, el paso `flutter analyze` debe fallar y GitHub Actions mostrara una marca roja. Esto demuestra que la validacion automatica detecto el error.

Despues se restaura el nombre correcto de la variable y se vuelve a subir el cambio. El flujo debe ejecutarse nuevamente y terminar en verde.

**Captura 5.** Inserta una captura de la ejecucion fallida donde se vea el error de analisis.

**Captura 6.** Inserta una captura de la ejecucion exitosa despues de corregir el error.

## 9. Conclusion personal

La integracion continua es util porque revisa el proyecto automaticamente cada vez que se suben cambios. En este caso, GitHub Actions ayuda a comprobar que CitaApp sigue compilando y que el analizador no detecta errores en el codigo. Esto permite encontrar problemas antes de instalar la aplicacion en un celular o continuar con nuevas funciones. Tambien facilita trabajar de forma mas ordenada, porque cada cambio queda registrado en GitHub y puede revisarse con claridad.

