# Implementación del sprint 1

Referencia: Sprint_1_y_2.docx y backend develop e82929d. Aplicación base main e78c25a.

## Fase 1 Cantidades y cotizaciones

- [x] Cantidad de 1 a 999 al publicar, inmutable después.
- [x] Precio unitario al crear y actualizar ofertas; consultas sin precio.
- [x] Modelos de solicitudes, conversaciones y compras compatibles con registros de una unidad.
- [x] Desglose de cantidad, precio unitario, subtotal, envío y total del servidor.
- [x] Pruebas de contratos y cálculos monetarios.

## Fase 2 Fotografías

- [x] Selección de cero a cinco fotos, miniaturas, eliminación y validación de tamaño/formato.
- [x] Carga individual con estado y reintento; publicación bloqueada ante cargas fallidas.
- [x] Envío de photoUrls y lectura ordenada de photos; portada antigua compatible.
- [x] Galería accesible para solicitante y tienda.

## Fase 3 Edición de solicitudes

- [x] Edición de descripción y fotos mediante PATCH /search/:id.
- [x] Cantidad, vehículo y categoría permanecen fijos.
- [x] Manejo de 409 SEARCH_REQUEST_NOT_EDITABLE y 422 PHOTOS_NOT_AVAILABLE.
- [x] Recarga de detalle y bandejas después de guardar.

Se implementará el contrato vigente del backend: abierta, no vencida y sin cotizaciones con precio. El documento permite editar hasta COMPRADO; esa diferencia queda pendiente de decisión de producto y no autoriza cambiar las reglas del servidor.

## Fase 4 Nivel profesional y Home

- [x] Nivel profesional de mecánico: Certificado, TSU, Ingeniero; independiente de reseñas.
- [x] Orden del Home determinado por el servidor, sin calcular bonos en el cliente.
- [x] Proveedores sin reseñas mostrados sin valoración inventada.
- [x] Verificación de estados, contraste, objetivos táctiles, texto ampliado, áreas seguras, movimiento reducido y anchos de teléfono pequeños y grandes.

El backend aplica +0,01 por compra entregada hasta +1 mensual en America/Caracas. Confirmar aprobación y versionado de reglas antes de modificar el incentivo. El selector administrativo necesita su repositorio independiente, no disponible aquí. Las HU 007 y 008 siguen fuera de alcance por falta de especificación. No se incluyen despliegues ni cambios de reglas del backend.

## Validación y límites

La implementación móvil cubre las cuatro fases. Se agregaron pruebas para límites de cantidad, precisión en centavos, cargas parciales, reintentos, orden de fotos, contratos de cotización, edición concurrente y estados de error. La revisión visual utiliza capturas de 320 y 430 px con texto ampliado al doble, áreas seguras y movimiento reducido. Los botones naranja usan texto e indicadores blancos por indicación del usuario, registrada en DESIGN_SYSTEM.md.

La comprobación completa contra una API desplegada, almacenamiento real y cámara/galería en dispositivos iOS y Android queda pendiente. El backend requerido es develop con las migraciones del sprint 1, no su main anterior. No se modificó ni desplegó el backend. Su ranking del Home utiliza una caché de hasta 24 horas; invalidar la caché móvil tras una entrega no garantiza una reclasificación inmediata en el servidor.

Resultados finales: `flutter analyze --no-pub` sin observaciones; `flutter test --no-pub` con 822 pruebas aprobadas. Las capturas con Hanken Grotesk se inspeccionaron a 320 y 430 px. El texto de los botones principales es blanco por indicación del usuario.
