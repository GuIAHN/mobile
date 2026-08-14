# Bandeja de notificaciones no leídas

Fecha: 2026-08-14
Estado: aprobado

## Objetivo

Crear una pantalla móvil dedicada a las notificaciones no leídas del usuario. La campana del Home abrirá esta pantalla, cada notificación se marcará como leída al tocarla y existirá una acción explícita para marcar todas. Abrir la bandeja por sí solo no modificará ninguna notificación.

La pantalla debe sentirse parte natural del Home: cercana y clara, pero con una jerarquía sobria apropiada para ofertas, mensajes, solicitudes y estados de cuenta.

## Contratos backend verificados

Todos los endpoints requieren JWT y usan el prefijo `/api/me/notifications`.

### Listar no leídas

`GET /api/me/notifications?leido=false&page=1&limit=20`

Devuelve una lista ordenada por `createdAt` descendente. Cada elemento contiene:

```json
{
  "_id": "notification-id",
  "tipo": "offer.new",
  "titulo": "Nueva oferta",
  "cuerpo": "Nueva oferta de Taller Central",
  "data": {},
  "leido": false,
  "createdAt": "2026-08-14T12:00:00.000Z"
}
```

El parser móvil aceptará `_id` e `id`, porque el historial REST expone documentos de MongoDB y los eventos en tiempo real usan `id`.

### Marcar una

`PATCH /api/me/notifications/:id/read`

Valida pertenencia y devuelve la notificación actualizada.

### Marcar todas

`PATCH /api/me/notifications/read-all`

Devuelve `{ "success": true }`.

### Contador compartido

`GET /api/me/notifications/unread-count`

El provider existente del contador se invalidará después de cualquier marcado exitoso para mantener sincronizado el indicador de la campana.

## Navegación

Se añadirá una ruta autenticada de nivel secundario:

```text
Home
  └── /notifications
```

La campana usará `context.push(RouteNames.notifications)`. La pantalla será completa, conservará el back del sistema y no ocupará una pestaña del `BottomNavBar`.

En esta primera entrega, tocar una tarjeta significa “marcar como leída”. La tarjeta se retirará del filtro de no leídas después de que el backend confirme la operación. No se intentará navegar a ofertas o conversaciones porque el campo `data` todavía no ofrece un identificador de ruta uniforme para todos los tipos.

## Dirección visual

`DESIGN_SYSTEM.md` prevalece sobre cualquier recomendación genérica de bandejas:

- Fondo `AppColors.background`.
- Hanken Grotesk mediante `AppTypography`.
- Superficies blancas con radios de 20 px, sombra baja y separación de 12 px.
- Naranja automotriz para acciones y pendientes; azul sólo como semántica secundaria cuando corresponda.
- Sin AppBar elevada ni fondo oscuro.

La firma visual será una línea naranja vertical en el borde izquierdo de cada tarjeta, inspirada en un indicador pendiente del tablero de un vehículo. La línea no será el único indicador: el icono, el texto y la semántica anunciarán que el elemento no está leído.

### Encabezado

- Safe area superior.
- Botón back `arrow_back_ios_new` con área táctil de 48 dp.
- Título “Notificaciones”.
- Link “Marcar todas” sólo cuando haya elementos y no exista una acción masiva en curso.
- Resumen debajo: “N pendientes”, con pluralización correcta.

### Tarjeta

- Contenedor blanco, radio 20, padding 16 y separación vertical 12.
- Línea naranja izquierda de 4 px.
- Contenedor líder de 48 × 48 con fondo semántico suave.
- Icono Material outline según la familia del tipo:
  - `offer.*`: oferta/compras.
  - `message.*`: chat.
  - `search.*`: búsqueda o solicitud.
  - `user.*`: cuenta.
  - `settlement.*`: pagos.
  - fallback: campana.
- Título, cuerpo y hora relativa; el cuerpo puede ocupar varias líneas con text scaling.
- Ripple y semántica de botón: “Marcar como leída: {título}”.
- Durante el marcado individual, sólo esa tarjeta se deshabilita y muestra progreso sin bloquear el resto.

### Esquema

```text
┌──────────────────────────────────────────┐
│  ‹  Notificaciones        Marcar todas   │
│     4 pendientes                         │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │▌ [icono] Nueva oferta        Ahora │  │
│  │▌         Taller Central envió...   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │▌ [icono] Nuevo mensaje       10 min│  │
│  │▌         Revisa la consulta...     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

## Arquitectura

El feature de notificaciones crecerá conservando las capas del proyecto y evitando mezclar estas notificaciones persistidas con el sistema global de toasts `core/notifications`.

```text
presentation
  NotificationsPage + widgets
  NotificationsNotifier / state
           │
           v
