import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'theme/app_theme.dart';

/// Root widget of the AUDIAX app.
///
/// Pada tahap fondasi ini isinya masih placeholder: session bootstrap dan
/// routing ke landing/machines screen menyusul setelah fitur-fiturnya ada.
class AudiaxApp extends StatelessWidget {
  const AudiaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUDIAX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: Center(child: Text('AUDIAX', style: AppTextStyles.title)),
      ),
    );
  }
}
