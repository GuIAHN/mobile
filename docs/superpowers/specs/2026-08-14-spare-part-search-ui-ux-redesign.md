# Rediseño UI/UX del flujo de búsqueda de repuestos

Fecha: 2026-08-14  
Estado: diseño cerrado para planificación  
Prioridad: UI/UX y fluidez; automatización de pruebas diferida por solicitud del usuario

## Objetivo

Rediseñar el asistente móvil de solicitud de repuestos para que sus tres pasos sean compactos, claros, consistentes y agradables de usar, sin cambiar el contrato de negocio ni eliminar etapas. El resultado debe reducir espacio muerto, mantener siempre visible la acción principal, comunicar mejor el contexto acumulado y convertir la ubicación en una experiencia de mapa útil, no en una tarjeta genérica.

## Fuente de verdad

- La captura `/home/carlose19/Pictures/2.png` corresponde al estado actual observado por el usuario.
- El código relevante vive en `lib/features/home/presentation/widgets/spare_part_wizard/`.
- `DESIGN_SYSTEM.md` continúa siendo obligatorio.
- El diseño conserva exactamente tres pasos: Vehículo, Repuesto y Detalles.
- Esta especificación reemplaza únicamente la decisión de `2026-08-13-request-location-map-picker-design.md` que prohibía una previsualización de mapa en el paso final. El modal de pantalla completa y el aislamiento de la ubicación por solicitud se mantienen.

## Diagnóstico

### Flujo y composición

- La captura presenta más de 250 px de espacio vertical sin propósito antes del contenido principal.
- Los CTA forman parte del contenido desplazable y pueden quedar fuera de alcance en pantallas pequeñas, con teclado o texto ampliado.
- El progreso indica cantidad, pero no explica con suficiente fuerza el nombre y propósito de la etapa.
- Los pasos no muestran de forma consistente el contexto elegido anteriormente.
- El envío usa un overlay genérico que bloquea la pantalla y no explica qué operación está ocurriendo.

### Vehículos

- La tarjeta actual es estrecha incluso cuando solo existe un vehículo.
- El logo de marca se muestra dos veces en la misma tarjeta.
- La selección depende demasiado del borde/color y carece de una respuesta táctil completa.
- La tarjeta usa `GestureDetector` sin el feedback material que sí tienen otros controles.
- Las ilustraciones cargan PNG de 1024×682 para un espacio de aproximadamente 230×130.
- Los assets no representan siete tipos: `car` y `sedan` son idénticos; `motorcycle` y `sport` son idénticos; `pickup`, `suv` y `van` son idénticos. La van queda casi invisible en fondos claros.

### Mapa

- La previsualización actual es una tarjeta con icono; no permite reconocer visualmente el punto elegido.
- El modal mueve un marcador al tocar, pero el patrón obliga a apuntar con precisión y resulta menos cómodo con una mano.
- Cada selección dispara geocodificación inversa. Las respuestas antiguas se ignoran, pero las solicitudes no se agrupan.
- El tile URL fuerza `@2x` en todos los dispositivos en vez de usar densidad real.
- El progreso de geocodificación no es visible y el cambio de ubicación no tiene una transición espacial clara.

## Dirección visual

La interfaz seguirá una estética **automotriz refinada y utilitaria**:

- Superficies limpias, compactas y con jerarquía firme.
- Hanken Grotesk como única tipografía.
- Naranja `#F25C05` reservado para acción, selección y señalización.
- Carbón y grises para estructura, lectura y sensación técnica.
- Azul tecnológico solo para metadata secundaria cuando aporte significado.
- Ilustraciones vehiculares coherentes en perspectiva 3/4, con contorno carbón y acentos naranjas mínimos.
- Sin gradientes decorativos, glassmorphism, exceso de sombras ni patrones visuales genéricos.

## Estructura compartida

Cada paso usará la misma anatomía:

```text
┌────────────────────────────────────┐
│ ‹   Paso 1 de 3 · Vehículo         │  56 dp
│ ████████  ░░░░░░░  ░░░░░░░        │
├────────────────────────────────────┤
│ Título                             │
│ Texto de ayuda                     │
│                                    │
│ Contenido desplazable              │
│                                    │
├────────────────────────────────────┤
│ Acción secundaria / ayuda          │
│ [       CONTINUAR              ]   │  CTA fijo
└────────────────────────────────────┘
```

- Header fijo y compacto.
- Contenido inmediatamente debajo del progreso.
- `PageView` controlado, sin swipe, para transiciones direccionales y preservación de estado.
- Área central desplazable con clave de almacenamiento por paso.
- Barra inferior fija con `SafeArea`, fondo sólido y separador sutil.
- CTA de 56 dp, radio pill y estado de carga interno.
- Al avanzar se cierra el teclado y se mueve el foco de forma predecible.
- El back físico y el botón del header siguen la misma lógica.

