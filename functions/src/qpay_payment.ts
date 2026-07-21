import * as admin from "firebase-admin";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { getPackageById } from "./bid_packages";
import {
  createSimpleInvoice,
  hasPaidInvoice,
  loadQPayConfig,
} from "./qpay_client";

const qpayUsername = defineSecret("QPAY_USERNAME");
const qpayPassword = defineSecret("QPAY_PASSWORD");
const qpayInvoiceCode = defineSecret("QPAY_INVOICE_CODE");
const qpayCallbackUrl = defineSecret("QPAY_CALLBACK_URL");
const qpayBaseUrl = defineSecret("QPAY_BASE_URL");

const qpaySecrets = [
  qpayUsername,
  qpayPassword,
  qpayInvoiceCode,
  qpayCallbackUrl,
  qpayBaseUrl,
];

function applyQPaySecrets() {
  process.env.QPAY_USERNAME = qpayUsername.value();
  process.env.QPAY_PASSWORD = qpayPassword.value();
  process.env.QPAY_INVOICE_CODE = qpayInvoiceCode.value();
  process.env.QPAY_CALLBACK_URL = qpayCallbackUrl.value();
  process.env.QPAY_BASE_URL =
    qpayBaseUrl.value() || "https://merchant.qpay.mn";
}

export async function completePurchaseIfPending(
  db: admin.firestore.Firestore,
  purchaseId: string,
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const purchaseRef = db.collection("purchases").doc(purchaseId);
    const purchaseSnap = await tx.get(purchaseRef);
    if (!purchaseSnap.exists) {
      return false;
    }

    const purchase = purchaseSnap.data()!;
    if (purchase.status === "completed") {
      return true;
    }
    if (purchase.status !== "pending") {
      return false;
    }

    const userRef = db.collection("users").doc(purchase.userUid as string);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new Error("Хэрэглэгч олдсонгүй");
    }

    tx.update(purchaseRef, {
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(userRef, {
      bidBalance: admin.firestore.FieldValue.increment(purchase.bidCount),
    });
    return true;
  });
}

export const createQPayPayment = onCall(
  {
    region: "asia-southeast1",
    secrets: qpaySecrets,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Нэвтэрнэ үү");
    }

    const packageId = request.data?.packageId as string | undefined;
    if (!packageId) {
      throw new HttpsError("invalid-argument", "Багц сонгоно уу");
    }

    const pkg = getPackageById(packageId);
    if (!pkg) {
      throw new HttpsError("invalid-argument", "Буруу багц");
    }

    applyQPaySecrets();
    const config = loadQPayConfig();
    const db = admin.firestore();
    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "Хэрэглэгчийн профайл олдсонгүй");
    }
    if (userSnap.data()?.banned === true) {
      throw new HttpsError(
        "permission-denied",
        "Таны бүртгэл түр хориглогдсон",
      );
    }

    const purchaseRef = db.collection("purchases").doc();
    const senderInvoiceNo = purchaseRef.id;

    await purchaseRef.set({
      userUid: uid,
      packageId: pkg.id,
      bidCount: pkg.amount,
      amount: pkg.price,
      paymentMethod: "qpay",
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      const invoice = await createSimpleInvoice({
        config,
        senderInvoiceNo,
        description: `Дэмбээ — ${pkg.amount} санал`,
        amount: pkg.price,
      });

      await purchaseRef.update({
        qpayInvoiceId: invoice.invoiceId,
      });

      return {
        purchaseId: purchaseRef.id,
        invoiceId: invoice.invoiceId,
        qrText: invoice.qrText,
        qrImage: invoice.qrImage,
        shortUrl: invoice.shortUrl,
        urls: invoice.urls,
        amount: pkg.price,
        bidCount: pkg.amount,
      };
    } catch (error) {
      await purchaseRef.update({
        status: "failed",
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.error("createQPayPayment алдаа", error);
      throw new HttpsError(
        "internal",
        "Төлбөр үүсгэхэд алдаа гарлаа. Дахин оролдоно уу.",
      );
    }
  },
);

export const checkQPayPayment = onCall(
  {
    region: "asia-southeast1",
    secrets: qpaySecrets,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Нэвтэрнэ үү");
    }

    const purchaseId = request.data?.purchaseId as string | undefined;
    if (!purchaseId) {
      throw new HttpsError("invalid-argument", "purchaseId шаардлагатай");
    }

    applyQPaySecrets();
    const config = loadQPayConfig();
    const db = admin.firestore();
    const purchaseRef = db.collection("purchases").doc(purchaseId);
    const purchaseSnap = await purchaseRef.get();
    if (!purchaseSnap.exists) {
      throw new HttpsError("not-found", "Гүйлгээ олдсонгүй");
    }

    const purchase = purchaseSnap.data()!;
    if (purchase.userUid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "Эрхгүй");
    }
    if (purchase.status === "completed") {
      return { status: "completed", bidCount: purchase.bidCount };
    }

    const invoiceId = purchase.qpayInvoiceId as string | undefined;
    if (!invoiceId) {
      throw new HttpsError("failed-precondition", "Invoice олдсонгүй");
    }

    const paid = await hasPaidInvoice(config, invoiceId);
    if (paid) {
      await completePurchaseIfPending(db, purchaseId);
      return { status: "completed", bidCount: purchase.bidCount };
    }

    return { status: "pending" };
  },
);

export const qpayCallback = onRequest(
  {
    region: "asia-southeast1",
    secrets: qpaySecrets,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      applyQPaySecrets();
      const config = loadQPayConfig();
      const db = admin.firestore();

      const body = req.body as Record<string, unknown>;
      const invoiceId =
        (body.invoice_id as string | undefined) ||
        (body.object_id as string | undefined);

      if (!invoiceId) {
        res.status(400).send("invoice_id шаардлагатай");
        return;
      }

      const paid = await hasPaidInvoice(config, invoiceId);
      if (!paid) {
        res.status(200).json({ status: "pending" });
        return;
      }

      const purchaseSnap = await db
        .collection("purchases")
        .where("qpayInvoiceId", "==", invoiceId)
        .limit(1)
        .get();

      if (purchaseSnap.empty) {
        logger.warn("QPay callback: purchase олдсонгүй", { invoiceId });
        res.status(200).json({ status: "ignored" });
        return;
      }

      const purchaseId = purchaseSnap.docs[0].id;
      await completePurchaseIfPending(db, purchaseId);
      res.status(200).json({ status: "completed", purchaseId });
    } catch (error) {
      logger.error("qpayCallback алдаа", error);
      res.status(500).send("callback error");
    }
  },
);
