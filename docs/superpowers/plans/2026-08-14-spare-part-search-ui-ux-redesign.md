# Spare Part Search UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Rediseñar visualmente el flujo Flutter de búsqueda de repuestos manteniendo tres pasos, eliminando espacio muerto, fijando el CTA y mejorando vehículos, mapa, feedback y fluidez.

**Architecture:** SparePartWizardPage seguirá siendo la fuente de verdad y controlará un PageView sin swipe. El chrome compartido vivirá en parts enfocados, los steps quedarán libres de CTA y la ubicación seguirá siendo un valor local confirmado desde un selector fullscreen.

**Tech Stack:** Flutter/Dart, Material, Riverpod 2.5, flutter_map 7.0.2, latlong2, geolocator, geocoding, image_picker y Hanken Grotesk.

## Estado de implementación · 2026-08-14

- [x] Tasks 1–7 implementadas en `codex/spare-part-ui`.
- [x] Siete ilustraciones generadas de forma independiente, normalizadas a
  512×320 con alpha y exportadas en PNG de compatibilidad y WebP v2.
- [x] Cards verticales, carrusel paginado, indicador `Vehículo N de total` y
  precarga limitada a los tipos presentes.
- [x] Iconografía semántica para raíces, subcategorías y resultados de búsqueda.
- [x] Logo de marca libre de marco en los resúmenes de los pasos 2 y 3.
- [x] Build Web y acceso HTTP 200 verificados para los catorce assets declarados.
- [ ] Matriz completa de capturas de Task 8 y saneamiento de la suite global:
  se mantienen diferidos porque existen fallos ajenos en Home/header/skeleton y
  esos tres archivos contienen cambios locales que este plan debe preservar.

**Decisión de compatibilidad Web:** el runtime mantiene los alias PNG históricos
en `assets/images/vehicles/` para evitar la regresión 404 observada durante hot
reload. Los WebP v2 también se declaran y empaquetan, y quedan disponibles para
una migración posterior con reinicio completo del bundle.

## Global Constraints

- Mantener exactamente tres pasos: Vehículo, Repuesto y Detalles.
- Priorizar UI/UX; pruebas automatizadas y goldens se harán después.
- No agregar dependencias ni modificar backend, REST, matching o persistencia.
- DESIGN_SYSTEM.md manda: Hanken Grotesk, fondo #F5F6FA, primario #F25C05, CTA pill y superficies blancas.
- Usar AppColors, AppSpacing y AppTypography; evitar tamaños tipográficos ad hoc.
- Touch targets mínimos de 48 dp.
- Respetar safe areas, text scale 2.0, reduced motion y anchos de 320 a 430 dp.
- Preservar cambios locales ajenos en user_role.dart, home_header_expanded.dart y skeleton_loader.dart.
- No usar los PNG actuales como set final: están duplicados o mal etiquetados.
- La ubicación elegida pertenece únicamente a la solicitud.
- Antes de cada commit: dart format sobre archivos tocados y flutter analyze.

---

## File Structure

### Crear

- lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_chrome.dart — header, progreso y barra inferior.
- lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_summary.dart — contexto editable.
- lib/features/home/presentation/widgets/spare_part_wizard/vehicle_option_card.dart — tarjeta adaptativa.
- assets/images/vehicles/v2/compact.webp
- assets/images/vehicles/v2/sedan.webp
- assets/images/vehicles/v2/sport.webp
- assets/images/vehicles/v2/suv.webp
- assets/images/vehicles/v2/pickup.webp
- assets/images/vehicles/v2/van.webp
- assets/images/vehicles/v2/motorcycle.webp

### Modificar

- pubspec.yaml
- lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart
- lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step1.dart
- lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step2.dart
- lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_step3.dart
- lib/features/home/presentation/widgets/spare_part_wizard/category_subcategory_selector_sheet.dart
- lib/features/home/presentation/widgets/form_parts/form_part_type_selector.dart
- lib/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart
- lib/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart
- lib/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart

### Referencias visuales disponibles

