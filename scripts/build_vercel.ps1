Write-Host "=== FieldTrack Vercel Multi-Bundle Build ===" -ForegroundColor Cyan

Write-Host "1. Cleaning previous dist & build folders..." -ForegroundColor Yellow
if (Test-Path dist) { Remove-Item -Recurse -Force dist }
if (Test-Path frontend/build) { Remove-Item -Recurse -Force frontend/build }

Write-Host "2. Installing frontend dependencies..." -ForegroundColor Yellow
Set-Location frontend
flutter pub get

Write-Host "3. Building Admin Web Portal..." -ForegroundColor Yellow
flutter build web -t lib/main_admin.dart --base-href "/admin/" --release -o build/web_admin

Write-Host "4. Building Supervisor Web Portal..." -ForegroundColor Yellow
flutter build web -t lib/main_supervisor.dart --base-href "/supervisor/" --release -o build/web_supervisor

Set-Location ..

Write-Host "5. Assembling root dist directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path dist | Out-Null
Copy-Item -Recurse -Force landing_page/* dist/

New-Item -ItemType Directory -Force -Path dist/admin | Out-Null
New-Item -ItemType Directory -Force -Path dist/supervisor | Out-Null

Copy-Item -Recurse -Force frontend/build/web_admin/* dist/admin/
Copy-Item -Recurse -Force frontend/build/web_supervisor/* dist/supervisor/

Write-Host "=== Build Complete! Output assembled in dist/ ===" -ForegroundColor Green
