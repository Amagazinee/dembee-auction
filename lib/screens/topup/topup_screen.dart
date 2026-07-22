import 'package:flutter/material.dart';

import '../../core/app_navigation.dart';
import '../../core/constants/bid_packages.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../services/credits_service.dart';
import '../../services/qpay_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dembee_app_bar.dart';
import '../../widgets/qpay_payment_sheet.dart';

/// Figma TopUpView — Санал багц авах
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _creditsService = CreditsService();
  final _qpayService = QPayService();
  BidPackage? _selected;
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null) {
      setState(() => _error = 'Багц сонгоно уу');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final session = await _qpayService.createPayment(package.id);
      if (!mounted) return;

      final paid = await showQPayPaymentSheet(
        context,
        session: session,
        creditsService: _creditsService,
        qpayService: _qpayService,
      );

      if (!mounted) return;
      if (paid == true) {
        setState(() {
          _success = '${package.amount} санал нэмэгдлээ!';
          _selected = null;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _creditsService.watchCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final balance = user?.bidBalance ?? 0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: DembeeAppBar(
            bidBalance: balance,
            user: user,
            showAdminBadge: user?.isAdmin ?? false,
            showHomeButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Санал багц авах',
                  style: AppTheme.headingStyle.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Санал багц худалдан авч дуудлага худалдаанд оролцоно. '
                          'Санал бүр үнийг нэмж, ялагч тодорхойлох хугацааг дахин эхлүүлнэ.',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 13,
                            color: AppTheme.secondaryForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Одоогийн үлдэгдэл: $balance санал',
                  style: AppTheme.monoStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Text(
                  'БАГЦ СОНГОХ',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: BidPackages.all.length,
                  itemBuilder: (context, index) {
                    final pkg = BidPackages.all[index];
                    final isSelected = _selected?.id == pkg.id;
                    return _PackageCard(
                      package: pkg,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = pkg),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'ТӨЛБӨРИЙН АРГА',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const _PaymentChip(
                      label: 'QPay',
                      selected: true,
                    ),
                    const SizedBox(width: 12),
                    _PaymentChip(
                      label: 'Golomt Bank (удахгүй)',
                      selected: false,
                      enabled: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'QPay-ээр төлсний дараа санал автоматаар нэмэгдэнэ.',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.destructive)),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  Text(_success!, style: const TextStyle(color: AppTheme.primary)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _purchase,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('QPay-ээр төлөх'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => popOrGoHome(context),
                    child: const Text('Буцах'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final BidPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (package.popular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppTheme.primary,
                  child: Text(
                    'АЛДАРТАЙ',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 8,
                      color: AppTheme.primaryForeground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: AppTheme.primary, size: 20),
                const SizedBox(height: 8),
                Text(
                  '${package.amount} санал',
                  style: AppTheme.headingStyle.copyWith(fontSize: 18),
                ),
                Text(
                  formatPrice(package.price),
                  style: AppTheme.monoStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '1 санал = ${formatPrice(package.pricePerBid)}',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.selected,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = !enabled
        ? AppTheme.border.withValues(alpha: 0.5)
        : selected
            ? AppTheme.primary
            : AppTheme.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTheme.bodyStyle.copyWith(
          color: enabled
              ? AppTheme.foreground
              : AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
