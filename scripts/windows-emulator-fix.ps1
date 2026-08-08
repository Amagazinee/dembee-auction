# Dembee - Windows Android emulator helper (ASCII-only for PowerShell 5.1)
# Run: powershell -ExecutionPolicy Bypass -File scripts\windows-emulator-fix.ps1

Write-Host "=== Dembee Android emulator fix ===" -ForegroundColor Cyan

$sdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
    "$env:ANDROID_HOME\platform-tools",
    "$env:ANDROID_SDK_ROOT\platform-tools"
)

$adbDir = $sdkPaths | Where-Object { Test-Path (Join-Path $_ "adb.exe") } | Select-Object -First 1

if (-not $adbDir) {
    Write-Host "ERROR: adb not found." -ForegroundColor Red
    Write-Host "Install Android SDK Platform-Tools in Android Studio SDK Manager."
    exit 1
}

$adb = Join-Path $adbDir "adb.exe"
Write-Host "adb: $adb" -ForegroundColor Green

if ($env:Path -notlike "*$adbDir*") {
    $env:Path = "$adbDir;$env:Path"
}

Write-Host ""
Write-Host "Restarting ADB..." -ForegroundColor Yellow
& $adb kill-server 2>$null
Start-Sleep -Seconds 2
& $adb start-server
Start-Sleep -Seconds 1

Write-Host ""
Write-Host "Connected devices:" -ForegroundColor Yellow
& $adb devices -l

$ready = & $adb devices | Select-String "emulator-\d+\s+device"
if (-not $ready) {
    Write-Host ""
    Write-Host "Emulator not ready." -ForegroundColor Red
    Write-Host "1. Device Manager: delete gphone16k if present"
    Write-Host "2. Create Device: Pixel 7, API 34 x86_64 (not 16k page size)"
    Write-Host "3. Cold Boot and wait 1-2 minutes"
    Write-Host "4. Run this script again"
} else {
    Write-Host ""
    Write-Host "Emulator ready. Run: flutter run" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== flutter doctor ===" -ForegroundColor Cyan
flutter doctor -v
