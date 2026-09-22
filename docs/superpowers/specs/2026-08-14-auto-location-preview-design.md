# Auto Location Preview Design

## Objetivo

Mostrar en el paso 3 la mejor ubicación ya disponible en la sesión, sin que el
usuario tenga que abrir el selector de mapa para inicializarla.

## Causa raíz

`resolveRequestLocationSeed` sólo se ejecuta dentro de
`_openRequestLocationPicker`. El selector recibe correctamente la ubicación de
perfil o GPS, pero `SparePartWizardStep3` continúa recibiendo directamente
`_requestLocation`, que permanece nulo hasta confirmar el diálogo.

## Diseño aprobado

El wizard tendrá una ubicación efectiva derivada en este orden:

1. Selección explícita de la solicitud.
2. GPS compartido y disponible en la sesión.
3. Coordenadas guardadas del usuario autenticado.
4. Sin selección; el fallback sólo se usa para centrar el selector.

La ubicación efectiva alimentará de forma consistente:

- el preview del paso 3;
- la habilitación del CTA final;
- el payload enviado;
- el centro y selección inicial del selector de mapa.

La ubicación derivada no marcará el formulario como editado ni escribirá en el
backend. Una selección manual seguirá teniendo prioridad y cancelar el selector
no modificará el preview.

## UI y accesibilidad

Se reutiliza el preview actual y su etiqueta `Última ubicación guardada`; no se
añaden superficies, animaciones ni copy nuevos. Los estados vacío, GPS, perfil y
selección manual conservan el mismo comportamiento responsive y semántico.

## Verificación

Una prueba de widget navegará por los tres pasos con un usuario autenticado que
tenga coordenadas guardadas. En el paso 3 comprobará que el preview muestra las
coordenadas y `Última ubicación guardada` sin abrir el selector, y que el CTA de
envío está habilitado.
