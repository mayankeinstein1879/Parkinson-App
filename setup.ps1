# NeuroStep — Post-Flutter-Install Setup Script
# Run this ONCE after installing Flutter SDK
# Usage: Right-click -> "Run with PowerShell" or run in terminal

$ErrorActionPreference = "Stop"
$projectDir = "C:\Users\Mayank Mukherjee\Desktop\parkinson_app"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  NeuroStep Flutter Setup Verification" -ForegroundColor Cyan  
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Check Flutter
Write-Host "[1] Checking Flutter SDK..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "    OK: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "    FAIL: Flutter not found on PATH" -ForegroundColor Red
    Write-Host "    Please install Flutter: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Red
    exit 1
}

# 2. Check Git
Write-Host "[2] Checking Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>&1
    Write-Host "    OK: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "    FAIL: Git not found" -ForegroundColor Red
    exit 1
}

# 3. Navigate to project
Write-Host "[3] Checking project directory..." -ForegroundColor Yellow
if (Test-Path $projectDir) {
    Write-Host "    OK: $projectDir" -ForegroundColor Green
    Set-Location $projectDir
} else {
    Write-Host "    FAIL: Project directory not found: $projectDir" -ForegroundColor Red
    exit 1
}

# 4. Check pubspec.yaml
Write-Host "[4] Checking pubspec.yaml..." -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    Write-Host "    OK: pubspec.yaml found" -ForegroundColor Green
} else {
    Write-Host "    FAIL: pubspec.yaml missing" -ForegroundColor Red
    exit 1
}

# 5. Run flutter create to generate missing platform files (safe on existing project)
Write-Host "[5] Running flutter create to generate Android/iOS boilerplate..." -ForegroundColor Yellow
flutter create --project-name parkinson_insole_app --org com.parkinsonsai . 2>&1 | ForEach-Object {
    if ($_ -match "created|Wrote|Running") { Write-Host "    $_" -ForegroundColor Gray }
}
Write-Host "    OK: flutter create complete" -ForegroundColor Green

# 6. Run flutter pub get
Write-Host "[6] Installing dependencies (flutter pub get)..." -ForegroundColor Yellow
$pubResult = flutter pub get 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "    OK: All dependencies resolved" -ForegroundColor Green
} else {
    Write-Host "    FAIL: pub get failed:" -ForegroundColor Red
    Write-Host $pubResult -ForegroundColor Red
    exit 1
}

# 7. Run flutter analyze
Write-Host "[7] Running flutter analyze..." -ForegroundColor Yellow
$analyzeResult = flutter analyze 2>&1
$errors = $analyzeResult | Where-Object { $_ -match "error" }
if ($errors.Count -eq 0) {
    Write-Host "    OK: No errors found" -ForegroundColor Green
} else {
    Write-Host "    WARN: $($errors.Count) issue(s) found:" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
}

# 8. Check connected devices
Write-Host "[8] Checking connected Android devices..." -ForegroundColor Yellow
$devices = flutter devices 2>&1
Write-Host $devices -ForegroundColor Gray

# 9. Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "  1. Connect Android phone via USB (enable USB debugging)" -ForegroundColor White
Write-Host "  2. Run: flutter run" -ForegroundColor Cyan
Write-Host "  3. App starts in MOCK mode (no hardware needed)" -ForegroundColor White
Write-Host "  4. For ESP32 testing:" -ForegroundColor White
Write-Host "     a. Flash docs\esp32_ble_firmware_test.ino to ESP32" -ForegroundColor White
Write-Host "     b. Set 'useMock = false' in lib\main.dart" -ForegroundColor White
Write-Host "     c. Run: flutter run" -ForegroundColor Cyan
Write-Host ""
