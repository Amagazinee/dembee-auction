import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/user_model.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

/// Админ самбар — бүх бүртгэлтэй хэрэглэгчид
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key, required this.creditsService});

  final CreditsService creditsService;

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchController = TextEditingController();
  String? _busyUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterUsers(List<UserModel> allUsers) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return allUsers;

    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    return allUsers.where((u) {
      if (u.name.toLowerCase().contains(q)) return true;
      if (u.email.toLowerCase().contains(q)) return true;
      final phone = u.phone.toLowerCase();
      if (phone.contains(q)) return true;
      if (qDigits.isNotEmpty) {
        final phoneDigits = u.phone.replaceAll(RegExp(r'\D'), '');
        if (phoneDigits.contains(qDigits)) return true;
      }
      return false;
    }).toList();
  }

  Future<void> _runUserAction(
    String userId,
    Future<void> Function() action,
  ) async {
    setState(() => _busyUserId = userId);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Амжилттай хадгаллаа'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _showAdjustCreditsDialog(UserModel user) async {
    final controller = TextEditingController(text: '${user.bidBalance}');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text(
          'Санал засах',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user.name.isNotEmpty ? user.name : user.email,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.mutedForeground,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Шинэ үлдэгдэл',
                suffixText: 'санал',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null) return;
              Navigator.pop(context, value);
            },
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || !mounted) return;
    await _runUserAction(
      user.uid,
      () => widget.creditsService.adminAdjustBidBalance(
        userUid: user.uid,
        newBalance: result,
      ),
    );
  }

  Future<void> _showBanDialog(UserModel user) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text(
          'Хэрэглэгч хориглох',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user.name.isNotEmpty ? user.name : user.email,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.mutedForeground,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Шалтгаан (сонголттой)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.destructive,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Хориглох'),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();

    if (confirmed != true || !mounted) return;
    await _runUserAction(
      user.uid,
      () => widget.creditsService.adminSetUserBanned(
        userUid: user.uid,
        banned: true,
        reason: reason,
      ),
    );
  }

  Future<void> _unbanUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Хориг арилгах уу?'),
        content: Text(
          user.name.isNotEmpty ? user.name : user.email,
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Арилгах'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runUserAction(
      user.uid,
      () => widget.creditsService.adminSetUserBanned(
        userUid: user.uid,
        banned: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: widget.creditsService.watchAllUsersList(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Хэрэглэгч ачаалж байна...');
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Алдаа: ${snap.error}',
                style: const TextStyle(color: AppTheme.destructive),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allUsers = snap.data ?? [];
        final users = _filterUsers(allUsers);
        final q = _searchController.text.trim().toLowerCase();

        final adminCount = allUsers.where((u) => u.isAdmin).length;
        final bannedCount = allUsers.where((u) => u.isBanned).length;
        final totalBids =
            allUsers.fold<int>(0, (sum, u) => sum + u.bidBalance);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'Нийт хэрэглэгч',
                      value: '${allUsers.length}',
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Хориглогдсон',
                      value: '$bannedCount',
                      color: AppTheme.destructive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Нийт үлдсэн санал',
                      value: formatNumber(totalBids),
                      color: const Color(0xFFA855F7),
                    ),
                  ),
                ],
              ),
            ),
            if (adminCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Админ: $adminCount',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                cursorColor: AppTheme.primary,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.foreground,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Нэр, имэйл, утсаар хайх...',
                  hintStyle: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.mutedForeground,
                  ),
                  filled: true,
                  fillColor: AppTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        q.isEmpty
                            ? 'Хэрэглэгч байхгүй'
                            : 'Хайлтын үр дүн олдсонгүй',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _UserCard(
                        user: users[i],
                        busy: _busyUserId == users[i].uid,
                        onAdjustCredits: () => _showAdjustCreditsDialog(users[i]),
                        onBan: () => _showBanDialog(users[i]),
                        onUnban: () => _unbanUser(users[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.busy,
    required this.onAdjustCredits,
    required this.onBan,
    required this.onUnban,
  });

  final UserModel user;
  final bool busy;
  final VoidCallback onAdjustCredits;
  final VoidCallback onBan;
  final VoidCallback onUnban;

  @override
  Widget build(BuildContext context) {
    final initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: user.isBanned
              ? AppTheme.destructive.withValues(alpha: 0.5)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.25),
                child: Text(
                  initial,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 16,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name.isNotEmpty ? user.name : 'Нэргүй',
                            style: AppTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (user.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'АДМИН',
                              style: AppTheme.monoStyle.copyWith(fontSize: 9),
                            ),
                          ),
                        if (user.isBanned)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.destructive.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.destructive.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'ХОРИГЛОСОН',
                              style: AppTheme.monoStyle.copyWith(
                                fontSize: 9,
                                color: AppTheme.destructive,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                    if (user.isBanned &&
                        user.bannedReason != null &&
                        user.bannedReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Шалтгаан: ${user.bannedReason}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: AppTheme.destructive,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${user.bidBalance} санал',
                          style: AppTheme.monoStyle.copyWith(fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          'Бүртгэлтэй: ${formatDate(user.createdAt)}',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 10,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!user.isAdmin) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onAdjustCredits,
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit, size: 16),
                  label: const Text('Санал засах'),
                ),
                if (user.isBanned)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onUnban,
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('Хориг арилгах'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: busy ? null : onBan,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.destructive,
                      side: BorderSide(
                        color: AppTheme.destructive.withValues(alpha: 0.5),
                      ),
                    ),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Хориглох'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
