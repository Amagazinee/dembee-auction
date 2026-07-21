import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/formatters.dart';
import '../services/credits_service.dart';
import '../services/qpay_service.dart';
import '../theme/app_theme.dart';

class QPayPaymentSheet extends StatefulWidget {
  const QPayPaymentSheet({
    super.key,
    required this.session,
    required this.creditsService,
    required this.qpayService,
  });

  final QPayPaymentSession session;
  final CreditsService creditsService;
  final QPayService qpayService;

  @override
  State<QPayPaymentSheet> createState() => _QPayPaymentSheetState();
}

class _QPayPaymentSheetState extends State<QPayPaymentSheet> {
  bool _checking = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _manualCheck(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _manualCheck({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() => _checking = true);
    try {
      await widget.qpayService.checkPayment(widget.session.purchaseId);
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.creditsService.watchPurchase(widget.session.purchaseId),
      builder: (context, snapshot) {
        final purchase = snapshot.data;
        final completed = purchase?.isCompleted ?? false;

        if (completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pop(true);
          });
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'QPay төлбөр',
                      style: AppTheme.headingStyle.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${widget.session.bidCount} санал · ${formatPrice(widget.session.amount)}',
                style: AppTheme.monoStyle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (widget.session.qrImage.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(
                      base64Decode(widget.session.qrImage),
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Банкны апп-аар төлөх',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.session.urls.isEmpty)
                OutlinedButton(
                  onPressed: widget.session.shortUrl.isEmpty
                      ? null
                      : () => _openLink(widget.session.shortUrl),
                  child: const Text('QPay хуудас нээх'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final bank in widget.session.urls)
                      OutlinedButton(
                        onPressed: () => _openLink(bank.link),
                        child: Text(bank.name),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _checking ? null : () => _manualCheck(),
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Төлбөр шалгах'),
              ),
              const SizedBox(height: 8),
              Text(
                'Төлбөр төлсний дараа автоматаар баталгаажина.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 11,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<bool?> showQPayPaymentSheet(
  BuildContext context, {
  required QPayPaymentSession session,
  required CreditsService creditsService,
  required QPayService qpayService,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) => QPayPaymentSheet(
      session: session,
      creditsService: creditsService,
      qpayService: qpayService,
    ),
  );
}