domain
  UserNotification
  NotificationsRepository
  casos de uso de listar y marcar
           │
           v
data
  UserNotificationModel
  NotificationsRepositoryImpl
  NotificationsRemoteDatasource
           │
           v
GET/PATCH me/notifications
```

El nombre `UserNotification` evita colisiones con `NotificationModel`, que actualmente representa mensajes efímeros de interfaz.

El provider del listado será dueño de:

- página actual y capacidad de cargar más;
- elementos obtenidos;
- identificadores que se están marcando;
- estado de la acción masiva;
- error recuperable de carga inicial o de página adicional.

La primera página usará 20 elementos. Al acercarse al final se cargará la siguiente. Como el endpoint usa paginación por desplazamiento y el filtro cambia al marcar, después de un marcado exitoso se reconstruirá el conjunto desde la primera página; así no se saltarán elementos que hayan cambiado de posición.

## Comportamiento

### Carga y refresco

- La entrada solicita únicamente `leido=false`.
- Pull-to-refresh reconstruye la lista desde la primera página.
- El scroll solicita otra página sólo si la anterior devolvió 20 elementos.
- No se añadirá polling ni WebSocket en esta entrega.

### Marcado individual

1. El usuario toca una tarjeta.
2. La tarjeta muestra progreso y queda temporalmente deshabilitada.
3. Se ejecuta `PATCH :id/read`.
4. Si funciona, se invalida el contador y se recarga el rango visible desde la primera página.
5. Si falla, la tarjeta permanece y se muestra un mensaje recuperable.

No se aplica una eliminación optimista para evitar perder visualmente una notificación que el servidor no haya podido actualizar.

### Marcado masivo

1. El usuario toca “Marcar todas”.
2. La acción queda deshabilitada y muestra progreso.
3. Se ejecuta `PATCH read-all`.
4. Si funciona, el listado queda vacío, se invalida el contador y aparece el estado “Estás al día”.
5. Si falla, se conserva el listado y se ofrece reintento.

## Estados de interfaz

### Carga inicial

Cuatro esqueletos con la misma geometría de las tarjetas para evitar saltos de layout.

### Datos

Lista ordenada del más reciente al más antiguo, con pull-to-refresh y paginación progresiva.

### Vacío

Icono de campana con check, título “Estás al día” y texto “No tienes notificaciones sin leer.” El estado debe seguir siendo desplazable para permitir refrescar.

### Error inicial

Mensaje “No pudimos cargar tus notificaciones” y botón “Reintentar”. No se expondrá el texto técnico de Dio al usuario.

### Error de acción

Toast global con una explicación breve y la posibilidad de volver a tocar la tarjeta o la acción masiva.

## Accesibilidad y adaptación

- Todas las acciones tendrán un área táctil mínima de 48 dp.
- Se usarán `Semantics`, labels descriptivos y orden de lectura natural.
- El estado no leído no dependerá exclusivamente del color.
- Título y cuerpo envolverán líneas bajo text scaling; no habrá alturas fijas en tarjetas.
- Safe areas y back del sistema se conservarán.
- Los esqueletos y entradas respetarán `MediaQuery.disableAnimationsOf(context)`.
- La lista se comprobará en teléfonos pequeños y grandes, orientación vertical y horizontal.

## Pruebas

- Parsing de `_id`/`id`, fechas, `data` opcional y tipos desconocidos.
- Datasource: query de no leídas, paginación y rutas PATCH correctas.
- Repositorio y casos de uso delegan y propagan errores correctamente.
- Provider: carga inicial, página adicional, marcado individual, marcado masivo, invalidación del contador y recuperación de errores.
- Router: `/notifications` construye la pantalla y la campana navega a ella.
- Widget: carga, datos, vacío, error, progreso individual y masivo.
- Accesibilidad: labels, áreas táctiles y text scaling representativo.
- Layout sin overflow en anchos pequeños y grandes.

## Fuera de alcance

- Mostrar notificaciones ya leídas o añadir filtros adicionales.
- Pantalla de detalle para una notificación.
- Navegación contextual a chat, oferta, solicitud o pago.
- Recepción en tiempo real mediante WebSocket.
- Modificar la ubicación habitual o cualquier flujo del Home ajeno a la campana.
- Cambios en el backend, cuyos endpoints actuales son suficientes.