## Paso 1: Vehículo

### Un vehículo

Se usa una tarjeta horizontal de ancho completo, entre 152 y 168 dp de alto:

```text
┌────────────────────────────────────┐
│ BMW                                │
│ 6 Series                  [✓]      │
│ 1984 · Sedán              vehículo │
│                    [ilustración]   │
└────────────────────────────────────┘
```

### Varios vehículos

- Carrusel horizontal con ancho de tarjeta igual al 84% del viewport.
- La tarjeta siguiente debe quedar visible entre 20 y 32 dp.
- Indicador textual `2 de 4`, no puntos decorativos.
- El scroll debe alinear cada tarjeta sin agregar una dependencia nueva.

### Interacción

- Toda la tarjeta es un control Material con ripple, escala `0.98` al presionar y semántica de radio seleccionado.
- Estado seleccionado: borde naranja de 2 px, fondo naranja suave, check con contenedor sólido y texto `Seleccionado` para lectores de pantalla.
- Logo de marca solo una vez.
- Año y tipo de vehículo se muestran como metadata, no como badges competidores.
- `Agregar vehículo` permanece como acción secundaria de ancho completo.
- Estados requeridos: carga skeleton, error recuperable, garage vacío y lista cargada.

## Paso 2: Repuesto

- Encabezado de contexto compacto con el vehículo elegido y acción `Cambiar` que vuelve al paso 1.
- Campo de categoría de 56 dp con icono de búsqueda, valor jerárquico y chevron.
- Bottom sheet de categoría con búsqueda local por nombre, resultados planos con breadcrumb y árbol explorable como fallback.
- El valor final se muestra como `Categoría › Subcategoría`.
- `Otro / no encuentro mi categoría` permanece visible al final.
- Los tipos soportados por el contrato actual se muestran en tarjetas compactas con etiqueta y explicación:
  - Performance: `Alto rendimiento`.
  - Original: `Marca del fabricante`.
  - Genérico: `Alternativo/compatible`.
- El tipo seleccionado usa borde, check e icono; no solo color.

## Paso 3: Detalles y ubicación

- Resumen compacto de vehículo, categoría y condición con acción `Editar`.
- Detalles opcionales salvo para `Otro`.
- Campo con contador `0/240`, máximo de 240 caracteres y ejemplo contextual.
- La foto ofrece dos acciones explícitas: `Tomar foto` y `Elegir de galería`.
- Una foto seleccionada muestra miniatura 16:9, botones `Cambiar` y `Eliminar`, y estado local de procesamiento.
- La ubicación muestra mapa real de solo lectura cuando existe una selección.
- Sin ubicación, la misma superficie muestra un placeholder cartográfico tonal con CTA `Elegir ubicación`.
- El botón final cambia de `Enviar solicitud` a `Enviando solicitud…` y no abre un overlay adicional.
- El error de envío aparece sobre la barra inferior con acción `Reintentar`, conservando todo el formulario.

## Previsualización y selector de mapa

### Previsualización

- Altura objetivo: 168 dp.
- `FlutterMap` no interactivo dentro de `IgnorePointer`.
- Centro y marker corresponden exactamente a la selección confirmada.
- Banda inferior blanca con dirección, fuente `GPS` o `Mapa`, y acción `Cambiar`.
- Error de tiles: placeholder cartográfico y acción `Reintentar`; nunca se pierde la coordenada.

### Modal de pantalla completa

Se usará el patrón de pin central:

1. El mapa se desplaza bajo un pin fijo en el centro.
2. Durante el gesto, el pin sube 6 dp y su sombra aumenta.
3. Al terminar el movimiento, el pin vuelve a su lugar.
4. La coordenada provisional se toma del centro de cámara.
5. La geocodificación inversa se ejecuta 450 ms después del último movimiento.
6. Respuestas anteriores quedan invalidadas por revisión.
7. `Mi ubicación` centra el mapa y actualiza el borrador.
8. Confirmar devuelve el borrador; cancelar conserva la selección anterior.

El modal mantendrá selección manual aunque el permiso GPS se niegue. La URL será `.../{z}/{x}/{y}{r}.png` con `retinaMode: RetinaMode.isHighDensity(context)`.

## Motion y fluidez

