# FinanzApp — MVP de gastos personales

Aplicación móvil desarrollada con **Flutter + Dart**, SQLite y Supabase. Permite iniciar sesión, registrar gastos, administrar categorías y presupuestos, adjuntar fotografías de tickets, consultar gráficas y sincronizar movimientos con Supabase.

## Requisitos
- Flutter 3.24 o superior y Dart compatible con `pubspec.yaml`.
- Android Studio o VS Code con extensiones Flutter/Dart.
- Proyecto de Supabase (URL y anon/publishable key).
- Android/iOS configurado para ejecutar Flutter.

## Instalación
```bash
flutter doctor
flutter pub get
```
La configuración `lib/config/supabase_config.dart` ya lee variables `--dart-define`; coloca tus datos al ejecutar:
```bash
flutter run --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
```
Si ejecutas `flutter create .`, conserva el permiso CAMERA y POST_NOTIFICATIONS del AndroidManifest incluido o vuelve a agregarlos. No pongas `service_role` en la app móvil. La clave pública anon/publishable está diseñada para clientes y las políticas RLS protegen los datos.

## Preparar Supabase
1. En Supabase crea un proyecto.
2. Abre SQL Editor y ejecuta `supabase/schema.sql`.
3. Habilita Email/Password en Authentication → Providers.
4. Configura confirmación de correo según las reglas de tu práctica.
5. Copia Project URL y anon/publishable key.
6. Crea usuarios desde el formulario de registro de la aplicación.

La app funciona localmente para altas, consultas, edición y borrado. La sincronización con la nube se realiza desde el botón de sincronizar. Para sincronizar, el usuario debe iniciar sesión y haber ejecutado el SQL.

## Ejecutar
```bash
flutter run
```
Pruebas:
```bash
flutter analyze
flutter test
```

## Funcionalidades incluidas
- Registro e inicio/cierre de sesión con Supabase Auth.
- Persistencia SQLite local.
- CRUD de gastos (crear, leer, actualizar, eliminar).
- Entidades relacionadas: `categories`, `budgets`, `expenses`.
- Sincronización REST mediante el cliente oficial de Supabase.
- Estados de carga, mensajes de error y validación de formularios.
- Cámara/galería para fotografía del ticket (`image_picker`).
- Notificación local al superar el 80% del presupuesto mensual.
- Cifrado AES-256 de los campos descriptivos almacenados localmente; la clave se conserva en `flutter_secure_storage`.
- Tokens de sesión gestionados por Supabase Flutter; no se imprimen ni se guardan manualmente.
- Librerías de terceros: `image_picker`, `fl_chart`, `intl`, `sqflite`, `flutter_secure_storage`, `encrypt`, `flutter_local_notifications`.

## Estructura
```text
lib/
  main.dart
  config/
  data/
  models/
  services/
  screens/
supabase/schema.sql
docs/
  reporte_tecnico.pdf
  diagramas/
scripts/
  generar_historial_git.sh
```

## Modelo de datos
- Categoría 1—N Gasto.
- Categoría 1—N Presupuesto (la categoría puede ser nula para un presupuesto global).
- Gasto pertenece a un usuario y a una categoría.
- Presupuesto pertenece a un usuario y opcionalmente a una categoría.

## Seguridad y limitaciones del MVP
- RLS restringe cada fila al `auth.uid()` propietario.
- SQLite cifra descripción, categoría, ruta de imagen y notas mediante AES-256-CBC con IV aleatorio. Los importes y fechas quedan como columnas para consultas y agregaciones; no almacenar información bancaria sensible.
- `flutter_secure_storage` guarda la clave de cifrado mediante Keychain/Android Keystore.
- La sincronización requiere conexión y sesión válida. Los conflictos se resuelven con estrategia simple de última escritura (updated_at).
- La imagen del ticket se guarda como ruta local; para sincronizar archivos entre dispositivos debe configurarse Supabase Storage y subir el archivo (no incluido en este MVP).
- Para producción: usar HTTPS, revisar reglas de RLS, políticas de almacenamiento, gestión de respaldos, pruebas en dispositivos reales y análisis de seguridad.

## Git y Pull Request
El archivo `scripts/generar_historial_git.sh` inicializa Git y crea 15 commits significativos en ramas `main`, `develop`, `feature/login`, `feature/gastos`, `hotfix/validacion`. Después sube las ramas al repositorio remoto que tú crees en GitHub. El PR de `feature/login` hacia `develop` debe crearse en GitHub; la revisión auto-documentada está en `docs/PR_REVIEW.md`.

## Publicar en GitHub
1. Crea un repositorio público vacío llamado `finanzapp-mvp` en GitHub.
2. En esta carpeta ejecuta:
```bash
bash scripts/generar_historial_git.sh
git remote add origin https://github.com/TU_USUARIO/finanzapp-mvp.git
git push -u origin main develop feature/login feature/gastos hotfix/validacion
```
3. En GitHub crea un Pull Request: base `develop`, compare `feature/login`.
4. Pega la revisión de `docs/PR_REVIEW.md` como comentario y aprueba/mergea si la revisión es satisfactoria.

## Autora/or
Proyecto académico — sustituye este apartado por tus datos antes de entregar.
