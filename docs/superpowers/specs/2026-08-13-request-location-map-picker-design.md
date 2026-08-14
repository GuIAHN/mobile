# Selector de ubicación por mapa para solicitudes de repuestos

Fecha: 2026-08-13
Revisión: 2026-08-14
Estado: diseño acordado, pendiente de revisión final del usuario

## Objetivo

Permitir que una persona elija en un mapa el punto desde el cual desea solicitar un repuesto. La selección pertenece únicamente a esa solicitud: no modifica la ubicación habitual del perfil ni el estado global de ubicación de la pantalla de inicio.

El cambio también corregirá la inconsistencia actual del encabezado de inicio, donde el nombre visible puede provenir del GPS mientras las búsquedas observan otro estado de coordenadas.

## Decisiones confirmadas

- No se integrará Google Places ni un campo de autocompletado de direcciones.
- No se dividirá el mapa por sectores.
- El selector será un modal de pantalla completa.
- El asistente conservará sus tres pasos; no se añadirá un cuarto paso.
- El paso final mostrará una tarjeta resumen compacta en lugar de un mapa incrustado.
- Un toque sobre el mapa moverá el marcador al punto tocado.
- Existirá una acción visible para regresar a la ubicación GPS actual.
- La ubicación alternativa afectará solamente a la solicitud en curso.
- El backend continuará haciendo el emparejamiento por distancia desde el punto confirmado.

## Alcance

Incluye:

- Tarjeta resumen compacta de la ubicación en el paso final del asistente.
- Modal de mapa a pantalla completa.
- Selección del punto mediante toque.
- Retorno al GPS actual mediante un botón.
- Confirmación o cancelación sin efectos secundarios globales.
- Uso de las coordenadas seleccionadas al enviar la solicitud.
- Corrección de la fuente de verdad de ubicación en el encabezado de inicio.
- Estados de carga, permiso, error de GPS, error de mapa y selección confirmada.
- Pruebas de estado, interfaz y payload de red.

No incluye:

- Búsqueda escrita de direcciones.
- Persistencia de una dirección favorita o habitual.
- Modificación del perfil del usuario.
- Polígonos o catálogo de sectores.
- Rutas, navegación o cálculo de tiempo de llegada.
- Migración a Google Maps.

## Experiencia de usuario

### Paso final de la solicitud

La sección `TU UBICACIÓN` mostrará una tarjeta compacta de aproximadamente 96 dp. La tarjeta contendrá un icono de ubicación, el estado o nombre aproximado del punto seleccionado y la acción `Elegir ubicación` o `Cambiar`. No se renderizará un mapa dentro del paso 3.

- Si todavía no existe una selección y la ubicación global está compartida, se usará la posición ya disponible como punto inicial.
- Si la ubicación global está desactivada, no se solicitará permiso automáticamente: la persona podrá abrir el modal, elegir manualmente o tocar `Mi ubicación` para autorizar el GPS solo para esta solicitud.
- Si existe una selección confirmada, la tarjeta mostrará su nombre aproximado o sus coordenadas aunque el usuario regrese a pasos anteriores y vuelva al paso final.
- Tocar cualquier parte de la tarjeta abrirá el mapa de pantalla completa.
- El botón `Enviar solicitud` se habilitará cuando exista una ubicación confirmada y los demás campos requeridos sean válidos.
- Compartir la ubicación global dejará de ser un requisito para enviar una solicitud cuando ya exista un punto confirmado manualmente.
- El paso seguirá siendo desplazable para que detalles, ubicación, foto y CTA sean accesibles en teléfonos pequeños y con texto ampliado.

```text
MÁS DETALLES
[ Campo de texto                    ]

TU UBICACIÓN
┌───────────────────────────────────┐
│ [pin] Ubicación seleccionada      │
│       Nombre o coordenadas        │
│                         Cambiar > │
└───────────────────────────────────┘

AGREGAR UNA FOTO
[ Selector de foto                  ]

[ ENVIAR SOLICITUD ]
```

### Modal de pantalla completa

El modal utilizará toda la superficie disponible y respetará las áreas seguras del dispositivo.

