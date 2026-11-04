# guiautomotriz_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android release

Release builds default to the production environment so they never point to
the Android emulator host (`10.0.2.2`). For a client delivery, keep the API URL
explicit in the build command:

```bash
flutter build apk --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://guia-api-test.onrender.com/api \
  --dart-define=CARTO_BASEMAP_API_KEY=YOUR_CARTO_BASEMAP_API_KEY
```

After building, verify the artifact before sharing it:

```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk \
  lib/arm64-v8a/libapp.so | strings | rg guia-api-test.onrender.com
```

## Avisos de actualización (iOS y Android)

La app consulta la versión pública de App Store / Google Play al abrirse y al
volver al primer plano. Cuando encuentra una versión más reciente muestra
**Actualizar** (abre la tienda) y **Más tarde**. El recordatorio de una
actualización opcional se repite después de un día. La consulta no bloquea el
arranque ni borra la sesión cuando falla la red o la tienda.

Las actualizaciones son siempre opcionales. **Más tarde** y el botón Atrás
cierran el aviso y permiten seguir usando la app, incluso si la tienda indica
una versión mínima o una actualización crítica. Esos indicadores tampoco
omiten el intervalo de un día entre recordatorios. Si la tienda no abre, se
muestra un error con opción de reintentar o continuar usando la app.

Esto funciona a partir de la primera versión instalada que incluya este código;
no modifica versiones antiguas ya distribuidas. La detección depende de la
ficha pública: las versiones de TestFlight, las pruebas internas de Play y los
APK enviados directamente no sirven como fuente de nuevas versiones. Si la
tienda no proporciona una versión válida, no se impide el acceso.
Google Play se consulta mediante su página pública, con las limitaciones de
disponibilidad documentadas por [upgrader](https://pub.dev/packages/upgrader).

Un cierre nativo anterior al primer frame de Flutter requiere revisar el reporte
de crash de Xcode Organizer / App Store Connect o Android Vitals; el aviso no
corrige ese tipo de cierre por sí mismo.
