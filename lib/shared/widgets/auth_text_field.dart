import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Rounded, icon-led text field shared by the login/register forms — adds a
/// brand-colored focus outline and, for password fields, a visibility
/// toggle, on top of the plain filled [TextField] AUDIAX started with.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();
  late bool _obscured = widget.obscureText;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final outline = hasError
        ? AppColors.critical
        : _focused
            ? AppColors.brand
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline, width: 1.4),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.screenBackground,
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.textFaint, fontWeight: FontWeight.w500),
          errorText: widget.errorText,
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon, size: 19, color: _focused ? AppColors.brand : AppColors.textFaint),
          suffixIcon: !widget.obscureText
              ? null
              : IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.textFaint,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}
