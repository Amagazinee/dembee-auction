"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.purgeHistoricalData = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const firebase_functions_1 = require("firebase-functions");
admin.initializeApp();
const region = "asia-southeast1";
const BATCH_SIZE = 400;
async function assertAdmin(uid) {
    const db = admin.firestore();
    const userSnap = await db.collection("users").doc(uid).get();
    if (!userSnap.exists || userSnap.data()?.role !== "admin") {
        throw new https_1.HttpsError("permission-denied", "Зөвхөн админ цэвэрлэх боломжтой");
    }
}
async function deleteQueryInBatches(query) {
    let deleted = 0;
    // eslint-disable-next-line no-constant-condition
    while (true) {
        const snapshot = await query.limit(BATCH_SIZE).get();
        if (snapshot.empty)
            break;
        const batch = admin.firestore().batch();
        snapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        deleted += snapshot.size;
    }
    return deleted;
}
function isFinishedAuction(data) {
    if (data.status === "closed")
        return true;
    const endsAt = data.endsAt?.toDate?.();
    return endsAt != null && endsAt.getTime() < Date.now();
}
async function deleteFinishedAuctions(db) {
    const snapshot = await db.collection("auctions").get();
    const finishedDocs = snapshot.docs.filter((doc) => isFinishedAuction(doc.data()));
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
            }
            catch (error) {
                firebase_functions_1.logger.warn(`Storage устгах алдаа (${doc.id})`, error);
            }
        }
        await batch.commit();
    }
    return { auctions: finishedDocs.length, storageFiles };
}
/** Админ — дууссан дуудлага, түүх, гүйлгээ, мэдэгдлийг бүрэн цэвэрлэнэ */
exports.purgeHistoricalData = (0, https_1.onCall)({ region }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Нэвтэрнэ үү");
    }
    await assertAdmin(request.auth.uid);
    const confirm = request.data?.confirm === true;
    if (!confirm) {
        throw new https_1.HttpsError("failed-precondition", "Баталгаажуулалт шаардлагатай (confirm: true)");
    }
    const db = admin.firestore();
    const counts = {
        auctions: 0,
        auctionHistory: 0,
        purchases: 0,
        notifications: 0,
        storageFiles: 0,
    };
    const auctionResult = await deleteFinishedAuctions(db);
    counts.auctions = auctionResult.auctions;
    counts.storageFiles = auctionResult.storageFiles;
    counts.auctionHistory = await deleteQueryInBatches(db.collection("auctionHistory"));
    counts.purchases = await deleteQueryInBatches(db.collection("purchases"));
    counts.notifications = await deleteQueryInBatches(db.collection("notifications"));
    firebase_functions_1.logger.info("purgeHistoricalData дууслаа", counts);
    return counts;
});
//# sourceMappingURL=index.js.map