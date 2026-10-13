#!/usr/bin/env bash
set -e

echo "=== FieldTrack Vercel Multi-Bundle Build ==="

echo "1. Cleaning previous dist & build folders..."
rm -rf dist frontend/build

echo "2. Installing frontend dependencies..."
cd frontend
flutter pub get

echo "3. Building Admin Web Portal..."
flutter build web \
  -t lib/main_admin.dart \
  --base-href "/admin/" \
  --release \
  -o build/web_admin

echo "4. Building Supervisor Web Portal..."
flutter build web \
  -t lib/main_supervisor.dart \
  --base-href "/supervisor/" \
  --release \
  -o build/web_supervisor

cd ..

echo "5. Assembling root dist directory..."
mkdir -p dist

# Copy static landing page to root of dist
cp -r landing_page/* dist/

# Copy Admin and Supervisor portals into subdirectories
mkdir -p dist/admin dist/supervisor
cp -r frontend/build/web_admin/* dist/admin/
cp -r frontend/build/web_supervisor/* dist/supervisor/

echo "=== Build Complete! Output assembled in dist/ ==="
