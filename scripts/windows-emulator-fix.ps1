# Dembee — Windows Android эмулятор засах скрипт
# Ажиллуулах: powershell -ExecutionPolicy Bypass -File scripts\windows-emulator-fix.ps1

Write-Host "=== Dembee Android эмулятор засах ===" -ForegroundColor Cyan

$sdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
    "$env:ANDROID_HOME\platform-tools",
    "$env:ANDROID_SDK_ROOT\platform-tools"
)

$adbDir = $sdkPaths | Where-Object { Test-Path "$_\adb.exe" } | Select-Object -First 1

if (-not $adbDir) {
    Write-Host "АЛДАА: adb олдсонгүй." -ForegroundColor Red
    Write-Host "Android Studio → SDK Manager → Android SDK Platform-Tools суулгана уу."
    exit 1
}

$adb = Join-Path $adbDir "adb.exe"
Write-Host "adb: $adb" -ForegroundColor Green

if ($env:Path -notlike "*$adbDir*") {
    $env:Path = "$adbDir;$env:Path"
}

Write-Host "`nADB дахин эхлүүлж байна..." -ForegroundColor Yellow
& $adb kill-server 2>$null
Start-Sleep -Seconds 2
& $adb start-server
Start-Sleep -Seconds 1

Write-Host "`nТөхөөрөмжүүд:" -ForegroundColor Yellow
& $adb devices -l

$ready = & $adb devices | Select-String "emulator-\d+\s+device"
if (-not $ready) {
    Write-Host "`nЭмулятор бэлэн биш." -ForegroundColor Red
    Write-Host @"
1. Device Manager → gphone16k УСТГА
2. Create Device → Pixel 7 → API 34 (x86_64, 16k БИШ)
3. Cold Boot → 1-2 минут хүлээнэ
4. Энэ скриптийг дахин ажиллуулна
"@ -ForegroundColor Yellow
} else {
    Write-Host "`nЭмулятор бэлэн! flutter run ажиллуулна уу." -ForegroundColor Green
}

Write-Host "`n=== flutter doctor ===" -ForegroundColor Cyan
flutter doctor -v
