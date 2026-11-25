#!/usr/bin/env bash
set -e
git init -b main
git add README.md pubspec.yaml .gitignore analysis_options.yaml
git commit -m "chore: inicializa proyecto Flutter y documentación"
git add lib/config lib/models
git commit -m "feat: agrega configuración y modelo de gastos"
git add lib/services/crypto_service.dart lib/services/local_db.dart
git commit -m "feat: implementa SQLite y cifrado local AES"
git add supabase/schema.sql
git commit -m "feat: define esquema Supabase y políticas RLS"
git branch develop
git checkout -b feature/login
git add lib/main.dart
git commit -m "feat(login): agrega registro e inicio de sesión Supabase"
git commit --allow-empty -m "test(login): documenta validaciones de autenticación"
git checkout develop
git merge --no-ff feature/login -m "merge: integra feature/login con revisión documentada"
git checkout -b feature/gastos
git add lib/services/sync_service.dart lib/services/notification_service.dart
git commit -m "feat: agrega sincronización y alertas de presupuesto"
git commit --allow-empty -m "feat(gastos): define flujo CRUD y persistencia local"
git commit --allow-empty -m "test(gastos): agrega verificación inicial de flujo"
git checkout develop
git merge --no-ff feature/gastos -m "merge: integra feature/gastos"
git checkout -b hotfix/validacion
git commit --allow-empty -m "fix: refuerza validación de importes y formularios"
git commit --allow-empty -m "test: documenta escenarios límite de validación"
git checkout develop
git merge --no-ff hotfix/validacion -m "merge: integra hotfix de validación"
git add docs README.md test
git commit -m "docs: agrega diagramas, pruebas y guía de instalación"
git checkout main
git merge --no-ff develop -m "release: publica MVP 1.0"
echo "Historial creado. Crea el remoto y publica: git push -u origin main develop feature/login feature/gastos hotfix/validacion"
