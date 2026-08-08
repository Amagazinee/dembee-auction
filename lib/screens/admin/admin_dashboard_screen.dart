import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../core/app_navigation.dart';
import '../../services/auction_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dembee_logo.dart';
import '../../widgets/go_home_button.dart';
import '../../widgets/loading_widget.dart';
import 'admin_auctions_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_transactions_tab.dart';
import 'admin_users_tab.dart';

/// Figma Admin Panel
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late int _tab;
  final _auctionService = AuctionService();
  final _creditsService = CreditsService();
  final _tabScrollController = ScrollController();
  bool _showTabScrollHint = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 4);
    _tabScrollController.addListener(_updateTabScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTabScrollHint());
  }

  @override
  void dispose() {
    _tabScrollController
      ..removeListener(_updateTabScrollHint)
      ..dispose();
    super.dispose();
  }

  void _updateTabScrollHint() {
    if (!_tabScrollController.hasClients) return;
    final showHint = _tabScrollController.position.maxScrollExtent > 0 &&
        _tabScrollController.offset <
            _tabScrollController.position.maxScrollExtent - 4;
    if (showHint != _showTabScrollHint && mounted) {
      setState(() => _showTabScrollHint = showHint);
    }
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
  }

  static const _tabLabels = [
    'Ерөнхий',
    'Дуудлага',
    'Хэрэглэгч',
    'Гүйлгээ',
    'Тайлан',
  ];
  static const _tabIcons = [
    Icons.show_chart,
    Icons.gavel,
    Icons.people_outline,
    Icons.swap_horiz,
    Icons.summarize_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _creditsService.watchCurrentUser(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user != null && !user.isAdmin) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Зөвхөн админ хандах боломжтой'),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Буцах'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Буцах',
              onPressed: () => popOrGoHome(context),
            ),
            actions: const [
              GoHomeIconButton(compact: true),
            ],
            title: Row(
              children: [
                const DembeeLogo(size: 24, textSize: 14),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'АДМИН САМБАР',
                    style: AppTheme.monoStyle.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppTheme.border),
                  Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _tabScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: List.generate(_tabLabels.length, (i) {
                            final active = _tab == i;
                            return InkWell(
                              onTap: () => _selectTab(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: active
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _tabIcons[i],
                                      size: 16,
                                      color: active
                                          ? AppTheme.primary
                                          : AppTheme.mutedForeground,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _tabLabels[i],
                                      style: AppTheme.bodyStyle.copyWith(
                                        fontSize: 13,
                                        color: active
                                            ? AppTheme.primary
                                            : AppTheme.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (_showTabScrollHint)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              width: 36,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppTheme.background.withValues(alpha: 0),
                                    AppTheme.background,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: switch (_tab) {
            0 => _OverviewTab(
                auctionService: _auctionService,
                creditsService: _creditsService,
                onOpenReports: () => _selectTab(4),
              ),
            1 => AdminAuctionsTab(auctionService: _auctionService),
            2 => AdminUsersTab(creditsService: _creditsService),
            3 => AdminTransactionsTab(creditsService: _creditsService),
            4 => AdminReportsTab(
                auctionService: _auctionService,
                creditsService: _creditsService,
              ),
            _ => Center(
                child: Text(
                  '${_tabLabels[_tab]} — удахгүй',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ),
          },
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.auctionService,
    required this.creditsService,
    required this.onOpenReports,
  });

  final AuctionService auctionService;
  final CreditsService creditsService;
  final VoidCallback onOpenReports;

  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: auctionService.watchAuctions(),
      builder: (context, auctionSnap) {
        if (!auctionSnap.hasData) {
          return const LoadingWidget();
        }

        return StreamBuilder<List<UserModel>>(
          stream: creditsService.watchAllUsersList(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const LoadingWidget();
            }

            return StreamBuilder<List<PurchaseModel>>(
              stream: creditsService.watchAllCompletedPurchases(),
              builder: (context, purchaseSnap) {
                if (!purchaseSnap.hasData) {
                  return const LoadingWidget();
                }

                return StreamBuilder<List<BidHistoryModel>>(
                  stream: auctionService.watchAllBidHistory(),
                  builder: (context, bidSnap) {
                    if (!bidSnap.hasData) {
                      return const LoadingWidget();
                    }

                    final auctions = auctionSnap.data!;
                    final users = userSnap.data!;
                    final purchases = purchaseSnap.data!;
                    final bids = bidSnap.data!;

                    final ongoing =
                        auctions.where((a) => a.isOngoing).toList();
                    final activeCount = ongoing.length;
                    final finishedCount =
                        auctions.where((a) => a.isFinished).length;
                    final totalBids =
                        auctions.fold<int>(0, (s, a) => s + a.totalBids);
                    final usersToday =
                        users.where((u) => _isToday(u.createdAt)).length;
                    final totalRevenue =
                        purchases.fold<int>(0, (s, p) => s + p.amount);
                    final bidsToday =
                        bids.where((b) => _isToday(b.createdAt)).length;

                    final usersById = {
                      for (final u in users) u.uid: u,
                    };

                    final phaseCounts = List.filled(8, 0);
                    for (final a in ongoing) {
                      final p = a.currentPhase.clamp(1, 8) - 1;
                      phaseCounts[p]++;
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onOpenReports,
                            icon: const Icon(Icons.summarize_outlined, size: 18),
                            label: const Text('Тайлан харах (CSV)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, c) {
                              final cols = c.maxWidth > 600 ? 4 : 2;
                              return GridView.count(
                                crossAxisCount: cols,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.6,
                                children: [
                                  _AdminStatCard(
                                    value: '${users.length}',
                                    label: 'Нийт хэрэглэгч',
                                    sub: usersToday > 0
                                        ? '+$usersToday өнөөдөр'
                                        : 'Өнөөдөр шинэ бүртгэлгүй',
                                    color: const Color(0xFF60A5FA),
                                  ),
                                  _AdminStatCard(
                                    value: '$activeCount',
                                    label: 'Идэвхтэй дуудлага',
                                    sub:
                                        '$finishedCount дууссан · ${formatNumber(totalBids)} санал',
                                    color: AppTheme.primary,
                                  ),
                                  _AdminStatCard(
                                    value: formatPrice(totalRevenue),
                                    label: 'Нийт орлого',
                                    sub: '${purchases.length} гүйлгээ',
                                    color: const Color(0xFF22C55E),
                                  ),
                                  _AdminStatCard(
                                    value: '$bidsToday',
                                    label: 'Өнөөдрийн санал',
                                    sub: 'Дуудлага худалдаа',
                                    color: const Color(0xFFA855F7),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Дуудлагын үе хуваарилалт',
                                  style: AppTheme.headingStyle.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(8, (i) {
                                  const colors = [
                                    Color(0xFF22D3EE),
                                    Color(0xFF3B82F6),
                                    Color(0xFF8B5CF6),
                                    Color(0xFFA855F7),
                                    Color(0xFFEC4899),
                                    Color(0xFFF97316),
                                    Color(0xFFEAB308),
                                    Color(0xFFEF4444),
                                  ];
                                  final count = phaseCounts[i];
                                  final max = phaseCounts.reduce(
                                    (a, b) => a > b ? a : b,
                                  );
                                  final flex = max == 0 ? 0 : count;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 48,
                                          child: Text(
                                            '${i + 1}-р үе',
                                            style: AppTheme.bodyStyle.copyWith(
                                              fontSize: 12,
                                              color: AppTheme.mutedForeground,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: Row(
                                              children: [
                                                if (flex > 0)
                                                  Expanded(
                                                    flex: flex,
                                                    child: Container(
                                                      height: 8,
                                                      color: colors[i],
                                                    ),
                                                  ),
                                                if (max - flex > 0)
                                                  Expanded(
                                                    flex: max - flex,
                                                    child: Container(
                                                      height: 8,
                                                      color: AppTheme.muted,
                                                    ),
                                                  ),
                                                if (max == 0)
                                                  Expanded(
                                                    child: Container(
                                                      height: 8,
                                                      color: AppTheme.muted,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$count',
                                          style: AppTheme.monoStyle.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Сүүлийн гүйлгээнүүд',
                                  style: AppTheme.headingStyle.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (purchases.isEmpty)
                                  Text(
                                    'Гүйлгээ байхгүй',
                                    style: AppTheme.bodyStyle.copyWith(
                                      fontSize: 13,
                                      color: AppTheme.mutedForeground,
                                    ),
                                  )
                                else
                                  ...purchases.take(5).toList().asMap().entries.map(
                                    (entry) {
                                      final p = entry.value;
                                      final user = usersById[p.userUid];
                                      final userLabel =
                                          user?.name.isNotEmpty == true
                                              ? user!.name
                                              : 'Хэрэглэгч';
                                      return Column(
                                        children: [
                                          if (entry.key > 0)
                                            const Divider(
                                              color: AppTheme.border,
                                              height: 20,
                                            ),
                                          _TransactionRow(
                                            title:
                                                '$userLabel · ${p.bidCount} санал',
                                            sub:
                                                '${formatDateTime(p.createdAt)} · ${p.paymentLabel}',
                                            amount:
                                                '+${formatPrice(p.amount)}',
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.value,
    required this.label,
    required this.sub,
    required this.color,
  });

  final String value;
  final String label;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: AppTheme.mutedForeground,
            ),
          ),
          Text(
            sub,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 10,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.sub,
    required this.amount,
  });

  final String title;
  final String sub;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.bodyStyle.copyWith(fontSize: 13)),
              Text(
                sub,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 11,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: AppTheme.monoStyle.copyWith(
            fontSize: 14,
            color: const Color(0xFF22C55E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
