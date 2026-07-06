import * as admin from "firebase-admin";
import { phaseConfig, TOTAL_PHASES } from "./auction_phases";

const STATUS_ACTIVE = "active";
const STATUS_CLOSED = "closed";

export interface AuctionData {
  status?: string;
  price?: number;
  phase?: number;
  phaseStartedAt?: admin.firestore.Timestamp;
  winCountdownEndsAt?: admin.firestore.Timestamp;
  lastBidUid?: string;
  lastBidder?: string;
  endsAt?: admin.firestore.Timestamp;
}

export interface LifecycleResult {
  changed: boolean;
  action?: "winner" | "phase_advance" | "phase_extend";
}

function toMillis(ts: admin.firestore.Timestamp | undefined): number | null {
  return ts ? ts.toMillis() : null;
}

function addSeconds(
  base: admin.firestore.Timestamp,
  seconds: number,
): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(
    base.toMillis() + seconds * 1000,
  );
}

/**
 * Нэг дуудлагын lifecycle шалгах (transaction дотор дуудагдана).
 *
 * Дүрэм:
 * - winCountdownEndsAt дууссан + lastBidUid байвал → ялагч тодруулах
 * - winCountdownEndsAt дууссан + санал байхгүй → дараагийн үе
 * - 1–7-р үеийн хугацаа дууссан → дараагийн үе (ялагч тодрохгүй)
 * - 8-р үеийн хугацаа дууссан → сүүлийн санал өгсөн хүн ялагч
 */
export function evaluateAuctionLifecycle(
  data: AuctionData,
  now: admin.firestore.Timestamp,
): { updates: Record<string, unknown> | null; action?: LifecycleResult["action"] } {
  if (data.status !== STATUS_ACTIVE) {
    return { updates: null };
  }

  const phase = Math.min(
    Math.max((data.phase as number) ?? 1, 1),
    TOTAL_PHASES,
  );
  const config = phaseConfig(phase);
  const winEndsMs = toMillis(data.winCountdownEndsAt);
  const phaseStartMs = toMillis(data.phaseStartedAt);
  const nowMs = now.toMillis();

  if (winEndsMs !== null && nowMs >= winEndsMs) {
    if (data.lastBidUid) {
      return {
        action: "winner",
        updates: {
          status: STATUS_CLOSED,
          winnerUid: data.lastBidUid,
          winnerName: data.lastBidder ?? "",
          finalPrice: (data.price as number) ?? 0,
          updatedAt: now,
        },
      };
    }
    return buildPhaseAdvance(data, phase, now);
  }

  if (phaseStartMs !== null) {
    const phaseEndsMs = phaseStartMs + config.durationSeconds * 1000;
    if (nowMs >= phaseEndsMs) {
      if (phase < TOTAL_PHASES) {
        return buildPhaseAdvance(data, phase, now);
      }
      if (data.lastBidUid) {
        return {
          action: "winner",
          updates: {
            status: STATUS_CLOSED,
            winnerUid: data.lastBidUid,
            winnerName: data.lastBidder ?? "",
            finalPrice: (data.price as number) ?? 0,
            updatedAt: now,
          },
        };
      }
      return {
        action: "winner",
        updates: {
          status: STATUS_CLOSED,
          updatedAt: now,
        },
      };
    }
  }

  return { updates: null };
}

function buildPhaseAdvance(
  data: AuctionData,
  currentPhase: number,
  now: admin.firestore.Timestamp,
): { updates: Record<string, unknown>; action: "phase_advance" } {
  const nextPhase = Math.min(currentPhase + 1, TOTAL_PHASES);
  const nextConfig = phaseConfig(nextPhase);

  const updates: Record<string, unknown> = {
    phase: nextPhase,
    phaseStartedAt: now,
    winCountdownEndsAt: addSeconds(now, nextConfig.winCountdownSeconds),
    updatedAt: now,
  };

  return { updates, action: "phase_advance" };
}

/** Firestore transaction-оор нэг дуудлага боловсруулах */
export async function processAuctionById(
  db: admin.firestore.Firestore,
  auctionId: string,
): Promise<LifecycleResult> {
  const ref = db.collection("auctions").doc(auctionId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      return { changed: false };
    }

    const data = snap.data() as AuctionData;
    const now = admin.firestore.Timestamp.now();
    const { updates, action } = evaluateAuctionLifecycle(data, now);

    if (!updates) {
      return { changed: false };
    }

    tx.update(ref, updates);
    return { changed: true, action };
  });
}

/** Идэвхтэй, хугацаа нь дууссан дуудлагуудыг sweep хийх */
export async function sweepExpiredAuctions(
  db: admin.firestore.Firestore,
  limit = 50,
): Promise<number> {
  const now = admin.firestore.Timestamp.now();

  const byWinCountdown = await db
    .collection("auctions")
    .where("status", "==", STATUS_ACTIVE)
    .where("winCountdownEndsAt", "<=", now)
    .limit(limit)
    .get();

  const ids = new Set<string>();
  for (const doc of byWinCountdown.docs) {
    ids.add(doc.id);
  }

  // phaseStartedAt дууссан (win countdown ирээдүйд) дуудлагууд
  const activeSnap = await db
    .collection("auctions")
    .where("status", "==", STATUS_ACTIVE)
    .limit(100)
    .get();

  for (const doc of activeSnap.docs) {
    const data = doc.data() as AuctionData;
    const phase = Math.min(
      Math.max((data.phase as number) ?? 1, 1),
      TOTAL_PHASES,
    );
    const phaseStartMs = toMillis(data.phaseStartedAt);
    const winEndsMs = toMillis(data.winCountdownEndsAt);
    const nowMs = now.toMillis();

    if (phaseStartMs !== null) {
      const phaseEndsMs =
        phaseStartMs + phaseConfig(phase).durationSeconds * 1000;
      if (nowMs >= phaseEndsMs && (winEndsMs === null || nowMs < winEndsMs)) {
        ids.add(doc.id);
      }
    }
  }

  let processed = 0;
  for (const id of ids) {
    const result = await processAuctionById(db, id);
    if (result.changed) {
      processed += 1;
    }
  }

  return processed;
}

/** Дараагийн шалгах цагийг тооцоолох (Cloud Tasks schedule) */
export function nextCheckTime(data: AuctionData): Date | null {
  if (data.status !== STATUS_ACTIVE) {
    return null;
  }

  const phase = Math.min(
    Math.max((data.phase as number) ?? 1, 1),
    TOTAL_PHASES,
  );
  const config = phaseConfig(phase);
  const candidates: number[] = [];

  const winMs = toMillis(data.winCountdownEndsAt);
  if (winMs !== null) {
    candidates.push(winMs);
  }

  const phaseStartMs = toMillis(data.phaseStartedAt);
  if (phaseStartMs !== null) {
    candidates.push(phaseStartMs + config.durationSeconds * 1000);
  }

  if (candidates.length === 0) {
    return null;
  }

  return new Date(Math.min(...candidates));
}
