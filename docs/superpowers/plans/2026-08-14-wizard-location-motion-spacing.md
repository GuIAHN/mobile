# Wizard Location, Motion and Spacing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inicializar el mapa de búsqueda desde la mejor ubicación disponible en sesión y refinar motion y espaciado del wizard sin tocar backend.

**Architecture:** Una función pura resolverá la semilla del mapa con prioridad solicitud → GPS → perfil → fallback. `SparePartWizardPage` seguirá siendo la fuente de verdad y consumirá el usuario de `authProvider`; el `PageView`, header y pasos sólo recibirán ajustes visuales y de motion.

**Tech Stack:** Flutter/Dart, Riverpod 2.6, geolocator, latlong2, flutter_map y flutter_test.

## Global Constraints

- No modificar backend, endpoints ni persistencia.
- Mantener exactamente tres pasos y el CTA persistente.
- No solicitar GPS automáticamente.
- Respetar `MediaQuery.disableAnimationsOf(context)`.
- Mantener touch targets de 48 dp, text scale 2.0 y anchos 320–430 dp.
- Preservar cambios locales en `user_role.dart`, `home_header_expanded.dart` y `skeleton_loader.dart`.
- Aplicar TDD: prueba roja, implementación mínima y prueba verde.

---

### Task 1: Resolver la ubicación inicial desde la sesión

**Files:**
- Create: `lib/features/home/presentation/widgets/spare_part_wizard/request_location_seed.dart`
- Create: `test/features/home/presentation/widgets/request_location_seed_test.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart`

**Interfaces:**
- Consumes: selección local, coordenadas GPS, coordenadas de `authProvider.user` y fallback.
- Produces: `RequestLocationSeed resolveRequestLocationSeed(...)` con `selection` y `center`.

- [x] **Step 1: Escribir pruebas rojas de prioridad y validación**

Crear casos literales para:

```dart
expect(
  resolveRequestLocationSeed(
    requestSelection: request,
    gpsLatitude: 10,
    gpsLongitude: -66,
    profileLatitude: 14,
    profileLongitude: -87,
  ).selection,
  same(request),
);
```

Agregar casos GPS sobre perfil, perfil sin GPS, fallback sin datos y rechazo de
`NaN`, latitud 91 y longitud 181.

- [x] **Step 2: Ejecutar la prueba y confirmar fallo por API inexistente**

```bash
flutter test test/features/home/presentation/widgets/request_location_seed_test.dart
```

- [x] **Step 3: Implementar la función pura**

```dart
class RequestLocationSeed {
  final RequestLocationSelection? selection;
  final LatLng center;
  const RequestLocationSeed({required this.selection, required this.center});
}

RequestLocationSeed resolveRequestLocationSeed({
  RequestLocationSelection? requestSelection,
  double? gpsLatitude,
  double? gpsLongitude,
  double? profileLatitude,
  double? profileLongitude,
  LatLng fallback = const LatLng(14.0723, -87.1921),
}) {
  if (requestSelection != null) {
    return RequestLocationSeed(
      selection: requestSelection,
      center: LatLng(
        requestSelection.latitude,
        requestSelection.longitude,
      ),
    );
  }
  if (isValidRequestCoordinates(gpsLatitude, gpsLongitude)) {
    final selection = RequestLocationSelection(
      latitude: gpsLatitude!,
      longitude: gpsLongitude!,
      source: RequestLocationSource.gps,
    );
    return RequestLocationSeed(
      selection: selection,
      center: LatLng(selection.latitude, selection.longitude),
    );
  }
  if (isValidRequestCoordinates(profileLatitude, profileLongitude)) {
    final selection = RequestLocationSelection(
      latitude: profileLatitude!,
      longitude: profileLongitude!,
      source: RequestLocationSource.profile,
    );
    return RequestLocationSeed(
      selection: selection,
      center: LatLng(selection.latitude, selection.longitude),
    );
  }
  return RequestLocationSeed(selection: null, center: fallback);
}
```

Añadir `profile` a `RequestLocationSource`.

- [x] **Step 4: Integrar el usuario autenticado en el picker**

En `_openRequestLocationPicker`, leer `ref.read(authProvider).user` y pasar sus
coordenadas al resolver. Usar `seed.selection` como `initialSelection` y
`seed.center` como `initialCenter`. No escribir en `authProvider` ni llamar
`updateProfile`.

- [x] **Step 5: Ejecutar pruebas verdes**

```bash
dart format lib/features/home/presentation/widgets/spare_part_wizard test/features/home/presentation/widgets/request_location_seed_test.dart
flutter test test/features/home/presentation/widgets/request_location_seed_test.dart
```

---

### Task 2: Identificar la ubicación guardada en mapa y preview

