# Auto Location Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar y utilizar automáticamente en el paso 3 la última ubicación disponible en sesión, sin abrir el selector.

**Architecture:** `SparePartWizardPage` resolverá una única ubicación efectiva mediante `resolveRequestLocationSeed`. El preview, la validación, el envío y el selector consumirán ese mismo resultado para evitar estados divergentes.

**Tech Stack:** Flutter, Riverpod, flutter_test, latlong2.

## Global Constraints

- No modificar backend ni persistencia.
- Mantener prioridad solicitud → GPS compartido → perfil → vacío.
- El fallback sólo centra el selector y nunca habilita el envío.
- Una ubicación derivada no marca el wizard como editado.
- Preservar reduced motion, accesibilidad y layout responsive actuales.

---

### Task 1: Unificar la ubicación efectiva del wizard

**Files:**
- Modify: `lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart`
- Modify: `test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart`

**Interfaces:**
- Consumes: `_requestLocation`, `isLocationSharedProvider`, `userLocationProvider`, `authProvider.user`.
- Produces: `RequestLocationSeed _resolveEffectiveLocation()` reutilizado por preview, validación, submit y picker.

- [x] **Step 1: Escribir la prueba de regresión**

Crear un usuario autenticado con `latitude: 14.0723` y
`longitude: -87.1921`, navegar mediante la UI hasta el paso 3 y comprobar:

```dart
expect(find.text('14.0723, -87.1921'), findsOneWidget);
expect(find.text('Última ubicación guardada'), findsOneWidget);
expect(
  tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Enviar solicitud')).onPressed,
  isNotNull,
);
```

- [x] **Step 2: Ejecutar la prueba y confirmar el fallo correcto**

```bash
flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart \
  --plain-name 'shows the saved profile location in step 3 without opening the map'
```

Resultado esperado: falla porque el preview continúa vacío.

- [x] **Step 3: Implementar una única resolución efectiva**

Agregar un helper sin efectos secundarios:

```dart
RequestLocationSeed _resolveEffectiveLocation() {
  final isShared = ref.read(isLocationSharedProvider);
  final current = ref.read(userLocationProvider).valueOrNull;
  final user = ref.read(authProvider).user;
  return resolveRequestLocationSeed(
    requestSelection: _requestLocation,
    gpsLatitude: isShared ? current?.latitude : null,
    gpsLongitude: isShared ? current?.longitude : null,
    profileLatitude: user?.latitude,
    profileLongitude: user?.longitude,
  );
}
```

Usar `seed.selection` en `_openRequestLocationPicker`, `_submit`,
`_canUsePrimaryAction` y al construir `SparePartWizardStep3`. En `build`, observar
los tres providers para que una sesión hidratada después del primer frame vuelva
a construir el preview.

- [x] **Step 4: Ejecutar pruebas verdes y verificación**

```bash
dart format lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart \
  test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
flutter test test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
dart analyze lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart \
  test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart
flutter build web --debug --no-wasm-dry-run
```

- [x] **Step 5: Confirmar alcance y commit**

```bash
git add lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart \
  test/features/home/presentation/widgets/spare_part_wizard_preselection_test.dart \
  docs/superpowers/plans/2026-08-14-auto-location-preview.md
git commit -m "fix: show saved location in wizard preview"
```
