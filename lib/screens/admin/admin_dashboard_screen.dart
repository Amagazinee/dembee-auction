import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dembee_logo.dart';
import '../../widgets/loading_widget.dart';
import 'admin_auctions_tab.dart';
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

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 3);
  }

  static const _tabLabels = ['Ерөнхий', 'Дуудлага', 'Хэрэглэгч', 'Гүйлгээ'];
  static const _tabIcons = [
    Icons.show_chart,
    Icons.gavel,
    Icons.people_outline,
    Icons.swap_horiz,
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
              onPressed: () => context.go('/home'),
            ),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: List.generate(_tabLabels.length, (i) {
                        final active = _tab == i;
                        return InkWell(
                          onTap: () => setState(() => _tab = i),
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
                ],
              ),
            ),
          ),
          body: switch (_tab) {
            0 => _OverviewTab(auctionService: _auctionService),
            1 => AdminAuctionsTab(auctionService: _auctionService),
            2 => AdminUsersTab(creditsService: _creditsService),
            3 => AdminTransactionsTab(creditsService: _creditsService),
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
  const _OverviewTab({required this.auctionService});

  final AuctionService auctionService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: auctionService.watchAuctions(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const LoadingWidget();
        }

        final auctions = snap.data!;
        final active =
            auctions.where((a) => a.isActive && !a.hasEnded).length;
        final totalBids =
            auctions.fold<int>(0, (s, a) => s + a.totalBids);

        final phaseCounts = List.filled(8, 0);
        for (final a in auctions.where((x) => x.isActive && !x.hasEnded)) {
          final p = a.currentPhase.clamp(1, 8) - 1;
          phaseCounts[p]++;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        value: '4',
                        label: 'Нийт хэрэглэгч',
                        sub: '+12 өнөөдөр',
                        color: const Color(0xFF60A5FA),
                      ),
                      _AdminStatCard(
                        value: '$active',
                        label: 'Идэвхтэй дуудлага',
                        sub: '${formatNumber(totalBids)} нийт санал',
                        color: AppTheme.primary,
                      ),
                      _AdminStatCard(
                        value: '₮373,000',
                        label: 'Нийт орлого',
                        sub: 'Цэнэглэлт',
                        color: const Color(0xFF22C55E),
                      ),
                      _AdminStatCard(
                        value: '621',
                        label: 'Өнөөдрийн санал',
                        sub: 'Идэвхтэй',
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
                      style: AppTheme.headingStyle.copyWith(fontSize: 16),
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
                      final max = phaseCounts.reduce((a, b) => a > b ? a : b);
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
                                borderRadius: BorderRadius.circular(2),
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
                              style: AppTheme.monoStyle.copyWith(fontSize: 12),
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
                      style: AppTheme.headingStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _TransactionRow(
                      title: 'Санал багц — 200 санал',
                      sub: '2024-12-20 · QPay',
                      amount: '+₮110,000',
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    _TransactionRow(
                      title: 'Санал багц — 40 санал',
                      sub: '2024-12-19 · Khan Bank',
                      amount: '+₮30,000',
                    ),
                  ],
                ),
              ),
            ],
          ),
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
