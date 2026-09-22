# Navegación y saldo pendiente para tiendas

## Objetivo

Corregir la navegación inferior de las tiendas de repuestos y hacer visible el
saldo que la tienda adeuda a GuIA por las ventas realizadas dentro de la
plataforma.

## Decisiones aprobadas

- La navegación inferior de una tienda tendrá únicamente tres destinos:
  `Inicio`, `Chats` y `Perfil`.
- El logo central no se mostrará para tiendas. Los tres destinos ocuparán el
  ancho disponible de manera uniforme.
- La navegación de consumidores y de otros roles conservará su estructura
  actual.
- No se creará por ahora un destino principal llamado `Cobros`.
- El saldo aparecerá dentro del dashboard de `Estadísticas`, porque es el lugar
  donde la tienda ya consulta ventas, cotizaciones y conversión.
- Esta primera entrega será informativa. El flujo para declarar pagos y subir
  comprobantes queda fuera de alcance.

## Alternativas consideradas

### 1. Saldo dentro de Estadísticas — seleccionada

Reutiliza la respuesta de `GET reports/store/dashboard`, que ya incluye la
métrica `M-T10`. No agrega un fetch, mantiene tres destinos principales y
presenta el saldo junto a su contexto comercial.

### 2. Destino `Cobros` en la navegación inferior

Facilitaría descubrir un futuro flujo de pagos, pero volvería a introducir un
cuarto elemento cuando el objetivo inmediato es simplificar la barra. También
crearía una pantalla cuyo contenido todavía sería principalmente informativo.

### 3. Sección de cobros dentro de Perfil

Mantendría tres destinos, pero escondería una obligación operativa importante
en un lugar asociado principalmente con datos de cuenta y configuración.

## Navegación inferior

`BottomNavBar` seguirá resolviendo sus elementos según el rol:

- Tienda: `Inicio` → índice 0, `Chats` → índice 1 y `Perfil` → índice 2.
- Consumidor: conserva los índices y el logo central existentes.

Para tiendas se renderizará una fila sencilla de tres elementos expandidos, sin
el hueco reservado al logo y sin el botón circular superpuesto. Se conservarán
los estilos, estados seleccionados, respuesta háptica, semántica y objetivos
de toque mínimos del sistema actual.

## Resumen de facturación en Estadísticas

El dashboard localizará la métrica `M-T10`, titulada por el backend `Saldo
pendiente con GuIA-HN`. Esta métrica representa la comisión histórica aún no
pagada y no depende del filtro de 7, 15 o 30 días.

Se mostrará antes del bloque `Resumen de Actividad` como una tarjeta horizontal
destacada con:

- Etiqueta: `Saldo pendiente con GuIA`.
- Importe con formato monetario local y cifras tabulares.
- Texto de apoyo: `Comisión pendiente por ventas realizadas en la app`.
- Estado explícito cuando el saldo sea cero: `Estás al día`.

La tarjeta usará los tokens de `DESIGN_SYSTEM.md`: superficie blanca, texto
principal oscuro, borde del sistema y naranja como acento. El saldo no se
presentará como error, porque es un estado contable y no un fallo de la cuenta.
No se introducirán la paleta ni las tipografías alternativas sugeridas por las
herramientas externas de diseño.

## Datos y estados

- Fuente: la respuesta ya solicitada por `storeDashboardProvider` a
  `GET reports/store/dashboard`.
- Métrica: `M-T10.payload.value`.
- No se realizará una segunda petición a `billing/me/balance` en esta entrega.
- Carga: el esqueleto del dashboard reservará espacio para el resumen.
- Error general: se conservará la vista actual con acción `Reintentar`.
- Métrica ausente o incompatible: el resumen no inventará un monto; mostrará un
  estado no disponible sin impedir que carguen las demás estadísticas.
- Saldo cero: se mostrará `$ 0.00` junto con `Estás al día`.

## Accesibilidad y adaptación

- Cada destino inferior mantendrá al menos 48 dp de alto y una etiqueta
  semántica con estado seleccionado.
- La tarjeta de saldo tendrá orden de lectura: título, importe y explicación.
- La deuda no se comunicará únicamente mediante color.
- El diseño admitirá texto ampliado sin truncar el importe ni las etiquetas.
- Se respetarán áreas seguras y reducción de movimiento.
- Se verificará en teléfonos representativos de 375 × 812 y 430 × 932.

## Pruebas

- Pruebas de widget para confirmar que la tienda muestra exactamente tres
  acciones distribuidas uniformemente y no renderiza el logo central.
- Pruebas de regresión para confirmar que la navegación del consumidor no
  cambia.
- Pruebas de widget del dashboard para saldo positivo, saldo cero y métrica
  ausente.
- Pruebas con texto a 2×, área segura inferior y animaciones deshabilitadas.
- `flutter analyze` sobre los archivos modificados y ejecución de las suites
  focalizadas de navegación y dashboard.

## Fuera de alcance

- Historial de liquidaciones.
- Declaración de un pago.
- Carga de comprobantes.
- Estados de pago en revisión o rechazado.
- Cambios en los endpoints o cálculos contables del backend.
