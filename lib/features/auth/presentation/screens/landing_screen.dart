import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../data/auth_repository.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// First screen an unauthenticated user sees — brand intro + the choice to
/// sign in or create an account, shown before [LoginScreen]/[RegisterScreen]
/// rather than dropping straight into a form.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.authRepository, required this.onAuthenticated});

  final AuthRepository authRepository;
  final Future<void> Function() onAuthenticated;

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(authRepository: authRepository, onAuthenticated: onAuthenticated),
      ),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authRepository: authRepository, onAuthenticated: onAuthenticated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandMark(size: 34),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUDIAX',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'LISTEN · DETECT · PREVENT',
                        style: AppTextStyles.mono(size: 8.5, color: AppColors.textFaint, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(flex: 3),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.22,
                    color: AppColors.ink,
                  ),
                  children: [
                    const TextSpan(text: 'Dengarkan mesin Anda,\nsebelum jadi '),
                    TextSpan(text: 'masalah', style: TextStyle(color: AppColors.brand)),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'AUDIAX mendengarkan suara mesin dan membandingkannya '
                'dengan kondisi sehatnya, agar pergeseran kecil ketahuan '
                'sebelum jadi kerusakan besar.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textSecondary),
              ),
              const Spacer(flex: 3),
              const _FeatureRow(
                icon: Icons.hearing_rounded,
                title: 'Dengarkan',
                body: 'Rekam suara mesin saat kondisinya sehat sebagai garis dasar.',
              ),
              const _Divider(),
              const _FeatureRow(
                icon: Icons.insights_rounded,
                title: 'Deteksi',
                body: 'Bandingkan kondisi terkini terhadap garis dasar secara otomatis.',
              ),
              const _Divider(),
              const _FeatureRow(
                icon: Icons.notifications_active_outlined,
                title: 'Cegah',
                body: 'Dapat peringatan dini sebelum kerusakan benar-benar terjadi.',
              ),
              const Spacer(flex: 4),
              AppButton(label: 'Daftar', onPressed: () => _openRegister(context)),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => _openLogin(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Sudah punya akun? ',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Masuk',
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(height: 1, color: AppColors.divider),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
