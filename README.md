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

## Infraestructura

Proyecto Supabase: `ugtuhukjfdvonabqqttd` (Orquivia CRM). Repositorio: https://github.com/thepulsestation/orquivia-crm . Configuración pública en `config.js`; no contiene secretos de servicio ni tokens de correo.

Migraciones en `supabase/migrations`. El MVP guarda un documento de espacio por usuario en `crm_workspaces`, protegido por RLS, con una revisión para impedir sobrescrituras entre sesiones. No es todavía un espacio multiusuario compartido; alternar buzones no cambia el usuario autenticado ni otorga permisos a otras personas. Los documentos reales se guardan en el bucket privado `crm-documents`, aislados por carpeta de usuario, límite 10 MB. Los de prueba se conservan en IndexedDB del dispositivo.

Configurar en Supabase Auth la Site URL y Redirect URLs de GitHub Pages y, si procede, localhost. Confirmación de correo permanece activada. No se crean contraseñas ni usuarios reales automáticamente.

## Publicación

El workflow publica `dist` en GitHub Pages después de instalar, probar y compilar. El repositorio debe configurar Pages con origen GitHub Actions. Las rutas de recursos son relativas.

## Pendiente para correo de producción

La aplicación no lee, envía ni modifica correo real. Añadir un buzón en ajustes NO autoriza acceso a su proveedor. Faltan el registro OAuth en Microsoft Entra y/o Google Cloud, consentimiento del titular, intercambio y renovación de tokens en backend, sincronización con Graph/Gmail, adjuntos del proveedor, reintentos y envío idempotente. Los botones de envío real permanecen deshabilitados. No se debe marcar un buzón conectado ni habilitar envíos hasta verificar esa integración.

Las políticas y flujos de auth siguen la documentación oficial: https://supabase.com/docs/guides/database/postgres/row-level-security y https://supabase.com/docs/reference/javascript/auth-onauthstatechange .
