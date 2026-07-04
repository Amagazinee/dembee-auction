import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/auction_categories.dart';
import '../../core/errors/app_exception.dart';
import '../../services/auction_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// Figma — Шинэ дуудлага нэмэх (тусдаа дэлгэц)
class AdminAddAuctionScreen extends StatefulWidget {
  const AdminAddAuctionScreen({
    super.key,
    this.auctionService,
    this.storageService,
  });

  final AuctionService? auctionService;
  final StorageService? storageService;

  @override
  State<AdminAddAuctionScreen> createState() => _AdminAddAuctionScreenState();
}

class _AdminAddAuctionScreenState extends State<AdminAddAuctionScreen> {
  late final AuctionService _auctionService =
      widget.auctionService ?? AuctionService();
  late final StorageService _storageService =
      widget.storageService ?? StorageService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String _category = AuctionCategories.all.first;
  int _bidIncrement = 2;
  File? _imageFile;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.length();
    if (bytes > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Зураг 5MB-аас их байна'),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
      return;
    }

    setState(() => _imageFile = File(file.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final auctionId = _auctionService.createAuctionId();
      String? imageUrl;

      if (_imageFile != null) {
        imageUrl = await _storageService.uploadAuctionImage(
          auctionId: auctionId,
          file: _imageFile!,
        );
      }

      await _auctionService.createAuction(
        docId: auctionId,
        title: _titleController.text,
        category: _category,
        description: _descriptionController.text,
        bidIncrement: _bidIncrement,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Дуудлага амжилттай нэмэгдлээ'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      context.pop();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Шинэ дуудлага нэмэх',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
                child: Text(
                  'Зөвхөн админ нэмэх эрхтэй · Бүх дуудлага 1-р үеэс эхэлнэ',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('БАРААНЫ ЗУРАГ'),
              const SizedBox(height: 8),
              Text(
                'JPEG эсвэл PNG зураг оруулах',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            _imageFile!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 32,
                              color: AppTheme.mutedForeground,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Зураг сонгох',
                              style: AppTheme.bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPEG, PNG · Хамгийн ихдээ 5MB',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 11,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('БАРААНЫ МЭДЭЭЛЭЛ'),
              const SizedBox(height: 12),
              _FieldLabel('Бараа нэр *'),
              TextFormField(
                controller: _titleController,
                style: AppTheme.bodyStyle,
                decoration: _inputDecoration('iPhone 15 Pro Max 256GB'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Барааны нэр оруулна уу'
                    : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Ангилал'),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: AppTheme.card,
                style: AppTheme.bodyStyle,
                decoration: _inputDecoration(null),
                items: [
                  for (final c in AuctionCategories.all)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              _FieldLabel('Барааны танилцуулга'),
              TextFormField(
                controller: _descriptionController,
                style: AppTheme.bodyStyle,
                maxLines: 5,
                maxLength: 1000,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  'Барааны дэлгэрэнгүй мэдээлэл, онцлог шинж чанарууд, '
                  'нөхцөл байдлыг энд бичнэ үү...',
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_descriptionController.text.length} тэмдэгт',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('ҮНИЙН ТОХИРГОО'),
              const SizedBox(height: 12),
              _FieldLabel('Санал бүрт нэмэх дүн (₮)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final amount in AuctionBidIncrements.options)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: amount != AuctionBidIncrements.options.last
                              ? 8
                              : 0,
                        ),
                        child: _IncrementOption(
                          amount: amount,
                          selected: _bidIncrement == amount,
                          onTap: () => setState(() => _bidIncrement = amount),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Санал бүрт үнэ ₮$_bidIncrement-аар нэмэгдэнэ',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryForeground,
                        ),
                      )
                    : const Icon(Icons.gavel, size: 18),
                label: Text(
                  _submitting ? 'Нэмж байна...' : 'Дуудлага худалдаанд нэмэх',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.bodyStyle.copyWith(
        fontSize: 11,
        letterSpacing: 1.2,
        color: AppTheme.mutedForeground,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _IncrementOption extends StatelessWidget {
  const _IncrementOption({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '₮$amount',
          style: AppTheme.monoStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? AppTheme.primary : AppTheme.foreground,
          ),
        ),
      ),
    );
  }
}
