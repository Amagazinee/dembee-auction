# Dembee — Windows Android эмулятор засах скрипт
# Ажиллуулах: powershell -ExecutionPolicy Bypass -File scripts\windows-emulator-fix.ps1

Write-Host "=== Dembee Android эмулятор засах ===" -ForegroundColor Cyan

# 1. Android SDK platform-tools (adb) олох
$sdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
    "$env:ANDROID_HOME\platform-tools",
    "$env:ANDROID_SDK_ROOT\platform-tools"
)

$adbDir = $sdkPaths | Where-Object { Test-Path "$_\adb.exe" } | Select-Object -First 1

if (-not $adbDir) {
    Write-Host "АЛДАА: adb олдсонгүй." -ForegroundColor Red
    Write-Host "Android Studio → SDK Manager → SDK Tools → Android SDK Platform-Tools суулгана уу."
    exit 1
}

$adb = Join-Path $adbDir "adb.exe"
Write-Host "adb олдлоо: $adb" -ForegroundColor Green

# 2. PATH-д түр нэмэх (энэ PowerShell цонхонд л)
if ($env:Path -notlike "*$adbDir*") {
    $env:Path = "$adbDir;$env:Path"
    Write-Host "PATH-д platform-tools нэмэгдлээ." -ForegroundColor Green
}

# 3. ADB дахин эхлүүлэх
Write-Host "`nADB дахин эхлүүлж байна..." -ForegroundColor Yellow
& $adb kill-server 2>$null
Start-Sleep -Seconds 2
& $adb start-server
Start-Sleep -Seconds 1

# 4. Холбогдсон төхөөрөмжүүд
Write-Host "`nХолбогдсон төхөөрөмжүүд:" -ForegroundColor Yellow
& $adb devices -l

$devices = & $adb devices | Select-String "emulator-\d+\s+device"
if (-not $devices) {
    Write-Host "`nАНХААР: Бэлэн эмулятор олдсонгүй." -ForegroundColor Red
    Write-Host @"

Дараахыг хийнэ үү:
  1. Android Studio → Device Manager
  2. Хуучин 'gphone16k' эмуляторыг УСТГА (16k ихэвчлэн асуудалтай)
  3. Create Device → Pixel 7 → API 34 (x86_64, 16k БИШ)
  4. Cold Boot → нүүр дэлгэц гарч 1-2 минут хүлээнэ
  5. Энэ скриптийг дахин ажиллуулна

"@ -ForegroundColor Yellow
} else {
    Write-Host "`nЭмулятор бэлэн байна!" -ForegroundColor Green
    Write-Host "Одоо: flutter run" -ForegroundColor Cyan
}

# 5. Flutter doctor
Write-Host "`n=== flutter doctor ===" -ForegroundColor Cyan
flutter doctor -v

Write-Host "`n=== Дууслаа ===" -ForegroundColor Cyan
