import { randomUUID } from "crypto";
import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const region = "asia-southeast1";
const MAX_BYTES = 5 * 1024 * 1024;

async function assertAdminUid(uid: string): Promise<void> {
  const db = admin.firestore();
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists || userSnap.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }
}

/** Admin auction image upload (lightweight codebase for Windows deploy) */
export const uploadAuctionImageAdmin = onCall({ region }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  await assertAdminUid(request.auth.uid);

  const auctionId = (request.data?.auctionId as string | undefined)?.trim();
  const imageBase64 = request.data?.imageBase64 as string | undefined;
  const extension = (request.data?.extension as string | undefined) ?? "jpg";

  if (!auctionId || !imageBase64) {
    throw new HttpsError("invalid-argument", "Image required");
  }

  let buffer: Buffer;
  try {
    buffer = Buffer.from(imageBase64, "base64");
  } catch {
    throw new HttpsError("invalid-argument", "Invalid image format");
  }

  if (buffer.length === 0) {
    throw new HttpsError("invalid-argument", "Empty image");
  }
  if (buffer.length > MAX_BYTES) {
    throw new HttpsError("invalid-argument", "Image exceeds 5MB");
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
});
