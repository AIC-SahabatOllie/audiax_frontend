import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/auth_scaffold_pieces.dart';
import '../../../../shared/widgets/auth_text_field.dart';
import '../../data/auth_repository.dart';
import 'register_screen.dart';

/// `POST /api/users/_login` (`docs/api_contract.md` §3).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository, required this.onAuthenticated});

  final AuthRepository authRepository;
  final VoidCallback onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _banner;
  Map<String, String>? _fieldErrors;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty && !_submitting;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _banner = null;
      _fieldErrors = null;
    });
    try {
      await widget.authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onAuthenticated();
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.isValidation ? e.fields : null;
        _banner = e.isUnauthorized ? 'Email atau sandi tidak valid.' : e.displayMessage;
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
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
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
              const SizedBox(height: 30),
              const Text(
                'Selamat datang kembali',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk memantau kondisi mesin Anda.',
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
                      hint: '••••••••',
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
                label: 'Masuk',
                enabled: _canSubmit,
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _submitting
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(
                              authRepository: widget.authRepository,
                              onAuthenticated: widget.onAuthenticated,
                            ),
                          ),
                        ),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Daftar',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.brand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
