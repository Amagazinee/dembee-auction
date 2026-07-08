# Blaze deploy — Windows PowerShell
param([string]$Project = "dembee-auction")

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> Төсөл: $Project"
Write-Host "==> Functions build..."
Push-Location "$Root\functions"
npm install
npm run build
Pop-Location

Write-Host "==> Firebase deploy..."
Push-Location $Root
npx firebase-tools@14 deploy `
  --only functions,firestore:rules,firestore:indexes `
  --project $Project
Pop-Location

Write-Host ""
Write-Host "Deploy дууслаа."
