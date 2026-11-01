# Auditoría de paginación — 24 de octubre de 2026

## Talleres y mecánicos: corregido

La app solicitaba únicamente `page=1&pageSize=20`, descartaba `total`, `page`
y `pageSize` de la respuesta, y dividía esos 20 resultados en páginas locales
de seis tarjetas. Las flechas nunca pedían las páginas restantes al servidor.

Ahora el listado conserva los metadatos y acumula páginas al acercarse a 600 px
del final, usando una grilla virtualizada. El total mostrado proviene del
servidor. Se impiden cargas concurrentes, se eliminan IDs duplicados y se
ignoran respuestas anteriores tras cambiar filtros, refrescar o cerrar la pantalla.
Un error al cargar más conserva los resultados y permite reintentar la misma página.

La búsqueda textual es local porque el endpoint no acepta texto: recorre las
páginas pendientes para encontrar coincidencias fuera de los primeros 20.
El orden por valoración/cercanía conserva el orden del servidor. El orden local
«Más populares» completa las páginas antes de mostrar la lista para evitar
que nuevas tarjetas se inserten por encima de la posición de lectura.
Estos dos casos requieren leer todas las páginas coincidentes; el scroll normal
por valoración/cercanía conserva la carga progresiva.

Se mantienen el radio, las especialidades, la valoración mínima y las reglas de
visibilidad del backend: el total representa proveedores que cumplen esos criterios.

## Otros listados revisados

| Listado | Evidencia | Estado |
| --- | --- | --- |
| Compras | `consumerPurchasesProvider` llama al caso de uso con la página predeterminada; el datasource descarta `total/page/pageSize`. | Pendiente: solo primera página de 20. |
| Solicitudes del consumidor | `consumerRequestsProvider` llama a `getChatThreadsUseCaseProvider` sin avanzar `page`. | Pendiente: solo primera página de 20. |
| Solicitudes/ventas de tienda | `storeSalesRequestsProvider` y `storeRequestsByStatusProvider` tampoco avanzan `page`. | Pendiente: solo primera página de 20. |
| Reseñas públicas | `reviewsProvider` fija `page: 1, limit: 20`. | Pendiente: no permite acceder a las siguientes páginas. |
| Notificaciones | `NotificationsNotifier.loadMore` avanza páginas y la pantalla lo invoca al hacer scroll. | Ya tiene carga progresiva. |
| Proveedores destacados del Home | Usa un endpoint específico de destacados. | Selección resumida intencional; el directorio completo es Talleres/Mecánicos. |

Los otros listados quedan registrados para una corrección independiente; este
cambio modifica el directorio de talleres/mecánicos y su invalidación tras reseñar.

## Verificación

- `flutter test --no-pub test/features/home test/features/reviews`: 296 pruebas aprobadas.
- Análisis estático de los diez archivos Dart modificados: sin incidencias.
- Revisión independiente: hallazgos corregidos y segunda revisión sin incidencias.
- Regresiones de 43 proveedores en tres páginas para ambas categorías; scroll real más allá del registro 20; búsqueda de un proveedor en una página aún no cargada.
- Errores iniciales y de carga adicional, reintento, duplicados, última página vacía, cambio de filtros y cierre durante una petición.
- Estados de carga, error, vacío y datos; anchos 320, 375 y 430; texto al 200 %, áreas seguras y movimiento reducido.
- Nuevo pie: texto oscuro sobre fondo claro; acción secundaria naranja en 20 sp y negrita (contraste 3.08:1 sobre el fondo, apto para texto grande), área táctil mínima 48 dp.
- Validación con respuestas controladas; no se consultó la base de datos de producción ni se desplegó una compilación móvil.

## Seguimiento: filtros del directorio

- Se elimina la fila de filtros activos, «Quitar filtros» y los indicadores de selección del buscador. La selección permanece en el panel y sigue aplicándose a las solicitudes.
- El encabezado ya no vuelve a solicitar el catálogo de especialidades para dibujar chips. Desaparece la fila de altura fija que podía quedar vacía mientras cargaba ese catálogo.
- Verificados todos los valores ofrecidos de orden/radio/valoración, ninguna/una/varias especialidades, parámetros HTTP reales serializados por Dio y conservación de filtros al reabrir el panel. Aplicar, cancelar y limpiar se prueban en ambas categorías.
- Corregido en backend el dato ausente que impedía ordenar por popularidad: el directorio devuelve `ratingCount`. Es un campo adicional; requiere desplegar el backend junto con la actualización móvil.
- `flutter test --no-pub --reporter expanded test/features/home test/home_filters_test.dart`: 275 pruebas aprobadas. Análisis estático de los seis archivos de este seguimiento: sin incidencias.
- Backend: 16 pruebas del repositorio de búsqueda aprobadas; verificación TypeScript de producción (`tsc -p tsconfig.build.json --noEmit --incremental false`) aprobada. La comprobación TypeScript que incluye todos los tests encuentra problemas previos en `realtime-security.e2e-spec.ts` por la dependencia local ausente `socket.io-client` y sus tipos; no se modifican esas pruebas ni se instalan dependencias.
- No se ejecutan pruebas E2E con bases de datos ni se despliega a producción. Las pruebas de transporte utilizan respuestas controladas.
