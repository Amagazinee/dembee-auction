import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Профайл засах — нэр, утас
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _authService.getCurrentUserProfile();
    if (!mounted) return;

    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _email = profile.email;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _authService.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профайл шинэчлэгдлээ'),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubPageScaffold(
      title: 'Профайл засах',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: AppTheme.bodyStyle,
                      decoration: const InputDecoration(
                        labelText: 'Нэр',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Нэр оруулна уу' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      style: AppTheme.bodyStyle,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Утас',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Утасны дугаар оруулна уу'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _email,
                      readOnly: true,
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'И-мэйл (өөрчлөхгүй)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(_saving ? 'Хадгалж байна...' : 'Хадгалах'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
