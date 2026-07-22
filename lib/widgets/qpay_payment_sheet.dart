import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/formatters.dart';
import '../models/purchase_model.dart';
import '../services/credits_service.dart';
import '../services/qpay_service.dart';
import '../theme/app_theme.dart';

class QPayPaymentSheet extends StatefulWidget {
  const QPayPaymentSheet({
    super.key,
    required this.session,
    required this.creditsService,
    required this.qpayService,
    required this.onClose,
    required this.onPaid,
  });

  final QPayPaymentSession session;
  final CreditsService creditsService;
  final QPayService qpayService;
  final VoidCallback onClose;
  final VoidCallback onPaid;

  @override
  State<QPayPaymentSheet> createState() => _QPayPaymentSheetState();
}

class _QPayPaymentSheetState extends State<QPayPaymentSheet> {
  bool _checking = false;
  bool _handledCompletion = false;
  Timer? _pollTimer;
  StreamSubscription<PurchaseModel?>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    _purchaseSub = widget.creditsService
        .watchPurchase(widget.session.purchaseId)
        .listen(_onPurchaseUpdate);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _manualCheck(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _onPurchaseUpdate(PurchaseModel? purchase) {
    if (!mounted || _handledCompletion) return;
    if (purchase?.isCompleted ?? false) {
      _handledCompletion = true;
      widget.onPaid();
    }
  }

  Future<void> _manualCheck({bool silent = false}) async {
    if (_checking || _handledCompletion) return;
    if (!silent) setState(() => _checking = true);
    try {
      await widget.qpayService.checkPayment(widget.session.purchaseId);
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Төлбөр шалгахад алдаа гарлаа')),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      _showMessage('Буруу холбоос');
      return;
    }

    final canOpen = await canLaunchUrl(uri);
    if (!canOpen) {
      _showMessage('Энэ төхөөрөмж дээр нээх боломжгүй');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showMessage('Холбоос нээхэд алдаа гарлаа');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return PopScope(
      canPop: true,
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'QPay төлбөр',
                      style: AppTheme.headingStyle.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    tooltip: 'Хаах',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${widget.session.bidCount} санал · ${formatPrice(widget.session.amount)}',
                style: AppTheme.monoStyle.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                              onPressed: bank.link.isEmpty
                                  ? null
                                  : () => _openLink(bank.link),
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
              ),
            ),
          ],
        ),
      ),
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
    isDismissible: true,
    enableDrag: true,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: QPayPaymentSheet(
          session: session,
          creditsService: creditsService,
          qpayService: qpayService,
          onClose: () => Navigator.of(sheetContext).pop(false),
          onPaid: () => Navigator.of(sheetContext).pop(true),
        ),
      );
    },
  );
}
