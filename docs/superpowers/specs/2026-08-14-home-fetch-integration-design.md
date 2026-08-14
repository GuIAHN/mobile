# Integración de datos del Home

Fecha: 2026-08-14
Estado: aprobado

## Objetivo

Conectar el Home móvil con los endpoints reales de proveedores destacados y conteo de notificaciones no leídas, evitando solicitudes duplicadas y sin modificar el diseño visual existente.

## Contratos verificados

### Proveedores destacados

`GET /api/home/top-providers`

- Autenticación opcional.
- Acepta `lat` y `lng` opcionales.
- Si no recibe coordenadas y existe un usuario autenticado, el backend intenta usar la ubicación de su perfil.
- Si no existe ubicación, devuelve el ranking nacional.
- Devuelve una sola respuesta con dos colecciones:

```json
{
  "workshops": [],
  "mechanics": []
}
```

Cada colección contiene hasta cinco proveedores. El backend es la fuente de verdad del ranking, cercanía, respaldo nacional y caché.

### Notificaciones no leídas

`GET /api/me/notifications/unread-count`

- Requiere JWT.
- Devuelve `{ "count": number }`.
- El Home mostrará el indicador de la campana cuando `count > 0`.
- La navegación definitiva de la campana se resolverá cuando se implemente la pantalla de notificaciones; mientras tanto conservará su acción actual.

## Arquitectura y flujo

### Una sola petición para los dos tops

El móvil tendrá un provider asíncrono compartido que realizará una única llamada a `home/top-providers`. Ese provider conservará las listas de talleres y mecánicos dentro de un mismo resultado.

Las dos instancias de `TopProvidersSection` observarán selectores derivados del resultado compartido:

```text
GET home/top-providers (una vez)
             │
             v
   TopProvidersResult
      │             │
      v             v
 workshops       mechanics
```

No se ejecutará una petición por sección. Reintentar desde cualquiera de las secciones invalidará el provider agrupado y actualizará ambas listas con una sola petición.

Cuando la ubicación global esté activa y exista una posición, la llamada enviará `lat/lng`. En los demás casos omitirá las coordenadas y permitirá que el backend aplique su fallback de perfil o ranking nacional.

### Mapeo

Se reutilizará `ProviderModel` para convertir los elementos del endpoint en `HomeItem`. El parser admitirá tanto los nombres existentes de búsqueda como los nombres del contrato de Home, evitando un segundo modelo con la misma representación:

- `name` / `nombre`
- `description` / `descripcion`
- `ratingCount` / `rating_count` / `reviews`
- `distanceKm` / `distancia_km`
- `specialties` / `especialidades`

### Conteo de notificaciones

El módulo móvil de notificaciones expondrá un datasource y un provider de conteo no leído. El Home lo observará una vez mientras esté activo y convertirá el resultado en `hasUnreadNotifications`.

No se añadirá polling. La futura pantalla podrá invalidar el mismo provider después de marcar notificaciones como leídas.

## Errores y estados

- Un error de `top-providers` conservará el estado recuperable que ya muestra cada sección.
- El botón `Reintentar` invalidará el fetch agrupado, no las búsquedas generales.
- Un error de `unread-count` no bloqueará el Home y se interpretará visualmente como ausencia de indicador.
- Las búsquedas completas de mecánicos y talleres seguirán usando sus endpoints actuales; sólo las secciones destacadas migran al endpoint de Home.

## Pruebas

- El datasource usa las rutas y parámetros correctos.
- El parser acepta el contrato en inglés de `top-providers` sin romper el contrato anterior.
- Talleres y mecánicos consumen un único resultado compartido.
- La ubicación activa agrega `lat/lng`; sin posición se omiten.
- Reintentar invalida el provider agrupado.
- `unread-count` convierte `{ count }` en un entero y la campana se activa sólo cuando es mayor que cero.
- Los errores de conteo no rompen la construcción del Home.

## Fuera de alcance

- Pantalla o listado de notificaciones.
- Marcar notificaciones como leídas.
- Polling, WebSocket o actualización en tiempo real del contador.
- Cambios visuales en las tarjetas, secciones o campana.
- Cambios en los endpoints backend ya verificados.
