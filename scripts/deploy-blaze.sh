#!/usr/bin/env bash
# Blaze идэвхжүүлсний дараа Cloud Functions + Firestore deploy
set -euo pipefail

PROJECT="${1:-dembee-auction}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIREBASE="npx --yes firebase-tools@14"

echo "==> Төсөл: $PROJECT"
echo "==> Functions build..."
cd "$ROOT/functions"
npm install
npm run build

echo "==> Firebase deploy (functions + firestore rules/indexes)..."
cd "$ROOT"
$FIREBASE deploy \
  --only functions,firestore:rules,firestore:indexes \
  --project "$PROJECT"

echo ""
echo "Deploy дууслаа."
echo "Firebase Console → Functions дээр 3 функц байна:"
echo "  - processAuctionTask"
echo "  - scheduleAuctionLifecycle"
echo "  - sweepAuctionLifecycle"
