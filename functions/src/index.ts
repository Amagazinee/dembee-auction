import * as admin from "firebase-admin";
import { getFunctions } from "firebase-admin/functions";
import {
  onDocumentWritten,
  FirestoreEvent,
  Change,
  DocumentSnapshot,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { logger } from "firebase-functions";
import {
  nextCheckTime,
  processAuctionById,
  sweepExpiredAuctions,
  AuctionData,
} from "./auction_lifecycle";

admin.initializeApp();

const db = admin.firestore();
const region = "asia-southeast1";

/** Task queue — яг цагт нэг дуудлага шалгана */
export const processAuctionTask = onTaskDispatched(
  {
    region,
    retryConfig: { maxAttempts: 3, minBackoffSeconds: 10 },
    rateLimits: { maxConcurrentDispatches: 20 },
  },
  async (req) => {
    const auctionId = req.data.auctionId as string;
    if (!auctionId) {
      logger.warn("processAuctionTask: auctionId байхгүй");
      return;
    }

    const result = await processAuctionById(db, auctionId);
    if (result.changed) {
      logger.info(`Дуудлага ${auctionId}: ${result.action}`);
    }
  },
);

/** Дуудлага өөрчлөгдөхөд дараагийн шалгалтыг task queue-д төлөвлөнө */
export const scheduleAuctionLifecycle = onDocumentWritten(
  {
    document: "auctions/{auctionId}",
    region,
  },
  async (
    event: FirestoreEvent<Change<DocumentSnapshot> | undefined>,
  ) => {
    const auctionId = event.params.auctionId;
    const after = event.data?.after;
    if (!after?.exists) {
      return;
    }

    const data = after.data() as AuctionData;
    if (data.status !== "active") {
      return;
    }

    const when = nextCheckTime(data);
    if (!when) {
      return;
    }

    // Ирээдүйн цаг хүртэл хүлээнэ
    const delayMs = when.getTime() - Date.now();
    if (delayMs < 0) {
      // Аль хэдийн хугацаа дууссан — шууд боловсруулна
      await processAuctionById(db, auctionId);
      return;
    }

    const queue = getFunctions().taskQueue(
      `locations/${region}/functions/processAuctionTask`,
    );

    await queue.enqueue(
      { auctionId },
      {
        scheduleTime: when,
        dispatchDeadlineSeconds: 60,
        id: `auction-${auctionId}-${when.getTime()}`,
      },
    );

    logger.debug(`Дуудлага ${auctionId} шалгалт: ${when.toISOString()}`);
  },
);

/** Нөөц sweep — task алдагдсан тохиолдолд минут бүр */
export const sweepAuctionLifecycle = onSchedule(
  {
    schedule: "every 1 minutes",
    region,
    timeZone: "Asia/Ulaanbaatar",
  },
  async () => {
    const count = await sweepExpiredAuctions(db);
    if (count > 0) {
      logger.info(`Sweep: ${count} дуудлага боловсруулагдлаа`);
    }
  },
);
