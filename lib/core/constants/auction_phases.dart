/// 8 үе механик — Figma PhaseBar / DualTimer
class AuctionPhaseConfig {
  const AuctionPhaseConfig({
    required this.phase,
    required this.durationSeconds,
    required this.winCountdownSeconds,
  });

  final int phase;
  final int durationSeconds;
  final int winCountdownSeconds;

  Duration get duration => Duration(seconds: durationSeconds);
  Duration get winCountdown => Duration(seconds: winCountdownSeconds);
}

class AuctionPhases {
  AuctionPhases._();

  static const int totalPhases = 8;

  static const List<AuctionPhaseConfig> configs = [
    AuctionPhaseConfig(phase: 1, durationSeconds: 7200, winCountdownSeconds: 1800),
    AuctionPhaseConfig(phase: 2, durationSeconds: 3600, winCountdownSeconds: 1800),
    AuctionPhaseConfig(phase: 3, durationSeconds: 3600, winCountdownSeconds: 1800),
    AuctionPhaseConfig(phase: 4, durationSeconds: 3600, winCountdownSeconds: 1800),
    AuctionPhaseConfig(phase: 5, durationSeconds: 1800, winCountdownSeconds: 600),
    AuctionPhaseConfig(phase: 6, durationSeconds: 1800, winCountdownSeconds: 60),
    AuctionPhaseConfig(phase: 7, durationSeconds: 1800, winCountdownSeconds: 10),
    AuctionPhaseConfig(phase: 8, durationSeconds: 1800, winCountdownSeconds: 3),
  ];

  static AuctionPhaseConfig forPhase(int phase) {
    return configs.firstWhere(
      (c) => c.phase == phase,
      orElse: () => configs.first,
    );
  }
}
