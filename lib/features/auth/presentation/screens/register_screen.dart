import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/auth_scaffold_pieces.dart';
import '../../../../shared/widgets/auth_text_field.dart';
import '../../data/auth_repository.dart';

/// `POST /api/users` (`docs/api_contract.md` §3). The endpoint doesn't
/// return a session token, so on success this immediately logs in with the
/// same credentials rather than sending the user back to a manual login.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authRepository, required this.onAuthenticated});

  final AuthRepository authRepository;
  final Future<void> Function() onAuthenticated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _banner;
  Map<String, String>? _fieldErrors;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 8 &&
      !_submitting;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _banner = null;
      _fieldErrors = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      await widget.authRepository.register(email: email, name: _nameController.text.trim(), password: password);
      await widget.authRepository.login(email: email, password: password);
      await widget.onAuthenticated();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.isValidation ? e.fields : null;
        _banner = e.isConflict ? 'Email sudah terdaftar.' : e.displayMessage;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const AuthBrandMark(title: 'AUDIAX', subtitle: 'Pemantauan kondisi mesin'),
              const SizedBox(height: 26),
              const Text('Buat akun', style: AppTextStyles.title),
              const SizedBox(height: 8),
              const Text(
                'Daftar untuk mulai mengkalibrasi dan memantau mesin.',
                style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              if (_banner != null) ...[
                AuthErrorBanner(text: _banner!),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('NAMA'),
                    const SizedBox(height: 9),
                    AuthTextField(
                      controller: _nameController,
                      hint: 'mis. Budi Santoso',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      errorText: _fieldErrors?['name'],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('EMAIL'),
                    const SizedBox(height: 9),
                    AuthTextField(
                      controller: _emailController,
                      hint: 'operator@contoh.id',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _fieldErrors?['email'],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('SANDI'),
                    const SizedBox(height: 9),
                    AuthTextField(
                      controller: _passwordController,
                      hint: 'minimal 8 karakter',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      errorText: _fieldErrors?['password'],
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Daftar',
                enabled: _canSubmit,
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