- docs/superpowers/assets/vehicle-art-direction.png
- docs/superpowers/assets/vehicle-examples/*.png

Son referencias de dirección y no deben incorporarse directamente como runtime final.

---

### Task 1: Construir el shell compacto y el CTA persistente

**Files:**
- Create: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_chrome.dart
- Modify: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart
- Modify: los tres archivos spare_part_wizard_step*.dart

**Interfaces:**
- Consumes: currentStep, label, enabled, loading, error y callbacks.
- Produces: _WizardHeader, _WizardBottomBar y navegación por PageController.

- [ ] **Step 1: Añadir controller y estado de UI**

~~~dart
part 'spare_part_wizard_chrome.dart';

late final PageController _pageController;
bool _isSubmitting = false;
String? _submitError;

@override
void initState() {
  super.initState();
  _pageController = PageController();
  _selectedVehicle = widget.initialVehicle;
  _temporaryModelId = widget.initialVariantId;
}

@override
void dispose() {
  _pageController.dispose();
  _detailsController.dispose();
  super.dispose();
}
~~~

Eliminar el listener global de _detailsController. El contador y la validez textual se actualizarán localmente.

- [ ] **Step 2: Centralizar validación y acción**

~~~dart
String get _primaryLabel => switch (_currentStep) {
  1 || 2 => 'Continuar',
  _ => _isSubmitting ? 'Enviando solicitud…' : 'Enviar solicitud',
};

bool get _canUsePrimaryAction => switch (_currentStep) {
  1 => _selectedVehicle != null,
  2 => _selectedSubcategory != null && _selectedPartType != null,
  _ => _requestLocation != null &&
      (_selectedSubcategory?.id != kOtherSubcategoryId ||
       _detailsController.text.trim().isNotEmpty),
};
~~~

- [ ] **Step 3: Reemplazar AnimatedSwitcher por PageView**

~~~dart
Future<void> _goToStep(int nextStep) async {
  if (nextStep < 1 || nextStep > 3 || nextStep == _currentStep) return;
  FocusManager.instance.primaryFocus?.unfocus();
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  setState(() {
    _currentStep = nextStep;
    _submitError = null;
  });
  if (reduceMotion) {
    _pageController.jumpToPage(nextStep - 1);
  } else {
    await _pageController.animateToPage(
      nextStep - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}
~~~

Usar PageView con NeverScrollableScrollPhysics y los tres pasos como hijos estables.

- [ ] **Step 4: Implementar header**

~~~dart
class _WizardHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  const _WizardHeader({required this.step, required this.onBack});

  @override
  Widget build(BuildContext context) {
    const labels = ['Vehículo', 'Repuesto', 'Detalles'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 10),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Volver',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Text(
                    'Paso $step de 3 · ' + labels[step - 1],
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _WizardProgress(step: step),
        ],
      ),
    );
  }
}
~~~

El progreso usa tres AnimatedContainer de 4 dp, 240 ms y easeOutCubic.

- [ ] **Step 5: Implementar barra inferior**

~~~dart
class _WizardBottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onPressed;

  const _WizardBottomBar({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.errorMessage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.errorInk,
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: enabled && !loading ? onPressed : null,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
~~~

- [ ] **Step 6: Quitar CTA de cada step y unificar back**

Cada step termina tras el contenido y usa padding inferior 24. Envolver el scaffold con PopScope: pasos 2/3 retroceden; paso 1 confirma descarte solo si el usuario modificó el borrador.

- [ ] **Step 7: Verificar y commit**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard
flutter analyze
flutter run
git add lib/features/home/presentation/widgets/spare_part_wizard
git commit -m "refactor: build compact spare part wizard shell"
~~~

Revisar título sin vacío, CTA estable, teclado y back físico.

---

### Task 2: Sustituir assets y rediseñar vehículo

**Files:**
- Create: assets/images/vehicles/v2/*.webp
- Create: lib/features/home/presentation/widgets/spare_part_wizard/vehicle_option_card.dart
- Modify: pubspec.yaml
- Modify: lib/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart
- Modify: spare_part_wizard_page.dart y spare_part_wizard_step1.dart

**Interfaces:**
- Consumes: UserCar, selected, callback y ancho.
- Produces: siete imágenes correctas y tarjeta single/carousel.

- [ ] **Step 1: Generar siete assets individuales**

Usar una llamada ImageGen por vehículo con este prompt base:

~~~text
Use case: stylized-concept
Asset type: Flutter mobile vehicle-card illustration
Subject: [compact | sedan | sport coupe | SUV | pickup | cargo van | motorcycle]
Style: refined technical automotive illustration, crisp charcoal #22272E outline,
warm off-white panels, minimal cool-gray shading, one restrained #F25C05 accent.
Composition: three-quarter front view, centered, same scale and perspective.
Backdrop: perfectly flat #00FF00 chroma key.
Constraints: unmistakable at 120x75 dp, no logo, text, watermark, shadow or reflection.
~~~

Aplicar remove_chroma_key.py, encajar en canvas 512x320 y exportar WebP calidad 88. Objetivo: 80 KB o menos por archivo.

- [ ] **Step 2: Declarar carpeta v2**

~~~yaml
flutter:
  assets:
    - assets/images/vehicles/
    - assets/images/vehicles/v2/
~~~

- [ ] **Step 3: Corregir mapping y decode**

~~~dart
static String getAssetPath(String type) {
  return switch (type.trim().toUpperCase()) {
    'COMPACT' || 'HATCHBACK' => 'assets/images/vehicles/v2/compact.webp',
    'SPORT' || 'SPORTS' => 'assets/images/vehicles/v2/sport.webp',
    'SUV' || 'UTILITY' => 'assets/images/vehicles/v2/suv.webp',
    'PICKUP' || 'TRUCK' => 'assets/images/vehicles/v2/pickup.webp',
    'VAN' || 'MINIVAN' => 'assets/images/vehicles/v2/van.webp',
    'MOTORCYCLE' || 'MOTO' => 'assets/images/vehicles/v2/motorcycle.webp',
    _ => 'assets/images/vehicles/v2/sedan.webp',
  };
}
~~~

Calcular cacheWidth con width por devicePixelRatio, clamp 240–1024, FilterQuality.medium y excludeFromSemantics.

- [ ] **Step 4: Crear tarjeta Material**

Usar Semantics(selected: isSelected, button: true), InkWell, AnimatedScale 0.98 y AnimatedContainer. Mostrar logo una sola vez. Metadata: marca/modelo, año y tipo. El check añade señal no cromática.

- [ ] **Step 5: Adaptar un vehículo y carrusel**

~~~dart
if (cars.length == 1)
  SizedBox(
    height: 164,
    child: _VehicleOptionCard(car: cars.single, ...),
  )
else
  SizedBox(
    height: 184,
    child: ListView.separated(
      key: const PageStorageKey('wizard-vehicles'),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: cars.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, index) => SizedBox(
        width: (MediaQuery.sizeOf(context).width * .78).clamp(256, 336),
        child: _VehicleOptionCard(car: cars[index], ...),
      ),
    ),
  )
~~~

Mostrar texto Vehículo N de total para múltiples elementos.

- [ ] **Step 6: Estados**

Loading: skeleton de ancho completo. Empty: explicación y Agregar vehículo. Error: ErrorView con reintento. Data: tarjeta y Usar otro vehículo.

- [ ] **Step 7: Verificar y commit**

~~~bash
find assets/images/vehicles/v2 -maxdepth 1 -type f -exec identify -format '%f %wx%h %[channels]\n' {} \;
du -h assets/images/vehicles/v2/*
dart format lib/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart lib/features/home/presentation/widgets/spare_part_wizard
flutter analyze
git add pubspec.yaml assets/images/vehicles/v2 lib/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart lib/features/home/presentation/widgets/spare_part_wizard
git commit -m "feat: redesign wizard vehicle selection"
~~~

Validar los siete tipos a 120x75 sobre blanco, fondo y naranja suave.

---

### Task 3: Mejorar categoría y condición

**Files:**
- Create: lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_summary.dart
- Modify: spare_part_wizard_page.dart, spare_part_wizard_step2.dart
- Modify: category_subcategory_selector_sheet.dart
- Modify: lib/features/home/presentation/widgets/form_parts/form_part_type_selector.dart

**Interfaces:**
- Consumes: vehículo, árbol de categorías y PartType.
- Produces: resumen editable, búsqueda jerárquica y condición explicada.

- [ ] **Step 1: Crear resumen editable**

~~~dart
class _WizardSelectionSummary extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
}
~~~

Altura mínima 72 dp, superficie blanca, borde y acción de 48 dp. Paso 2 muestra el vehículo; Paso 3 reutiliza el componente.

- [ ] **Step 2: Insertar contexto en paso 2**

~~~text
VEHÍCULO
BMW 6 Series · 1984                           Cambiar
~~~

Cambiar vuelve al paso 1 sin borrar categoría o condición.

- [ ] **Step 3: Añadir búsqueda a la hoja**

Query vacía muestra árbol. Query de 2+ caracteres muestra hojas planas con breadcrumb. Crear:

~~~dart
class _CategorySearchResult {
  final CategoryNode leaf;
  final CategoryNode root;
  final List<String> path;
  const _CategorySearchResult({
    required this.leaf,
    required this.root,
    required this.path,
  });
  String get breadcrumb => path.join(' › ');
}
~~~

Filas de 64 dp. Sin resultados: No encontramos esa pieza y acción Elegir Otro.

- [ ] **Step 4: Explicar condición**

Cada opción respeta el contrato actual y muestra label y descripción: Performance — Alto rendimiento; Original — Marca del fabricante; Genérico — Alternativo/compatible. En 320–360 dp usar columna; desde 390 dp se permite fila. Añadir check y Semantics selected.

- [ ] **Step 5: Limpiar comentarios provisionales**

Retirar del paso 2 las narraciones del proceso de desarrollo y conservar únicamente comentarios que expliquen decisiones permanentes de UX o arquitectura.

- [ ] **Step 6: Verificar y commit**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard lib/features/home/presentation/widgets/form_parts/form_part_type_selector.dart
flutter analyze
flutter run
git add lib/features/home/presentation/widgets/spare_part_wizard lib/features/home/presentation/widgets/form_parts/form_part_type_selector.dart
git commit -m "feat: clarify spare part category selection"
~~~

Revisar búsqueda, sin resultados, error, Otro y text scale 2.0.

---

### Task 4: Rediseñar detalles y fotografía

**Files:**
- Modify: spare_part_wizard_page.dart
- Modify: spare_part_wizard_step3.dart
- Modify: spare_part_wizard_summary.dart

**Interfaces:**
- Consumes: detalle, categoría, condición, imagen local y callbacks.
- Produces: resumen acumulado, contador y selector de foto explícito.

- [ ] **Step 1: Añadir resumen acumulado**

Mostrar dentro de una superficie:

~~~text
BMW 6 Series · 1984                          Cambiar
Frenos › Pastillas · Original               Editar
~~~

Cambiar vuelve a 1; Editar vuelve a 2; nunca borrar el resto del formulario.

- [ ] **Step 2: Limitar detalles a 240 caracteres**

~~~dart
TextField(
  controller: detailsController,
  minLines: 3,
  maxLines: 5,
  maxLength: 240,
  buildCounter: (_, {
    required currentLength,
    required isFocused,
    maxLength,
  }) => Text(
    '$currentLength/240',
    style: AppTypography.meta,
  ),
  decoration: const InputDecoration(
    hintText: 'Ej. lado del conductor, con sensor, color gris',
  ),
)
~~~

Para Otro, usar label DETALLES · REQUERIDOS y helper: Describe la pieza para que las tiendas puedan identificarla.

- [ ] **Step 3: Convertir Step3 a StatefulWidget**

Agregar bool _isPickingImage. Deshabilitar acciones mientras image_picker responde. Mantener la ruta final en el page state mediante onImagePicked.

- [ ] **Step 4: Mostrar acciones directas**

~~~dart
Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: _isPickingImage
            ? null
            : () => _pickImage(context, ImageSource.camera),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Tomar foto'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: OutlinedButton.icon(
        onPressed: _isPickingImage
            ? null
            : () => _pickImage(context, ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Galería'),
      ),
    ),
  ],
)
~~~

En 320 dp apilar ambos botones.

- [ ] **Step 5: Rediseñar preview**

- Aspect ratio 16:9, máximo 180 dp.
- cacheWidth según ancho físico.
- Scrim solo detrás de controles.
- Acciones Cambiar y Eliminar de 48 dp.
- Semántica Foto del repuesto seleccionada.
- Error: No pudimos abrir esa imagen. Intenta con otra foto.

- [ ] **Step 6: Evitar rebuild global por tecla**

Envolver solamente contador y barra inferior del paso 3 con ValueListenableBuilder de _detailsController.

- [ ] **Step 7: Verificar y commit**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard
flutter analyze
flutter run
git add lib/features/home/presentation/widgets/spare_part_wizard
git commit -m "feat: improve wizard details and photo UX"
~~~

Revisar teclado, 240 caracteres, Otro, cancelación, foto vertical y landscape.

---

### Task 5: Crear previsualización real y selector de mapa fluido

**Files:**
- Modify: request_location_preview.dart
- Modify: request_location_picker_dialog.dart
- Modify: request_location_selection.dart
- Modify: spare_part_wizard_step3.dart

**Interfaces:**
- Consumes: selección confirmada, LocationService y tiles Carto.
- Produces: preview no interactivo y picker con pin central.

- [ ] **Step 1: Corregir configuración de tiles**

~~~dart
TileLayer _requestTileLayer(
  BuildContext context, {
  required TileErrorCallback onError,
  Stream<void>? reset,
}) {
  return TileLayer(
    urlTemplate:
        'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    userAgentPackageName: 'com.guiautomotriz.mobile',
    retinaMode: RetinaMode.isHighDensity(context),
    reset: reset,
    errorTileCallback: onError,
  );
}
~~~

- [ ] **Step 2: Convertir preview a StatefulWidget**

Con ubicación, renderizar FlutterMap de 168 dp dentro de IgnorePointer y RepaintBoundary:

~~~dart
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(selection.latitude, selection.longitude),
    initialZoom: 15,
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.none,
    ),
  ),
  children: [
    _requestTileLayer(context, onError: _handleMapError),
    MarkerLayer(markers: [_selectionMarker(selection)]),
  ],
)
~~~

Superponer banda inferior blanca con dirección, fuente GPS/Mapa y Cambiar. El InkWell debe cubrir todo por encima del mapa.

- [ ] **Step 3: Diseñar preview vacío**

No cargar tiles. Usar superficie de 152 dp con patrón cartográfico tonal, pin y copy:

~~~text
Define dónde necesitas el repuesto
Elegir ubicación
~~~

- [ ] **Step 4: Sustituir marker por pin central**

En el modal, quitar MarkerLayer provisional y superponer:

~~~dart
Center(
  child: AnimatedSlide(
    offset: _isMapMoving ? const Offset(0, -0.12) : Offset.zero,
    duration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 140),
    curve: Curves.easeOut,
    child: _CenterLocationPin(moving: _isMapMoving),
  ),
)
~~~

- [ ] **Step 5: Actualizar borrador al finalizar el gesto**

Importar dart:async. Agregar Timer? _reverseGeocodeDebounce y cancelarlo en dispose.

~~~dart
void _handleMapEvent(MapEvent event) {
  if (event is MapEventMoveStart) {
    if (!_isMapMoving) setState(() => _isMapMoving = true);
    return;
  }
  if (event is! MapEventMoveEnd) return;
  final point = event.camera.center;
  setState(() {
    _isMapMoving = false;
    _draft = RequestLocationSelection(
      latitude: point.latitude,
      longitude: point.longitude,
      source: RequestLocationSource.mapTap,
    );
    _isResolvingAddress = true;
  });
  _reverseGeocodeDebounce?.cancel();
  _reverseGeocodeDebounce = Timer(
    const Duration(milliseconds: 450),
    () => _resolveDraftLabel(point),
  );
}
~~~

Conservar el contador de revisión existente para ignorar resultados viejos.

- [ ] **Step 6: Dar feedback de dirección**

- Moviendo: Suelta el mapa para elegir este punto.
- Resolviendo: Buscando dirección… con skeleton de una línea.
- Resultado: dirección legible.
- Fallo: coordenadas y No pudimos obtener el nombre de la calle.

La geocodificación nunca bloquea confirmar.

- [ ] **Step 7: Mejorar Mi ubicación**

Target 48 dp, spinner interno, permiso explícito y center por MapController. Al recibir GPS, actualizar borrador, fuente y dirección. Si se deniega, selección manual sigue disponible.

- [ ] **Step 8: Ajustar fullscreen**

- Header flotante de 56 dp.
- FAB de ubicación sobre panel.
- Panel con handle, dirección, fuente y CTA.
- SafeArea y scroll con text scale 2.0.
- Mapa visible mínimo de 240 dp.
- Error de tiles recuperable sin perder coordenadas.

- [ ] **Step 9: Verificar y commit**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard
flutter analyze
flutter run
git add lib/features/home/presentation/widgets/spare_part_wizard
git commit -m "feat: add fluid request map preview"
~~~

Revisar GPS, permiso denegado, drag repetido, zoom, tiles fallidos, dirección lenta, cancelar y confirmar.

---

### Task 6: Mejorar envío, error y éxito

**Files:**
- Modify: spare_part_wizard_page.dart

**Interfaces:**
- Consumes: formulario válido y searchRequestNotifierProvider.
- Produces: loading inline, error recuperable y success compacto.

- [ ] **Step 1: Eliminar overlay**

Eliminar _showLoadingOverlay y _hideLoadingOverlay. Mantener la UI visible; el CTA muestra el progreso.

- [ ] **Step 2: Bloquear dobles envíos**

~~~dart
Future<void> _submit() async {
  if (_isSubmitting || !_canUsePrimaryAction) return;
  setState(() {
    _isSubmitting = true;
    _submitError = null;
  });
  try {
    final userCarId = await _ensurePersistedVehicle();
    if (userCarId == null || !mounted) return;
    await ref.read(searchRequestNotifierProvider.notifier).submitSearch(
      userCarId: userCarId,
      subcategoryId: _selectedSubcategory!.id,
      details: _detailsController.text.trim(),
      partType: _selectedPartType!,
      fotoUrl: _selectedImagePath,
      lat: _requestLocation!.latitude,
      lon: _requestLocation!.longitude,
    );
    if (!mounted) return;
    final result = ref.read(searchRequestNotifierProvider);
    if (result.status == SearchRequestStatus.success) {
      _showSuccessDialog();
    } else {
      setState(() {
        _submitError =
            result.errorMessage ?? 'No pudimos enviar la solicitud.';
      });
    }
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
~~~

Extraer _ensurePersistedVehicle sin cambiar lógica.

- [ ] **Step 3: Rediseñar success sheet**

~~~text
[check]
Solicitud enviada
Ya estamos buscando tiendas cercanas.

BMW 6 Series · Pastillas de freno

[ Entendido ]
~~~

Check de 420 ms easeOutBack o estado final inmediato con reduced motion. Copy breve y honesto.

- [ ] **Step 4: Recuperar error**

Mostrar el error sobre el CTA. Rehabilitarlo con label Reintentar envío. Conservar vehículo, categoría, detalle, foto y mapa.

- [ ] **Step 5: Verificar y commit**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart
flutter analyze
flutter run
git add lib/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart
git commit -m "feat: improve spare part request feedback"
~~~

Simular doble toque, vehículo temporal, error de red y success.

---

### Task 7: Pulir motion, accesibilidad y rendimiento

**Files:**
- Modify: todos los componentes tocados en Tasks 1–6.

**Interfaces:**
- Consumes: UI final.
- Produces: experiencia consistente y adaptable.

- [ ] **Step 1: Aplicar motion**

| Evento | Duración | Curva |
|---|---:|---|
| Paso | 300 ms | easeOutCubic |
| Progreso | 240 ms | easeOutCubic |
| Selección | 180 ms | easeOut |
| Press | 90 ms | easeOut |
| Pin | 140 ms | easeOut |
| Success | 420 ms | easeOutBack |

Con MediaQuery.disableAnimationsOf, usar Duration.zero.

- [ ] **Step 2: Añadir semántica**

Etiquetas:

- Paso 1 de 3, Vehículo.
- BMW 6 Series, año 1984, seleccionado.
- Categoría seleccionada: Frenos, Pastillas.
- Tipo seleccionado: Original.
- Cambiar ubicación. Ubicación actual: dirección.
- Enviar solicitud.

Excluir logos, ilustraciones e iconos decorativos.

- [ ] **Step 3: Revisar touch y responsive**

Ninguna acción menor de 48x48. Revisar 320, 360, 390 y 430 dp; text scale 1.0, 1.3 y 2.0; teclado y barras gestuales.

- [ ] **Step 4: Revisar rendimiento**

- RepaintBoundary en mapas e ilustraciones.
- cacheWidth en assets y miniatura.
- Precache solo de tipos presentes.
- Sin setState de página por tecla.
- Sin animar opacidad del mapa completo.
- Retina solo en alta densidad.

- [ ] **Step 5: Verificación técnica**

~~~bash
dart format lib/features/home/presentation/widgets/spare_part_wizard lib/features/home/presentation/widgets/form_parts/form_part_type_selector.dart lib/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart
flutter analyze
git diff --check
git add lib/features/home/presentation/widgets/spare_part_wizard lib/features/home/presentation/widgets/form_parts/form_part_type_selector.dart lib/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart
git commit -m "polish: refine wizard motion and accessibility"
~~~

---

### Task 8: QA visual y preparación de pruebas posteriores

**Files:**
- Create: docs/superpowers/assets/spare-part-wizard-qa/*.png
- Modify: spec solo si una decisión visual cambia.

**Interfaces:**
- Consumes: build final.
- Produces: evidencia visual y backlog de tests.

- [ ] **Step 1: Recorrer casos**

1. Un vehículo.
2. Cuatro vehículos.
3. Garage vacío/error.
4. Categorías loading/error/sin resultados.
5. Otro.
6. Cámara/galería.
7. Ubicación manual/GPS denegado.
8. Error de tiles.
9. Envío error/success.

- [ ] **Step 2: Capturar evidencia**

~~~text
docs/superpowers/assets/spare-part-wizard-qa/
  step-1-small.png
  step-1-large.png
  step-2-small.png
  step-2-large.png
  step-3-small.png
  step-3-large.png
  map-picker.png
~~~

- [ ] **Step 3: Cerrar checklist**

- Sin espacio muerto.
- CTA visible.
- Estado preservado al volver.
- Siete assets correctos.
- Mapa real en preview.
- Pin central y debounce.
- Sin clipping a 2.0.
- Reduced motion y safe area.

- [ ] **Step 4: Registrar tests diferidos**

Fase posterior: shell/CTA, back, single/carousel, búsqueda, condición responsive, Otro, foto, mapa, debounce, permisos, doble submit, errores, success y goldens 360/430.

- [ ] **Step 5: Revisión final**

~~~bash
flutter analyze
git status --short
git diff --stat
~~~

Confirmar que no se incluyeron cambios locales ajenos.

---

## Orden de ejecución y checkpoints

1. Task 1 desbloquea la estructura.
2. Tasks 2 y 3 pueden ejecutarse en paralelo después de Task 1.
3. Task 4 depende de Task 3 por el resumen.
4. Task 5 puede ejecutarse después de Task 1.
5. Task 6 depende de Tasks 4 y 5.
6. Tasks 7 y 8 cierran el trabajo.

Checkpoint visual obligatorio después de Tasks 1, 2, 5 y 7.

## Resultado esperado

El flujo seguirá teniendo tres pasos, pero se sentirá compacto y continuo: contenido arriba, acción siempre accesible, vehículos correctos, categoría encontrable, foto comprensible, mapa reconocible y envío sin bloqueo modal. La fase posterior agregará tests de widgets y goldens sobre esta UI estabilizada.
