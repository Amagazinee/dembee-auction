/** 8 үе механик — lib/core/constants/auction_phases.dart-тай ижил */
export interface AuctionPhaseConfig {
  phase: number;
  durationSeconds: number;
  winCountdownSeconds: number;
}

export const TOTAL_PHASES = 8;

export const AUCTION_PHASES: AuctionPhaseConfig[] = [
  { phase: 1, durationSeconds: 7200, winCountdownSeconds: 1800 },
  { phase: 2, durationSeconds: 3600, winCountdownSeconds: 1800 },
  { phase: 3, durationSeconds: 3600, winCountdownSeconds: 1800 },
  { phase: 4, durationSeconds: 3600, winCountdownSeconds: 1800 },
  { phase: 5, durationSeconds: 1800, winCountdownSeconds: 600 },
  { phase: 6, durationSeconds: 1800, winCountdownSeconds: 60 },
  { phase: 7, durationSeconds: 1800, winCountdownSeconds: 10 },
  { phase: 8, durationSeconds: 1800, winCountdownSeconds: 3 },
];

export function phaseConfig(phase: number): AuctionPhaseConfig {
  const found = AUCTION_PHASES.find((c) => c.phase === phase);
  return found ?? AUCTION_PHASES[0];
}
