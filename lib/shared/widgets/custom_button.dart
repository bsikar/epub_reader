import 'package:flutter/material.dart';

/// A customizable button widget that follows the app's design system.
///
/// Provides three button types:
/// - [CustomButton.primary] - Primary action button with filled background
/// - [CustomButton.secondary] - Secondary action button with outlined style
/// - [CustomButton.text] - Text-only button for tertiary actions
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonType type;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = ButtonType.primary,
    this.width,
    this.padding,
  });

  const CustomButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : type = ButtonType.primary;

  const CustomButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : type = ButtonType.secondary;

  const CustomButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : type = ButtonType.text;

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final buttonStyle = _getButtonStyle(context);
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: content,
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: content,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: content,
        );
        break;
    }

    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final basePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return ButtonStyle(
      padding: WidgetStateProperty.all(basePadding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
}
