# Firebase Android тохируулах (Windows PowerShell)
# Ажиллуулах: powershell -ExecutionPolicy Bypass -File scripts\setup-firebase.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Дэмбээ — Firebase тохируулах ===" -ForegroundColor Cyan
Write-Host ""

# 1. FlutterFire CLI
Write-Host "[1/4] FlutterFire CLI суулгах..." -ForegroundColor Yellow
dart pub global activate flutterfire_cli
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"

# 2. flutterfire configure
Write-Host "[2/4] flutterfire configure (dembee-auction)..." -ForegroundColor Yellow
Write-Host "  -> Төсөл: dembee-auction" -ForegroundColor Gray
Write-Host "  -> Platform: Android (space дарж сонго, Enter)" -ForegroundColor Gray
flutterfire configure --project=dembee-auction

# 3. Шалгах
Write-Host "[3/4] Файлууд шалгах..." -ForegroundColor Yellow
$optionsFile = "lib\firebase_options.dart"
$googleServices = "android\app\google-services.json"

$ok = $true
if (-not (Test-Path $googleServices)) {
    Write-Host "  X google-services.json олдсонгүй: $googleServices" -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "  OK google-services.json" -ForegroundColor Green
}

if (Test-Path $optionsFile) {
    $content = Get-Content $optionsFile -Raw
    if ($content -match "YOUR_API_KEY") {
        Write-Host "  X firebase_options.dart хэвээр placeholder байна!" -ForegroundColor Red
        $ok = $false
    } else {
        Write-Host "  OK firebase_options.dart (бодит түлхүүр)" -ForegroundColor Green
    }
} else {
    Write-Host "  X firebase_options.dart олдсонгүй" -ForegroundColor Red
    $ok = $false
}

# 4. Дараагийн алхам
Write-Host ""
if ($ok) {
    Write-Host "[4/4] Амжилттай! Одоо:" -ForegroundColor Green
    Write-Host "  flutter pub get"
    Write-Host "  flutter run --no-enable-impeller"
    Write-Host ""
    Write-Host "Апп дээр 'Тохиргоо шаардлагатай' алга болно." -ForegroundColor Green
} else {
    Write-Host "[4/4] Алдаа — дараахыг гараар хийнэ үү:" -ForegroundColor Red
    Write-Host "  1. https://console.firebase.google.com/project/dembee-auction/settings/general"
    Write-Host "  2. Android app байхгүй бол 'Add app' -> package: com.example.dembee_app"
    Write-Host "  3. google-services.json татаж android\app\ руу тавина"
    Write-Host "  4. flutterfire configure --project=dembee-auction дахин ажиллуулна"
}