```text
┌────────────────────────────────────┐
│  [Cerrar]   Elegir ubicación       │
│                                    │
│                                    │
│             MAPA                   │
│                                    │
│                  [Mi ubicación]    │
│                                    │
├────────────────────────────────────┤
│  Ubicación seleccionada            │
│  Nombre aproximado o coordenadas   │
│                                    │
│  [ Usar esta ubicación ]           │
└────────────────────────────────────┘
```

Interacciones:

1. Tocar cualquier punto actualiza inmediatamente el marcador y la selección provisional.
2. Desplazar o ampliar el mapa no cambia por sí solo la coordenada seleccionada.
3. `Mi ubicación` solicita una posición GPS reciente, centra el mapa y mueve el marcador a ese punto.
4. `Usar esta ubicación` devuelve el punto provisional al asistente y cierra el modal.
5. Cerrar, usar el gesto de volver o cancelar descarta los cambios provisionales y conserva la selección anterior.

El nombre obtenido mediante geocodificación inversa será informativo. Si no puede resolverse, se mostrarán las coordenadas y la selección seguirá siendo válida.

## Modelo de estado

Se introducirá un valor local e inmutable para el asistente, conceptualmente:

```text
RequestLocationSelection
  latitude: double
  longitude: double
  label: String?        // solo presentación; no requerido por el backend
  source: gps | mapTap
```

La selección confirmada vivirá en `_SparePartWizardPageState`. El modal manejará una copia provisional y solo la devolverá al confirmar.

No se utilizará `isLocationSharedProvider` como indicador de validez de la ubicación de la solicitud. Tampoco se escribirá la selección manual en `userLocationProvider`.

## Flujo de datos

```text
GPS actual ───────────────┐
                         ├─> borrador del modal
Toque sobre el mapa ──────┘          │
                                     │ confirmar
                                     v
                         selección local del asistente
                                     │
                                     │ enviar solicitud
                                     v
                         CreateSearchRequest(lat, lon)
                                     │
                                     v
                         PostGIS / tiendas por distancia
```

La prioridad para abrir el modal será:

1. Selección ya confirmada en la solicitud.
2. GPS ya disponible cuando la ubicación global esté compartida.
3. Centro predeterminado que ya utilice la aplicación, permitiendo selección manual aunque el permiso esté denegado.

El centro predeterminado no constituye una selección: el CTA permanecerá deshabilitado hasta que la persona toque el mapa o use `Mi ubicación`.

## Componentes y responsabilidades

### `RequestLocationPickerDialog`

- Presenta el mapa de pantalla completa.
- Mantiene el marcador provisional.
- Procesa los toques del mapa.
- Controla el `MapController`.
- Solicita el GPS al tocar `Mi ubicación`.
- Devuelve `RequestLocationSelection` únicamente al confirmar.

### `RequestLocationPreview`

- Muestra una tarjeta resumen compacta con el punto confirmado.
- Expone `Elegir ubicación` cuando está vacía y `Cambiar` cuando ya existe una selección.
- Presenta carga, error recuperable o ausencia de selección.
- No contiene lógica de permisos ni modifica providers globales.

### Estado del asistente

- Conserva la selección entre pasos.
- Decide si la solicitud puede enviarse.
- Envía exactamente las coordenadas confirmadas.

### `GuiaMap`

Permanecerá sin cambios para las demás pantallas que ya lo reutilizan. El paso 3 dejará de renderizarlo y la interacción del selector vivirá en un componente separado, evitando alterar mapas ajenos a este flujo.

## Corrección del encabezado de inicio

Al activar la ubicación desde el encabezado:

1. Se solicitará la posición mediante `userLocationProvider.notifier.updateLocation()`.
2. `isLocationSharedProvider` pasará a `true` solo si se obtuvo una posición válida.
3. El nombre visible se resolverá usando exactamente las coordenadas almacenadas en `userLocationProvider`.
4. Los providers de búsqueda observarán ese mismo valor, evitando que el chip muestre una ubicación distinta de la enviada al backend.
5. Si la operación falla, el estado compartido permanecerá desactivado y se mostrará una recuperación clara.

Esta corrección no vincula la ubicación del encabezado con la selección manual de una solicitud.

## Backend y validación

El contrato actual ya acepta `lat` y `lon`, y `SearchRequest` ya almacena un punto geográfico. No se requiere migración de base de datos.

Se reforzará el DTO para:

