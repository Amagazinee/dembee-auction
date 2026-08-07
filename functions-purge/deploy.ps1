# Дэмбээ — purgeHistoricalData deploy (Windows PowerShell)
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot
Write-Host "npm install..." -ForegroundColor Cyan
npm install

Set-Location ..
$env:FUNCTIONS_DISCOVERY_TIMEOUT = "90"
Write-Host "firebase deploy --only functions:purge ..." -ForegroundColor Cyan
firebase deploy --only functions:purge
