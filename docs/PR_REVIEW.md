# Revisión documentada — PR feature/login → develop

**Tipo:** auto-revisión académica documentada.  
**Objetivo:** integrar registro e inicio de sesión con Supabase Auth.

## Lista de revisión
- [x] Validación de correo y contraseña mínima de 6 caracteres en formulario.
- [x] Estado de carga evita envíos repetidos.
- [x] Errores mostrados sin exponer credenciales ni tokens.
- [x] La sesión se gestiona con Supabase Flutter.
- [x] No se incluye `service_role` en el cliente.
- [x] Navegación al panel después de autenticar.
- [ ] Verificar en dispositivo con proyecto Supabase real y confirmación de correo configurada.

## Resultado
Aprobación condicionada a ejecutar las pruebas de integración con credenciales propias. No se deben subir secretos al repositorio. Esta revisión es documentación académica; el PR real debe crearse en GitHub después de publicar las ramas.
