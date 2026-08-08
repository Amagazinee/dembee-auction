import { randomUUID } from "crypto";
import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

const region = "asia-southeast1";
const MAX_BYTES = 5 * 1024 * 1024;
const PROJECT_ID = "dembee-auction";
const STORAGE_BUCKETS = [
  `${PROJECT_ID}.firebasestorage.app`,
  `${PROJECT_ID}.appspot.com`,
];

async function saveImageToBucket(
  buffer: Buffer,
  objectPath: string,
  contentType: string,
  token: string,
): Promise<{ bucketName: string; objectPath: string }> {
  const candidates = [
    admin.app().options.storageBucket,
    ...STORAGE_BUCKETS,
  ].filter((value, index, array): value is string => {
    return !!value && array.indexOf(value) === index;
  });

  let lastError: unknown;
  for (const bucketName of candidates) {
    try {
      const bucket = admin.storage().bucket(bucketName);
      const file = bucket.file(objectPath);
      await file.save(buffer, {
        metadata: {
          contentType,
          metadata: {
            firebaseStorageDownloadTokens: token,
          },
        },
      });
      return { bucketName, objectPath };
    } catch (error) {
      lastError = error;
      logger.warn(`Bucket ${bucketName} upload failed`, error);
    }
  }

  throw new HttpsError(
    "internal",
    lastError instanceof Error
      ? lastError.message
      : "Storage bucket not found",
  );
}

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
  const token = randomUUID();

  const saved = await saveImageToBucket(buffer, objectPath, contentType, token);
  const encodedPath = encodeURIComponent(saved.objectPath);
  const downloadUrl =
    `https://firebasestorage.googleapis.com/v0/b/${saved.bucketName}/o/${encodedPath}?alt=media&token=${token}`;

  return { downloadUrl };
});
