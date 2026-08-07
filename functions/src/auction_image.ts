import * as admin from "firebase-admin";
import { randomUUID } from "crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const region = "asia-southeast1";
const MAX_BYTES = 5 * 1024 * 1024;

/** Админ — дуудлагын зураг (Storage дүрэм deploy хийгдээгүй үед ч ажиллана) */
export const uploadAuctionImageAdmin = onCall(
  { region },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Нэвтэрнэ үү");
    }

    const db = admin.firestore();
    const userSnap = await db.collection("users").doc(request.auth.uid).get();
    if (!userSnap.exists || userSnap.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Зөвхөн админ зураг upload хийнэ");
    }

    const auctionId = (request.data?.auctionId as string | undefined)?.trim();
    const imageBase64 = request.data?.imageBase64 as string | undefined;
    const extension = (request.data?.extension as string | undefined) ?? "jpg";

    if (!auctionId || !imageBase64) {
      throw new HttpsError("invalid-argument", "Зураг шаардлагатай");
    }

    let buffer: Buffer;
    try {
      buffer = Buffer.from(imageBase64, "base64");
    } catch {
      throw new HttpsError("invalid-argument", "Зураг буруу форматтай");
    }

    if (buffer.length === 0) {
      throw new HttpsError("invalid-argument", "Зураг хоосон байна");
    }
    if (buffer.length > MAX_BYTES) {
      throw new HttpsError("invalid-argument", "Зураг 5MB-аас их байна");
    }

    const safeExt = extension.toLowerCase() === "png" ? "png" : "jpg";
    const contentType = safeExt === "png" ? "image/png" : "image/jpeg";
    const objectPath = `auctions/${auctionId}/cover.${safeExt}`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(objectPath);
    const token = randomUUID();

    await file.save(buffer, {
      metadata: {
        contentType,
        metadata: {
          firebaseStorageDownloadTokens: token,
        },
      },
    });

    const encodedPath = encodeURIComponent(objectPath);
    const downloadUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${token}`;

    return { downloadUrl };
  },
);
