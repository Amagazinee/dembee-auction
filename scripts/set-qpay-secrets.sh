#!/usr/bin/env bash
# QPay Cloud Functions secrets тохируулах
set -euo pipefail

PROJECT="${1:-dembee-auction}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIREBASE="npx --yes firebase-tools@14"

if [[ -z "${QPAY_USERNAME:-}" || -z "${QPAY_PASSWORD:-}" || -z "${QPAY_INVOICE_CODE:-}" ]]; then
  echo "Алдаа: QPAY_USERNAME, QPAY_PASSWORD, QPAY_INVOICE_CODE орчны хувьсагчуудыг тохируулна уу."
  echo ""
  echo "Жишээ:"
  echo "  export QPAY_USERNAME='your_merchant_username'"
  echo "  export QPAY_PASSWORD='your_merchant_password'"
  echo "  export QPAY_INVOICE_CODE='your_invoice_code'"
  echo "  export QPAY_CALLBACK_URL='https://asia-southeast1-dembee-auction.cloudfunctions.net/qpayCallback'"
  echo "  ./scripts/set-qpay-secrets.sh"
  exit 1
fi

CALLBACK_URL="${QPAY_CALLBACK_URL:-https://asia-southeast1-${PROJECT}.cloudfunctions.net/qpayCallback}"
BASE_URL="${QPAY_BASE_URL:-https://merchant.qpay.mn}"

echo "==> Төсөл: $PROJECT"
echo "==> QPay secrets тохируулж байна..."

cd "$ROOT"
$FIREBASE functions:secrets:set QPAY_USERNAME --project "$PROJECT" <<< "$QPAY_USERNAME"
$FIREBASE functions:secrets:set QPAY_PASSWORD --project "$PROJECT" <<< "$QPAY_PASSWORD"
$FIREBASE functions:secrets:set QPAY_INVOICE_CODE --project "$PROJECT" <<< "$QPAY_INVOICE_CODE"
$FIREBASE functions:secrets:set QPAY_CALLBACK_URL --project "$PROJECT" <<< "$CALLBACK_URL"
$FIREBASE functions:secrets:set QPAY_BASE_URL --project "$PROJECT" <<< "$BASE_URL"

echo ""
echo "Secrets тохируулагдлаа. Дараа нь functions deploy хийнэ:"
echo "  cd functions && npm run build && cd .."
echo "  $FIREBASE deploy --only functions:createQPayPayment,functions:checkQPayPayment,functions:qpayCallback --project $PROJECT"
echo ""
echo "Firestore rules deploy:"
echo "  $FIREBASE deploy --only firestore:rules --project $PROJECT"
