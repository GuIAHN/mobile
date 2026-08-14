# Floating Bottom Navigation Design

## Objetivo

Adaptar el navbar inferior de GuIA al lenguaje visual de la referencia: una
cápsula flotante con un ítem activo ligeramente elevado, manteniendo el logo de
la aplicación en el centro y conservando todas las rutas actuales.

## Dirección visual

El tono será **refined minimal**. La referencia se interpreta con moderación:
se conserva su silueta flotante y la jerarquía del ítem activo, pero se reemplaza
el negro dominante por la paleta blanca, naranja y gris definida en
`DESIGN_SYSTEM.md`.

## Estructura

- La barra será una superficie blanca flotante con 14–16 dp de margen lateral,
  separación inferior segura y radio de 28 dp.
- La superficie tendrá borde `AppColors.border` tenue y sombra negra al 6–8%,
  proyectada hacia arriba y abajo para separarla del contenido.
- Se mantienen los destinos actuales: `Inicio`, `Chats`, `Compras` y `Perfil`
  para consumidores; tiendas conservan su distribución actual sin `Compras`.
- El botón `Inicio` se conserva aunque el logo central también navegue al Home.
- El logo permanece centrado, con diámetro visual de 56–58 dp, aro blanco y una
  elevación aproximada de 12 dp sobre la cápsula.

## Estado activo

- El ítem seleccionado usa un círculo de 46–48 dp en `primaryMuted`.
- El círculo y el ícono suben 5–6 dp mediante una transición corta.
- El ícono activo usa `AppColors.primary`; los inactivos usan
  `AppColors.grey600`.
- El label activo usa Hanken Grotesk w800 y naranja; los demás usan w600 gris.
- Cuando `Inicio` está activo, su propio ítem recibe el estado elevado. El logo
  conserva una presentación de marca estable para evitar dos animaciones activas
  simultáneas.

## Interacción y motion

- Se conserva `HapticFeedback.selectionClick` al cambiar de pestaña.
- Press feedback: escala a 0.97 durante el toque.
- Cambio de selección: 220 ms, `Curves.easeOutCubic`; el desplazamiento vertical
  no excede 6 dp.
- El logo puede usar una escala de presión mínima, pero no cambia de tamaño por
  selección.
- Con `MediaQuery.disableAnimationsOf(context)`, todas las duraciones son cero.

## Layout responsive

- Cada destino conserva un target mínimo de 48×48 dp.
- Labels de una línea con ellipsis; el crecimiento del texto incrementa el inset
  inferior reservado mediante `bottomNavContentInset`.
- La barra debe funcionar a 320, 390 y 430 dp de ancho, text scale 1× y 2×,
  portrait y landscape.
- El SafeArea inferior se integra dentro de la cápsula sin dejar el contenido
  detrás de los controles.

## Estados y accesibilidad

- Cada destino expone `button`, `selected`, label y acción semántica.
- El logo expone `Volver al inicio, logo guIAutomotriz` y un target mínimo de
  48 dp.
- Si el asset del logo falla, se conserva el fallback actual con ícono Home.
- La navegación no introduce estados de carga, error o vacío adicionales.

## Alcance técnico

El cambio se limita a `BottomNavBar`, sus pruebas y el cálculo del inset inferior.
No se cambian providers, índices, rutas, backend ni pantallas de contenido.

## Criterios de aceptación

1. El navbar aparece como cápsula flotante y no como franja de borde a borde.
2. Sólo el destino seleccionado muestra el círculo elevado.
3. El logo permanece centrado y estable en todos los estados.
4. Todos los destinos actuales siguen navegando al mismo índice.
5. No hay overflow ni controles menores de 48 dp en la matriz responsive.
6. Reduced motion elimina los desplazamientos animados.