**Files:**
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart`
- Modify: `test/features/home/presentation/widgets/request_location_preview_test.dart`
- Modify: `test/features/home/presentation/widgets/request_location_picker_dialog_test.dart`

**Interfaces:**
- Consumes: `RequestLocationSelection(source: RequestLocationSource.profile)`.
- Produces: etiqueta visible y semántica `Última ubicación guardada`.

- [x] **Step 1: Escribir pruebas rojas del origen profile**

Renderizar preview y picker con una selección `profile`; comprobar que muestran
`Última ubicación guardada`, mantienen el centro recibido y permiten confirmar
sin mover el mapa.

- [x] **Step 2: Ejecutar y confirmar el fallo por etiqueta inexistente**

```bash
flutter test test/features/home/presentation/widgets/request_location_preview_test.dart test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
```

- [x] **Step 3: Implementar un label exhaustivo por origen**

```dart
String get requestLocationSourceLabel => switch (selection.source) {
  RequestLocationSource.gps => 'Ubicación GPS',
  RequestLocationSource.profile => 'Última ubicación guardada',
  RequestLocationSource.mapTap => 'Elegida en el mapa',
};
```

Reutilizarlo en preview, panel del picker y semántica. Si no hay dirección,
mostrar coordenadas sin bloquear el CTA.

- [x] **Step 4: Ejecutar pruebas verdes**

```bash
flutter test test/features/home/presentation/widgets/request_location_preview_test.dart test/features/home/presentation/widgets/request_location_picker_dialog_test.dart
```

---

### Task 3: Suavizar la transición y añadir microinteracciones contenidas

**Files:**
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_chrome.dart`
- Modify: `test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

**Interfaces:**
- Consumes: `currentStep`, `PageController` y reduced motion.
- Produces: navegación 360 ms y título del header con slide/fade de 180 ms.

- [x] **Step 1: Escribir pruebas rojas de motion observable**

Agregar getters `@visibleForTesting` para `debugWizardPage` y verificar que en
modo normal, a mitad de la transición, la página está entre 0 y 1; tras
`pumpAndSettle` está en 1. Con `disableAnimations: true`, debe saltar a 1 en el
primer frame.

- [x] **Step 2: Ejecutar y observar que la duración/comportamiento actual falla**

```bash
flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
```

- [x] **Step 3: Ajustar PageView y header**

Usar 360 ms con `Curves.easeInOutCubicEmphasized`. Reemplazar únicamente el
texto central del header por `AnimatedSwitcher` de 180 ms, transición
`FadeTransition` + `SlideTransition(begin: Offset(0, .12))`. Reduced motion
usa `Duration.zero`.

- [x] **Step 4: Mantener las microinteracciones existentes**

Conservar escala de press en cards, progreso de 240 ms y label del CTA de
160 ms. No añadir animación a mapas, listas ni superficies completas.

- [x] **Step 5: Ejecutar pruebas verdes**

```bash
flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
```

---

### Task 4: Aumentar el ritmo vertical entre secciones

**Files:**
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step1.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step2.dart`
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step3.dart`
- Modify: `test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

**Interfaces:**
- Consumes: layout actual de cada paso.
- Produces: gaps mayores entre grupos, manteniendo controles relacionados juntos.

- [x] **Step 1: Añadir matriz responsive roja**

Renderizar el wizard en 320×667, 390×844 y 430×932 con text scale 1 y 2;
navegar hasta los pasos disponibles y comprobar `tester.takeException()` nulo.

- [x] **Step 2: Aplicar espaciado**

- Paso 1: introducción → garaje, 28 dp.
- Paso 2: introducción → resumen, 24 dp; resumen → categoría, 32 dp;
  categoría → tipo, 32 dp.
- Paso 3: introducción → resúmenes, 24 dp; entre resúmenes, 12 dp; grupo de
  resúmenes → detalles, 32 dp; detalles → ubicación, 32 dp; ubicación → foto,
  32 dp.
- Encabezado de sección → control: 10–12 dp.

- [x] **Step 3: Ejecutar la matriz verde**

```bash
flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
```

---

### Task 5: Verificación final y cierre

**Files:**
- Modify: `docs/superpowers/plans/2026-08-14-wizard-location-motion-spacing.md`

**Interfaces:**
- Consumes: implementación terminada.
- Produces: evidencia técnica y commit aislado.

- [x] **Step 1: Formato y diff**

```bash
dart format lib/features/home/presentation/widgets/spare_part_wizard test/features/home/presentation/widgets
git diff --check
```

- [x] **Step 2: Pruebas enfocadas**

```bash
flutter test \
  test/features/home/presentation/widgets/request_location_seed_test.dart \
  test/features/home/presentation/widgets/request_location_preview_test.dart \
  test/features/home/presentation/widgets/request_location_picker_dialog_test.dart \
  test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
```

- [x] **Step 3: Análisis y build**

```bash
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter build web --debug
```

- [x] **Step 4: Confirmar alcance y commit**

Verificar que backend y los tres archivos locales ajenos no estén staged.

```bash
git status --short
git commit -m "feat: seed wizard map from saved user location"
```
