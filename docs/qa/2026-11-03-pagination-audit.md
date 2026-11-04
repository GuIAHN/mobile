# Auditoría de GET y paginación — 3 de noviembre de 2026

Se corrigen los pendientes de la auditoría del 24 de octubre y se revisan los
GET de la aplicación contra sus contratos en el código local del backend.

| Listado | Contrato y comportamiento verificado |
| --- | --- |
| Solicitudes propias, `GET /search/me` | `page` y `limit`; conserva `total`, `page`, tamaño efectivo y `counts`. Carga progresiva al acercarse al final. |
| Solicitudes/ventas de tienda, `GET /stores/me/search-requests` | Igual; cada estado conserva su bandeja independiente. Se usa `limit`, evitando el alias antiguo `pageSize`. |
| Compras, `GET /me/purchases` | Recorre páginas con `page`/`limit`; conserva metadatos y conteos globales. |
| Reseñas públicas, `GET /users/:id/reviews` | Recorre páginas con `page`/`limit`; conserva `total` y tamaño efectivo. |
| Conversaciones, `GET /conversations/me` | El API devuelve arrays paginados, sin total. Avanza hasta una página corta/vacía. La continuidad usa el número recibido antes de ocultar chats completados, de modo que una primera página enteramente oculta no impida ver las siguientes. |
| Mensajes, `GET /conversations/:id/messages` | Solicita 30 por lote y recorre el historial con el cursor UTC `before`, tomando la fecha más antigua recibida. Carga al acercarse al inicio y ofrece una acción visible. |
| Ofertas de una solicitud, `GET /search/:id/offers` | Recorre todas las páginas para que las comparaciones y los órdenes locales de precio, distancia y fecha utilicen el conjunto completo. |
| Talleres/mecánicos y notificaciones | Ya tenían paginación; se incluyen sus regresiones en la suite completa. |

Las rutas anteriores se muestran con los nombres conceptuales del API; los
valores exactos se mantienen centralizados en `ApiEndpoints`.

Las solicitudes se ordenan por **fecha de creación descendente**, tanto en el
mapeo inicial como al acumular páginas. La fecha de un mensaje reciente no hace
que una solicitud antigua desplace a una nueva. El backend local ya ordena las
solicitudes de forma descendente antes de paginar; en tiendas usa la fecha de
llegada del match a la bandeja. El cliente conserva también `createdAt`.

Se reemplaza el fallback de cotización que buscaba únicamente entre las primeras
100 solicitudes por el detalle autorizado de la solicitud por ID.

El controlador compartido impide solicitudes concurrentes, elimina IDs duplicados,
conserva resultados ante errores y reintenta la misma página. Descarta respuestas
obsoletas al refrescar, cambiar filtros/sesión, recibir una revisión de tiempo real
o abandonar la pantalla. Los filtros de solicitudes/compras reinician su scroll.
Las búsquedas locales recorren las páginas pendientes antes de anunciar que no
hay coincidencias, siguiendo el criterio del directorio de proveedores.

## GET que no representan listados paginables completos

- Detalles por ID, perfil propio, conteos, métricas y estado de una reseña son
  consultas individuales o agregadas.
- Marcas, modelos, categorías, especialidades, garaje y cobertura propia tienen
  contratos de listas completas sin parámetros de paginación.
- Destacados, publicidad y sugerencias de lugares son selecciones limitadas por
  contrato, con destinos/acciones propios; no se convierten en históricos.
- `messages?limit=1` se conserva exclusivamente para completar la autoría del
  último mensaje en previews. El historial utiliza su propio cursor.
- Reseñas pendientes devuelve una **cola de hasta 20 acciones**, sin cursor ni
  parámetros de página en el backend. Al reseñar o descartar se invalida y repone
  el lote. No se simula una paginación que ese endpoint no admite.

## Verificación

- `flutter test --no-pub --reporter expanded`: **781 pruebas aprobadas**.
- `flutter analyze --no-pub`: **sin incidencias**.
- `git diff --check`: sin errores de formato.

- Regresiones con 43 registros: scroll real más allá del registro 20 en las seis
  bandejas; búsqueda de coincidencias en la tercera página.
- Parámetros HTTP `page`/`limit`, metadatos efectivos y fecha de creación frente
  a actividad reciente; recorrido completo de las ofertas.
- Errores/reintentos, duplicados, concurrencia, páginas finales vacías, cambios
  de filtro/sesión, eventos de ofertas, refresco y cierre durante una petición.
- Historial superior a 30 mensajes; llegadas de tiempo real durante la carga,
  reintento del mismo cursor y conservación de mensajes al refrescar. Una
  reconexión con más de 30 mensajes nuevos completa el tramo entre el último
  lote y el historial existente antes de publicarlo, evitando huecos.
- Carga, error, vacío y datos; pantallas de 320 y 430 dp, texto al 200 %, áreas
  seguras y movimiento reducido. Pie con texto de contraste AA y acción de al
  menos 48 dp. Corregido un desbordamiento del encabezado de reseñas con texto
  ampliado, colocando la fecha debajo de la valoración.
- Pruebas con respuestas controladas; no se consultó producción ni se desplegó
  una compilación móvil.
