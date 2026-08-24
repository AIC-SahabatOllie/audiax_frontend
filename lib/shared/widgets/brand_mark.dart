import 'package:flutter/material.dart';

/// The AUDIAX "A" mark (`lib/shared/icon/icon1.png` — the bare gradient
/// glyph, no background badge) used wherever the brand shows up in-app
/// (landing, login, register). [appicon.png] is the boxed variant used only
/// for the OS app icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('lib/shared/icon/icon1.png', width: size, height: size, fit: BoxFit.contain);
  }
}
