# Orquivia CRM

Aplicación de correo y negocios con interfaz en español, frontend estático para GitHub Pages y Supabase para autenticación y persistencia privada.

## Desarrollo

- `npm ci`
- `npm run build`
- `npm start` (http://127.0.0.1:4173)
- `npm test` y `npm run check`

`workspace.js` contiene la interfaz, `model.js` la lógica de datos y `backend.js` la integración. `seed.js` contiene exclusivamente datos ficticios. Se conserva la demo anterior mediante migración local sin borrar la clave original.

## Funciones

- Registro, acceso, recuperación de contraseña y cierre de sesión con Supabase Auth.
- Espacio de prueba independiente del espacio real de cada usuario.
- Carpetas: entrada, borradores, salida, enviados, archivo y papelera. Vista conjunta o por buzón.
- Conversaciones con mensajes anteriores desplegables.
- Responder, responder a todos y reenviar dentro del panel, con Para/Cc/Cco, tipografía, tamaño, negrita, cursiva, subrayado, listas, alineación, color, enlaces, firma y adjuntos. HTML saneado con DOMPurify.
- Borradores automáticos y envío exclusivamente simulado en el espacio de prueba.
- Negocio vinculado editable junto al correo: etapa, checklist, datos y notas.
- Ficha de negocio como página con resumen, correos, documentos e historial.
- Campos configurables con obligatoriedad, plantilla de checklist editable y pasos específicos por negocio.
- Firmas por buzón, densidad del listado y preferencias tipográficas.
- Dashboards derivados de los negocios y sus checklists reales.

## Administración y cobros

- Tabla global con búsqueda, filtros, ordenación y edición de código, responsable, modalidad y próxima fecha; exportación CSV compatible con Excel.
- Reglas generales y ajustes por proyecto: inicio, hitos, final o mensual. Los períodos mensuales se solicitan manualmente y se comprueban duplicados por trabajo y período.
- Trabajos con cantidades, precios e impuestos; solicitudes internas para uno o varios trabajos.
- El responsable del proyecto o administración puede preparar un presupuesto. Los borradores permiten editar importes y asignar revisor; después pasan a revisión, aprobación y aceptación del cliente. La factura puede solicitarse desde el presupuesto aceptado conservando los importes negociados.
- Series y números, copias de datos fiscales por documento, PDF descargable y adjuntos PDF privados. Cobros parciales, saldo pendiente y vencimientos calculados.
- El módulo comparte los datos entre miembros de una empresa. Las solicitudes guardan el identificador del destinatario y tienen filtro «Asignadas a mí». Los roles propietario, administración y proyectos están registrados; todos ven los mismos módulos por ahora. Solo propiedad y administración gestionan invitaciones. No hay envío de documentos, automatización mensual, contabilidad oficial ni integración fiscal. Las facturas generadas se identifican como control interno.

El editor de documentos tiene tres pasos (cliente, servicios/IVA, revisión/destinatario), clientes fiscales reutilizables y catálogo. La tabla por trabajos busca por servicio, código, categoría y proyecto. Las invitaciones son enlaces personales de 7 días, almacenados mediante hash, sujetos al correo confirmado del destinatario y revocables. No se envían invitaciones por email automáticamente.

Las pruebas de `tests/billing.test.js` cubren cálculos, duplicados, períodos, numeración, instantáneas, revisión de presupuestos, cobros parciales y seguridad del CSV.

## Infraestructura de datos

Proyecto Supabase: `ugtuhukjfdvonabqqttd` (Orquivia CRM). Repositorio: https://github.com/thepulsestation/orquivia-crm . Configuración pública en `config.js`; no contiene secretos de servicio ni tokens de correo.

Migraciones en `supabase/migrations`. La versión actual guarda un documento por empresa en `crm_companies`, con miembros en `crm_members` y RLS. Al acceder, los antiguos espacios personales de `crm_workspaces` se copian a la empresa del propietario sin borrar los originales. La revisión impide sobrescrituras entre sesiones. Los nuevos documentos reales se guardan en el bucket privado `crm-documents`, bajo `company/<company-id>/`, límite 10 MB. Los archivos antiguos conservan su acceso privado original y no se comparten automáticamente. Los de prueba se conservan en IndexedDB del dispositivo.

Configurar en Supabase Auth la Site URL y Redirect URLs de GitHub Pages y, si procede, localhost. Confirmación de correo permanece activada. No se crean contraseñas ni usuarios reales automáticamente.

## Publicación

El workflow publica `dist` en GitHub Pages después de instalar, probar y compilar. El repositorio debe configurar Pages con origen GitHub Actions. Las rutas de recursos son relativas.

## Pendiente para correo de producción

La aplicación no lee, envía ni modifica correo real. Añadir un buzón en ajustes NO autoriza acceso a su proveedor. Faltan el registro OAuth en Microsoft Entra y/o Google Cloud, consentimiento del titular, intercambio y renovación de tokens en backend, sincronización con Graph/Gmail, adjuntos del proveedor, reintentos y envío idempotente. Los botones de envío real permanecen deshabilitados. No se debe marcar un buzón conectado ni habilitar envíos hasta verificar esa integración.

Las políticas y flujos de auth siguen la documentación oficial: https://supabase.com/docs/guides/database/postgres/row-level-security y https://supabase.com/docs/reference/javascript/auth-onauthstatechange .

Las pruebas SQL de `supabase/tests/companies.sql` verifican aislamiento entre empresas, aceptación por el correo correcto, uso único de invitaciones, acceso compartido, impedimento de escalada de rol, asignaciones a miembros y conflictos de revisión. Se ejecutan en una transacción que revierte los datos de prueba.


## Proyectos con múltiples trabajos y pagadores

- Cada trabajo guarda unidad/estructura/local, servicio, cliente fiscal, acuerdo comercial y ejecución. Un proyecto puede tener varios pagadores; cada solicitud y documento agrupa solo trabajos de uno de ellos.
- Los trabajos nuevos requieren presupuesto aceptado o referencia de acuerdo previo para facturar. La ejecución se confirma con autor y fecha; se admite cobro previo explícito con motivo. Los trabajos anteriores conservan su comportamiento para no bloquear la migración.
- En **Trabajos y cobros** se seleccionan líneas para emitir juntas o separadas. Si están completos pagador y código, el editor abre directamente la revisión. Se guardan método y plazo de pago por proyecto y documento, con vencimiento editable.
- Las solicitudes conservan una copia de los datos fiscales. La tabla Por trabajos distingue ejecución, facturación y cobro. Los cobros parciales se reparten proporcionalmente entre líneas; no son asignaciones bancarias individuales. No hay conciliación bancaria automática.
- Configuración permite varios tipos de proyecto y etapas; los proyectos continuos permanecen abiertos en la última etapa. Reordenar etapas conserva el significado actual; una etapa ocupada no se elimina ni renombra sin mover sus proyectos antes.
- Las plantillas técnicas generan borradores de texto por trabajo con variables. La confirmación humana produce un PDF, lo vincula a los documentos del proyecto y registra ejecución. No se aplican firma electrónica, validación técnica automática ni maquetación DOCX.
- Presupuestos, facturas y documentos técnicos pueden abrir un borrador de correo con PDF y proyecto vinculados. Outlook/Gmail siguen pendientes: no hay envíos reales. Los adjuntos de conversaciones vinculadas se reúnen con los documentos manuales en la ficha.
- Los nuevos campos se guardan en el payload compartido de empresa, bajo las políticas existentes de Supabase. Esta versión no necesita migración SQL adicional.