- Aceptar latitud y longitud como pareja: ambas presentes o ambas ausentes.
- Validar latitud entre -90 y 90.
- Validar longitud entre -180 y 180.
- Evitar comprobaciones por valor verdadero/falso; una coordenada igual a cero también es válida.

Cuando el asistente envíe una selección, esas coordenadas tendrán prioridad sobre la ubicación guardada del usuario. El radio y el algoritmo actual de emparejamiento continuarán sin cambios.

## Estados y recuperación

### GPS cargando

- `Mi ubicación` queda temporalmente deshabilitado.
- Se muestra progreso dentro de la acción sin bloquear el mapa.

### Permiso denegado

- El mapa continúa siendo utilizable manualmente.
- Se explica que puede tocar el mapa o habilitar el permiso desde ajustes.
- La selección manual no requiere permiso de ubicación.

### GPS no disponible o con tiempo de espera agotado

- Se conserva el último marcador provisional.
- Se muestra un mensaje con acción `Reintentar`.

### Error al cargar mosaicos

- Se presenta un aviso sobre el mapa con `Reintentar`.
- Si ya había una selección confirmada, no se pierde.

### Geocodificación inversa fallida

- Se muestran latitud y longitud con precisión legible.
- No se bloquea la confirmación.

### Sin selección

- `Usar esta ubicación` permanece deshabilitado.
- Se indica: `Toca el mapa para colocar el marcador`.

## Accesibilidad y adaptación

- Acciones con área mínima de 48 dp en Android y 44 pt en iOS.
- Etiquetas semánticas para cerrar, obtener ubicación actual, marcador y confirmar.
- Mensajes de error anunciables y acompañados por una acción de recuperación.
- Contraste conforme al sistema de diseño y uso exclusivo de tokens existentes.
- Texto escalable sin ocultar el CTA inferior.
- Panel inferior protegido por `SafeArea` y contenido desplazable si el texto crece.
- El mapa conservará espacio suficiente en teléfonos pequeños y grandes, retrato y paisaje.
- No se añadirán animaciones decorativas; cualquier transición respetará reducción de movimiento.

## Estrategia de pruebas

### Pruebas unitarias

- La selección confirmada produce el `lat/lon` esperado.
- Cancelar conserva la selección anterior.
- La selección manual no cambia `userLocationProvider` ni `isLocationSharedProvider`.
- El DTO del backend acepta límites válidos y rechaza pares incompletos o fuera de rango.
- Coordenadas iguales a cero no activan el fallback del perfil.

### Pruebas de widgets

- Un toque sobre el mapa actualiza el marcador provisional.
- `Mi ubicación` centra el mapa y actualiza el marcador cuando el GPS responde.
- El error de permiso permite continuar con selección manual.
- Confirmar devuelve la selección; cerrar no la devuelve.
- Los CTA reflejan correctamente carga, deshabilitado y selección válida.
- El paso final permite enviar con una ubicación manual aunque el estado global esté desactivado.
- El encabezado usa la misma posición para nombre y búsquedas.

### Verificación visual y de accesibilidad

- Teléfono pequeño y grande, retrato y paisaje.
- Escala de texto elevada.
- Modo claro definido por el proyecto.
- TalkBack y VoiceOver para las acciones principales.
- Áreas seguras, navegación atrás y reducción de movimiento.
- Estados de carga, error, ausencia de selección y selección confirmada.

## Criterios de aceptación

- El mapa se abre como modal de pantalla completa desde la solicitud de repuesto.
- El asistente conserva tres pasos y el paso final usa una tarjeta resumen compacta, no un mapa incrustado.
- Tocar el mapa mueve el marcador al punto tocado.
- `Mi ubicación` obtiene una posición reciente, mueve el marcador y centra el mapa.
- Cancelar no modifica la ubicación previamente confirmada.
- Confirmar actualiza solo la solicitud actual.
- Enviar utiliza las coordenadas confirmadas, incluso si la ubicación global está desactivada.
- La ubicación manual nunca actualiza el perfil ni el estado global.
- El backend valida y almacena el punto seleccionado y ejecuta el emparejamiento existente.
- El encabezado muestra el nombre correspondiente a las mismas coordenadas usadas por sus búsquedas.
- Todos los estados críticos tienen feedback y recuperación.
