# Imágenes locales para talleres y mecánicos

## Objetivo

Asignar una imagen compartida a todos los mecánicos y otra a todos los talleres de la base de datos local existente, de modo que las imágenes aparezcan en la app sin eliminar ni recrear usuarios, perfiles, ratings, reseñas u otros datos.

## Alcance

- Crear un comando de mantenimiento local, separado del seed de desarrollo.
- Publicar `mechanic.jpg` y `workshop.jpg` desde `uploads/dev-seed/` en el backend local.
- Actualizar exclusivamente el campo `users.photo` según `users.user_type`.
- Invalidar únicamente la caché de proveedores destacados después de una actualización exitosa.
- Verificar que los datos de `mechanic_profiles`, incluidos `rating` y `rating_count`, no cambien.

No se modificará la presentación de Flutter porque el flujo existente ya lee `photo`, lo convierte en `HomeItem.photo` y lo muestra mediante `Image.network` con un icono de respaldo cuando la carga falla.

## Enfoque

Se agregará un script repetible y no destructivo al backend, expuesto mediante `npm run data:provider-images`. El script aceptará la URL pública base mediante `DEV_ASSET_BASE_URL`; para el entorno local actual se ejecutará con:

```text
http://192.168.0.240:3000/uploads/dev-seed
```

Antes de modificar la base, el script comprobará que existan ambos JPG y copiará los archivos al directorio estático local. Después consultará los perfiles afectados y conservará una instantánea en memoria de sus campos de valoración. Una transacción de Prisma ejecutará dos actualizaciones:

- `MECHANIC` → `<base>/mechanic.jpg`
- `WORKSHOP` → `<base>/workshop.jpg`

Las operaciones reemplazarán cualquier valor anterior de `photo` en esos dos tipos de usuario, ya que el requisito aprobado es usar una imagen común por tipo. Solo escribirán `User.photo`; no se llamará al seed general ni a operaciones `delete`, `create` o `upsert`.

## Flujo de datos

1. El comando valida la URL base y los archivos de origen.
2. Copia las imágenes a `backend/uploads/dev-seed/`.
3. Lee los proveedores y sus valoraciones actuales.
4. Actualiza únicamente `users.photo` dentro de una transacción.
5. Dentro de la misma transacción, vuelve a leer los proveedores y comprueba que las valoraciones coincidan con la instantánea previa; una diferencia provoca rollback.
6. Invalida las claves asociadas a la etiqueta Redis `home:top-providers`.
7. Los endpoints de búsqueda y home devuelven `photo`; Flutter la muestra en las tarjetas existentes.

## Manejo de errores y seguridad de datos

- Una URL base ausente o inválida detendrá el comando antes de escribir en la base.
- Un archivo JPG ausente detendrá el comando antes de escribir en la base.
- Si una actualización falla, la transacción revertirá ambas asignaciones de imágenes.
- Si la comprobación posterior detecta cambios en ratings, el comando terminará con error y reportará los perfiles afectados.
- Si Redis no está disponible, la actualización de la base seguirá siendo válida y se informará que la caché puede requerir reiniciar el backend o esperar su expiración.
- El comando imprimirá cantidades y resultados, pero no credenciales ni la cadena de conexión.

## Pruebas y verificación

- Prueba automatizada del task con Prisma simulado para comprobar que solo se actualiza `photo` y que se filtra por `MECHANIC`/`WORKSHOP`.
- Prueba del rechazo previo a escritura cuando falta una imagen o la URL base no es válida.
- Comprobación de TypeScript, lint dirigido y pruebas del task.
- Ejecución contra la base local con conteos y valores agregados de `rating`/`rating_count` antes y después.
- Consulta final que confirme URLs no vacías para todos los mecánicos y talleres.
- Petición a los endpoints locales de talleres y mecánicos para confirmar que `photo` aparece en la respuesta.

## Compatibilidad con el trabajo existente

Los cambios locales ya presentes en `backend/prisma/tasks/users.task.ts` y en ambos repositorios se preservarán. El nuevo comando será independiente para evitar ejecutar el seed destructivo o mezclar esta actualización con la recreación de datos de desarrollo.
