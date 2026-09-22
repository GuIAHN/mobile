# GuIA — Sistema de Diseño (OBLIGATORIO en toda pantalla)

## 1. PALETA DE COLORES
| Token            | Hex                    | Uso |
|------------------|------------------------|-----|
| naranja          | #F25C05                | Color primario: botones, links, acentos, iconos activos |
| naranjaSuave     | #F25C05 al 10% opacidad| Fondos de iconos, chips, notas informativas |
| azulLogo         | #3A86FF                | Acentos tecnológicos, detalles del logo e indicadores secundarios |
| fondo            | #F5F6FA                | Background de TODAS las pantallas (Scaffold) |
| blanco           | #FFFFFF                | Cards y campos de texto |
| texto            | #22272E                | Títulos y texto principal |
| gris             | #7A828E                | Subtítulos, labels, placeholders activos |
| grisClaro        | #B8BDC4                | Placeholders de inputs |
| borde            | #DDE0E5                | Bordes de inputs y divisores |
| deshabilitado    | #D9DCE1 (fondo) / #9AA0A8 (texto) | Botones inactivos |
| verde            | #2E9E5B                | Estados de éxito/confirmación |
| error            | #E53935                | Errores y acciones destructivas |

## 2. TIPOGRAFÍA
- Fuente única: **Hanken Grotesk** (google_fonts).
- Título de pantalla: 28px, w800, color texto, centrado.
- Subtítulo bajo el título: 15px, w400, color gris, centrado, line-height 1.45.
- Labels de campos: 12px, w700, letterSpacing 1.5, MAYÚSCULAS, color gris.
- Texto de input: 16px, w400 (w600 si tiene valor seleccionado).
- Botón principal: 15px, w700, letterSpacing 2, MAYÚSCULAS.

## 2.1 ICONOGRAFÍA
- Familia única: **Lucide**, consumida desde `AppIcons` y `AppLineIcon`; no importar la librería directamente en features.
- Estilo por defecto: outline, trazo consistente, sin mezclar con iconos filled en la misma capa.
- Tamaños permitidos: 16px inline, 20px en acciones, 24px como leading y 32px para features. El hero puede usar 64px.
- Los iconos se presentan directamente sobre la superficie, **sin círculo, squircle ni fondo redondeado decorativo**.
- Un fondo detrás del icono solo se permite cuando comunica un estado funcional: selección, error, marcador de mapa o identidad de marca.
- Los iconos Material existentes se migran progresivamente. Las pantallas nuevas deben usar `AppIcons`.

## 3. COMPONENTES

### Scaffold
- backgroundColor: fondo (#F5F6FA). NUNCA blanco ni oscuro.
- Padding horizontal de pantalla: 24px.
- Botón back: icono arrow_back_ios_new, sin AppBar con fondo, alineado a la izquierda.

### Card contenedora de formularios
- Fondo blanco, borderRadius: 24.
- Padding interno: 20px.
- Sombra: color negro 5% opacidad, blur 20, offset (0, 8).

### Inputs / Selectores
- Fondo blanco, border 1px color borde, borderRadius: 14.
- Padding: 14-15 vertical, 16 horizontal.
- Icono outline a la izquierda (20px, color gris), gap 12px.
- Focus: borde naranja (+ glow naranja 10% en web).
- Label SIEMPRE arriba del campo (nunca floating label).

### Botón primario (CTA)
- Fondo naranja, texto blanco, borderRadius: 32 (pill).
- Padding vertical: 16. Ancho completo.
- Icono opcional a la derecha del texto, gap 8.
- Sombra: naranja al 40%, blur 24, offset (0, 8).
- Estado deshabilitado: fondo #D9DCE1, texto #9AA0A8, sin sombra.

### Botón secundario
- Fondo transparente, border 1.5px, borderRadius 32.
- Activo: borde y texto naranja. Inactivo: borde #DDE0E5, texto #B8BDC4.

### Cards de ítems (listas)
- Fondo blanco, borderRadius: 20, padding 16, margen inferior 12.
- Sombra: negro 4%, blur 14, offset (0, 6).
- Icono líder Lucide de 24px, sin contenedor decorativo; reservar una columna visual de 32px y un gap de 12px antes del texto.

### Links de texto
- Color naranja, w700, sin subrayado.

### Bottom sheets (para selects)
- borderRadius superior: 28. Handle gris de 40x4 centrado arriba.
- Título 18px w800 centrado. Ítem seleccionado: naranja w700 + check_circle.

## 4. INTERACCIÓN
- Botones CTA inician deshabilitados y se activan cuando el formulario es válido.
- Animaciones: entrada de cards con fade+slide 350ms ease; press scale 0.97.
- Toggle de visibilidad (ojo) en campos de contraseña.
- Mensajes de error bajo el campo: 12px, color error.

## 5. PROHIBIDO
- Temas oscuros, gradientes morados/azules, Material defaults (filled inputs grises de M3).
- Floating labels, bordes redondeados < 14, fuente Roboto por defecto.
- AppBars con elevation y color de fondo.