| Momento | Duración | Curva | Comportamiento |
|---|---:|---|---|
| Cambio de paso | 300 ms | `easeOutCubic` | `PageView` direccional |
| Progreso | 240 ms | `easeOutCubic` | Color y ancho sin rebote |
| Selección de tarjeta | 180 ms | `easeOut` | Borde, fondo y check |
| Press | 90 ms | `easeOut` | Escala 1 → 0.98 |
| Pin durante drag | 140 ms | `easeOut` | Traslación vertical y sombra |
| Éxito | 420 ms | `easeOutBack` | Check una sola vez |

Con `MediaQuery.disableAnimationsOf(context)`, todo cambio decorativo será instantáneo. No se animarán mapas completos ni imágenes grandes con opacidad en cada rebuild.

## Estado y responsabilidades

- `SparePartWizardPage` continúa como dueño de selección y navegación.
- Los pasos reciben valores y callbacks; no envían solicitudes.
- La barra inferior calcula su estado desde el paso actual.
- `_isSubmitting` impide dobles envíos y vive en el page state.
- El texto no debe disparar reconstrucción de los tres pasos: `ValueListenableBuilder<TextEditingValue>` actualizará contador y validez local.
- La ubicación continúa siendo local a la solicitud.
- No se cambia backend, contratos REST, providers globales ni arquitectura de dominio.

## Rendimiento

- Assets de vehículo de runtime: WebP con transparencia, calidad 88, canvas 512×320 y objetivo ≤80 KB por archivo.
- `Image.asset` usa `cacheWidth` proporcional al device pixel ratio.
- `precacheImage` carga solo los tipos presentes en el garage actual.
- Ilustraciones y mapas se envuelven en `RepaintBoundary`.
- No se agrega paquete de animación ni caché de mapas en esta fase.
- Se usa retina solo en pantallas de alta densidad.
- La geocodificación se agrupa con debounce y revisión.

## Assets

La referencia generada por ImageGen está en:

- `docs/superpowers/assets/vehicle-art-direction.png`
- `docs/superpowers/assets/vehicle-examples/compact-reference.png`
- `docs/superpowers/assets/vehicle-examples/sedan-reference.png`
- `docs/superpowers/assets/vehicle-examples/sport-reference.png`
- `docs/superpowers/assets/vehicle-examples/suv-reference.png`
- `docs/superpowers/assets/vehicle-examples/pickup-reference.png`
- `docs/superpowers/assets/vehicle-examples/van-reference.png`
- `docs/superpowers/assets/vehicle-examples/motorcycle-reference.png`

Son referencias de estilo, no archivos finales de runtime: conservan sombras editoriales y algunos detalles que deben simplificarse para lectura a tamaño pequeño.

El set final debe contener siete siluetas realmente distintas, sin logos, en la misma perspectiva y escala. Debe validarse sobre blanco, `#F5F6FA` y fondo naranja suave.

## Accesibilidad y adaptación

- Objetivos táctiles mínimos de 48 dp.
- Semántica de paso, progreso, radio seleccionado, mapa, foto y envío.
- Contraste de texto AA; naranja puro no se usa para texto pequeño sobre blanco.
- Texto a 1.0×, 1.3× y 2.0× sin clipping.
- Anchos de referencia: 320, 360, 390 y 430 dp.
- Safe areas con notch y barra gestual.
- Layout en landscape funcional, aunque no sea el foco visual.
- `FocusTraversalGroup` y orden lógico para teclado/tecnologías asistivas.

## Estados obligatorios

- Garage: loading, empty, data y error.
- Categorías: loading, empty, data y error.
- Foto: vacía, seleccionando, seleccionada y error.
- Ubicación: vacía, localizando, resolviendo dirección, seleccionada, permiso denegado y error de tiles.
- Envío: disabled, ready, submitting, error recuperable y success.

## Criterios de aceptación UI/UX

- El título del paso aparece inmediatamente debajo del header, sin espacio muerto.
- El CTA está visible y estable en los tres pasos.
- El flujo conserva siempre tres pasos y la información al retroceder.
- Un solo vehículo aprovecha todo el ancho; varios comunican scroll horizontal.
- Los siete tipos de vehículo son correctos y distinguibles a 120×75 dp.
- El paso 2 comunica vehículo, categoría y condición sin ambigüedad.
- El paso 3 muestra una previsualización real del punto confirmado.
- El mapa usa pin central, debounce y feedback de dirección.
- Enviar no abre un spinner modal y no permite doble toque.
- Reduced motion, texto ampliado y safe areas no rompen la experiencia.
- No se añaden dependencias ni cambios de backend.

## Verificación diferida

Por decisión del usuario, la implementación UI se realizará primero. Las pruebas automatizadas se planificarán después. Durante esta fase se exigirán solamente `dart format`, `flutter analyze` y revisión manual de los estados y tamaños descritos; esto no sustituye la futura cobertura de widgets y goldens.
