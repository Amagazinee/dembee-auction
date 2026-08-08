import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { uploadAuctionImageAdmin } from "./auction_image";

admin.initializeApp();

const region = "asia-southeast1";
const BATCH_SIZE = 400;

type PurgeCounts = {
  auctions: number;
  auctionHistory: number;
  purchases: number;
  notifications: number;
  storageFiles: number;
};

async function assertAdmin(uid: string): Promise<void> {
  const db = admin.firestore();
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists || userSnap.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Зөвхөн админ цэвэрлэх боломжтой");
  }
}

async function deleteQueryInBatches(
  query: FirebaseFirestore.Query,
): Promise<number> {
  let deleted = 0;

  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snapshot = await query.limit(BATCH_SIZE).get();
    if (snapshot.empty) break;

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snapshot.size;
  }

  return deleted;
}

function isFinishedAuction(data: FirebaseFirestore.DocumentData): boolean {
  if (data.status === "closed") return true;
  const endsAt = data.endsAt?.toDate?.() as Date | undefined;
  return endsAt != null && endsAt.getTime() < Date.now();
}

async function deleteFinishedAuctions(db: FirebaseFirestore.Firestore): Promise<{
  auctions: number;
  storageFiles: number;
}> {
  const snapshot = await db.collection("auctions").get();
  const finishedDocs = snapshot.docs.filter((doc) =>
    isFinishedAuction(doc.data()),
  );

  let storageFiles = 0;
  const bucket = admin.storage().bucket();

  for (let i = 0; i < finishedDocs.length; i += BATCH_SIZE) {
    const chunk = finishedDocs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.delete(doc.ref);
      try {
        const [files] = await bucket.getFiles({ prefix: `auctions/${doc.id}/` });
        if (files.length > 0) {
          await Promise.all(files.map((file) => file.delete()));
          storageFiles += files.length;
        }
      } catch (error) {
        logger.warn(`Storage устгах алдаа (${doc.id})`, error);
      }
    }
    await batch.commit();
  }

  return { auctions: finishedDocs.length, storageFiles };
}

/** Админ — дууссан дуудлага, түүх, гүйлгээ, мэдэгдлийг бүрэн цэвэрлэнэ */
export const purgeHistoricalData = onCall({ region }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Нэвтэрнэ үү");
  }

  await assertAdmin(request.auth.uid);

  const confirm = request.data?.confirm === true;
  if (!confirm) {
    throw new HttpsError(
      "failed-precondition",
      "Баталгаажуулалт шаардлагатай (confirm: true)",
    );
  }

  const db = admin.firestore();
  const counts: PurgeCounts = {
    auctions: 0,
    auctionHistory: 0,
    purchases: 0,
    notifications: 0,
    storageFiles: 0,
  };

  const auctionResult = await deleteFinishedAuctions(db);
  counts.auctions = auctionResult.auctions;
  counts.storageFiles = auctionResult.storageFiles;

  counts.auctionHistory = await deleteQueryInBatches(
    db.collection("auctionHistory"),
  );
  counts.purchases = await deleteQueryInBatches(db.collection("purchases"));
  counts.notifications = await deleteQueryInBatches(
    db.collection("notifications"),
  );

  logger.info("purgeHistoricalData done", counts);
  return counts;
});

export { uploadAuctionImageAdmin };
