import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/submit_service.dart';
import '../theme/app_theme.dart';
import 'success_screen.dart';

/// Дэлгэц 1: овог нэр + portrait зураг → илгээх.
class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key, required this.submitService});

  final SubmitService submitService;

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _portrait;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPortrait(ImageSource source) async {
    setState(() => _error = null);
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.front,
      );
      if (x == null) return;
      setState(() => _portrait = File(x.path));
    } catch (e) {
      setState(() => _error = 'Зураг сонгоход алдаа гарлаа.');
    }
  }

  void _showPickSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text('Камер', style: GoogleFonts.outfit()),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPortrait(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('Галерей', style: GoogleFonts.outfit()),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPortrait(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    if (_portrait == null) {
      setState(() => _error = 'Цээж (portrait) зураг оруулна уу.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final submission = await widget.submitService.submit(
        lastName: _lastNameCtrl.text,
        firstName: _firstNameCtrl.text,
        imageFile: _portrait!,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SuccessScreen(submission: submission),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Илгээхэд алдаа гарлаа. Дахин оролдоно уу.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              AppTheme.backgroundDeep,
              Color(0xFFC8D9D4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 400 ? 20 : 28,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Portrait',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Овог нэрээ бичээд цээж зургаа оруулаад илгээнэ үү.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          height: 1.45,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _PortraitPicker(
                        file: _portrait,
                        onTap: _submitting ? null : _showPickSheet,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _lastNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Овог',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Овог оруулна уу';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _firstNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        enabled: !_submitting,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Нэр',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Нэр оруулна уу';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppTheme.danger,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Илгээх'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Зөвхөн овог, нэр, зураг хадгалагдана.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortraitPicker extends StatelessWidget {
  const _PortraitPicker({required this.file, required this.onTap});

  final File? file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: file == null ? AppTheme.border : AppTheme.accent,
            width: file == null ? 1 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file!, fit: BoxFit.cover),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Material(
                      color: AppTheme.foreground.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Солих',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 48,
                    color: AppTheme.muted.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Цээж зураг оруулах',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Камер эсвэл галерей',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
