# Wizard Location, Motion and Spacing Design

## Objetivo

Facilitar la selección de ubicación en la búsqueda de repuestos reutilizando
la última coordenada persistida del usuario, y pulir el ritmo visual del flujo
de tres pasos sin sobrecargarlo con animaciones.

## Hallazgo de datos

El login guarda los tokens y consulta `GET /users/me`. El backend devuelve
`location: { lat, lon }`; `UserModel.fromJson` la transforma en
`User.latitude` y `User.longitude`, y `authProvider` conserva ese usuario en
la sesión. El wizard actualmente no consume esos campos: sólo considera una
selección local, el GPS compartido y, en último lugar, un centro fijo.

## Ubicación inicial

Al abrir el selector, el origen se resolverá en este orden:

1. Selección ya confirmada dentro de la solicitud actual.
2. Posición GPS activa en `userLocationProvider`.
3. Última ubicación persistida en `authProvider.user`.
4. Centro de respaldo actual en Tegucigalpa.

La ubicación de perfil se convertirá en una selección confirmable con origen
`profile`. El mapa abrirá centrado en ella, el CTA quedará disponible y la UI
la identificará como `Última ubicación guardada`. Mover el mapa cambiará el
origen a `mapTap`; usar el FAB de GPS lo cambiará a `gps`. Confirmar el punto
sólo afecta la solicitud y no actualiza el perfil ni el backend.

Las coordenadas se aceptarán únicamente cuando latitud y longitud estén
presentes, sean finitas y estén dentro de `[-90, 90]` y `[-180, 180]`.
Coordenadas inválidas continuarán hacia el siguiente fallback sin bloquear la
interfaz.

## Motion

La navegación conservará `PageView` sin gesto lateral. El cambio de página
durará 360 ms con `Curves.easeInOutCubicEmphasized`, produciendo una entrada y
salida más progresivas. El título del header usará una transición breve de
fade y desplazamiento vertical de 180 ms. El progreso mantendrá su animación
de 240 ms y el CTA conservará su cambio de etiqueta de 160 ms.

No se añadirán animaciones al mapa completo, listas extensas ni superficies
grandes. Todas las duraciones serán cero cuando
`MediaQuery.disableAnimationsOf(context)` sea verdadero.

## Espaciado

Se adoptarán tres niveles explícitos dentro de los pasos:

- 8–12 dp entre un encabezado de sección y su control inmediato.
- 16 dp entre elementos pertenecientes al mismo grupo.
- 28–32 dp entre secciones principales independientes.

Paso 1 separará más la introducción del garaje. Paso 2 aumentará el aire entre
resumen, categoría y tipo de repuesto. Paso 3 agrupará los resúmenes y dará
32 dp entre descripción, ubicación y fotografía. El CTA persistente y los
safe areas no cambian.

## Accesibilidad y errores

El origen de la ubicación se expresará en texto y semántica. La recuperación
de una dirección seguirá siendo no bloqueante: si falla, se mostrarán las
coordenadas. Reduced motion, objetivos táctiles de 48 dp y escalado de texto
se conservarán.

## Verificación

- Prueba de parsing de la ubicación entregada por `/users/me`.
- Pruebas de prioridad: selección local, GPS, perfil y fallback.
- Prueba del origen `profile` y su etiqueta visible.
- Pruebas de duración cero con reduced motion y 360 ms en modo normal.
- Pruebas de layout a 320–430 dp y text scale 2.0.
- `flutter analyze`, pruebas enfocadas y `flutter build web --debug`.

## Fuera de alcance

- Modificar backend, endpoints o persistencia.
- Guardar automáticamente en BD la ubicación elegida para una solicitud.
- Solicitar permisos GPS al entrar al wizard.
- Añadir dependencias o una librería de animación.
