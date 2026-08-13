# Home móvil: Hub profesional de servicios

**Fecha:** 2026-08-13
**Estado:** Aprobado para planificación

## Objetivo

Convertir el Home del consumidor de guIAutomotriz en un hub profesional y fácil de escanear. En la primera vista, una persona debe entender y poder iniciar, con un toque, sus tres tareas principales:

1. Pedir un repuesto.
2. Buscar un taller.
3. Buscar un mecánico.

El rediseño conserva por completo la paleta primaria, Hanken Grotesk, las rutas, los datos y los flujos actuales. La mejora procede de jerarquía, copy, iconografía, geometría, fondos neutros y ritmo vertical; no de cambiar la identidad de marca.

## Alcance

Incluye únicamente el Home de usuarios consumidores y sus módulos visibles: header, selector de vehículo, acciones principales, promo y previews de talleres y mecánicos. Se mantienen los dashboards de tienda, las rutas de lista/detalle, el wizard de repuestos y la barra de navegación actual.

No incluye nuevos endpoints, cambios al modelo de proveedor, cambios de color primario, rediseño de las listas completas ni modificación de otros tabs.

## Dirección visual aprobada

El lenguaje es **profesional, operativo y confiable**:

- `AppColors.primary` sigue siendo el naranja de marca; no se modifica ningún token primario.
- `AppColors.background`, blancos, grises y bordes existentes separan las zonas de contenido. No se introducen gradientes ni nuevos colores de identidad.
- Las superficies tienen radios de 16–20 dp, bordes finos y sombras suaves ya definidas por el sistema.
- Talleres usan foto rectangular 16:9 del negocio para identificar el local. Mecánicos usan foto circular para comunicar una persona. Los fallbacks conservan la misma geometría.
- La densidad visual es contenida: una acción principal, un título y metadatos útiles por bloque; nunca adornos que compitan con la tarea.

## Estructura y experiencia

### Header y vehículo

El header naranja mantiene saludo, ubicación y acceso a chats. Se elimina el subtítulo redundante y la fila horizontal de chips de vehículos deja de ser el selector principal. En su lugar habrá un solo control de vehículo compacto, con icono, nombre/año en una línea truncable y chevron. Al tocarlo se reutiliza `GarageVehicleSelectorSheet` y se actualizan `searchVehicleProvider` y `searchVehicleVariantIdProvider` como hoy.

El control tiene al menos 48 dp de alto y las partes accionables del header alcanzan 48×48 dp. El texto del vehículo se muestra sobre superficie blanca o neutra con texto carbón; el naranja permanece como acento de icono/contorno para no depender de texto pequeño blanco sobre el fondo de marca. Esta composición elimina el overflow actual de 22 px: el chip existente fija 44 dp mientras apila marca/modelo y año, que no caben a escala 2.0.

### Acciones principales

Debajo del header aparece el título `¿Qué necesitas hoy?` y un grid de tres cards de idéntico peso. El copy aprobado es:

- `Pedir repuesto`
- `Buscar taller`
- `Buscar mecánico`

Cada card reúne una ilustración outline específica, un contenedor naranja suave, label de dos líneas como máximo y una flecha de continuidad. La card entera es un control Material/InkWell con semántica del destino, feedback táctil contenido y una zona de toque de al menos 48 dp.

Las acciones reutilizan los flujos actuales: el wizard de repuestos recibe el vehículo seleccionado, talleres navega a `RouteNames.workshops` y mecánicos a `RouteNames.mechanics`. En ancho reducido conservan tres columnas; con texto escalado crecen verticalmente y el contenido nunca se recorta.

### Ritmo de secciones

El orden del Home consumidor es:

1. Header y selector de vehículo.
2. Acciones principales.
3. Promo, cuando exista.
4. Talleres mejor valorados.
5. Mecánicos mejor valorados.

Cada bloque usa una separación vertical consistente de 24 dp. Acciones y promo permanecen sobre el canvas neutro; cada grupo de proveedores recibe una superficie o banda neutra claramente delimitada, encabezado con acento naranja y espacio interno suficiente. Las cards de proveedor blancas quedan visualmente separadas del fondo y no se mezclan con la publicidad.

### Cards de proveedores

Las previews continúan mostrando como máximo tres proveedores y preservan ranking, nombre, puntuación, reseñas, distancia, disponibilidad y especialidad.

- **Talleres:** card vertical con imagen rectangular 16:9, título, estado y metadatos agrupados en orden de decisión. La imagen usa `BoxFit.cover`; si falta o falla, aparece una ilustración de taller en el mismo marco rectangular.
- **Mecánicos:** card horizontal compacta con avatar circular, título y metadatos. El fallback es un icono de mecánico dentro de un círculo.

Loading, vacío y error siguen presentes para cada sección. Las excepciones internas no se exponen; error ofrece `Reintentar` y vacío conserva `Ver todos`.

## Componentes y datos

`HomePage` conserva su responsabilidad de composición y roles. El trabajo se limita a componentes de presentación reutilizables:

- `HomeHeaderExpanded`: control único de vehículo y header simplificado.
- `CategoryGrid` y su card: copy, iconos, flecha y adaptación tipográfica.
- Un contenedor de sección de Home, si hace falta, para aplicar fondo, padding y separación sin duplicar valores.
- `TopProvidersSection`: usa los datos/ranking existentes y diferencia por tipo la geometría de foto y fallback.

No se modifica la API. `topProvidersProvider`, `homeItemsProvider`, `userCarsProvider`, los providers de vehículo y las rutas conservan sus contratos.

## Interacción, accesibilidad y estados

- Las áreas táctiles accionables miden al menos 48 dp.
- Todos los iconos sin texto tienen label semántico; las cards anuncian su destino.
- Las animaciones de presión duran 150–200 ms y respetan `MediaQuery.disableAnimations`.
- Texto a escala 1.0, 1.3 y 2.0 envuelve, trunca en una única línea cuando corresponde o incrementa el alto del módulo. No se usa altura fija para contenido textual de dos líneas.
- Se comprueba el Home a 375 y 430 dp, con safe areas superior/inferior.
- Se conserva color de marca y se evita texto pequeño de bajo contraste sobre naranja mediante superficies blancas/neutras en los controles compactos.

## Pruebas y verificación

Antes de cambiar producción se añadirán o actualizarán pruebas widget para:

- Los tres labels, sus destinos y semántica.
- La flecha e iconografía de cada acción.
- Selector único de vehículo y su fallback de garage vacío.
- Foto rectangular/fallback de talleres y avatar circular/fallback de mecánicos.
- Estados loading, vacío, error y datos de ambas secciones.
- Matriz 375/430 dp y escalas 1.0/1.3/2.0 sin overflow, incluido el caso que hoy falla.
- Safe areas, targets de 48 dp y reducción de movimiento.

La verificación final ejecutará `dart format`, `flutter analyze`, las pruebas enfocadas y el suite completo de Flutter, más una inspección visual del Home en tamaño de teléfono.
