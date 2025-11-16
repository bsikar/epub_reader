import 'package:flutter/material.dart';

/// A customizable dialog widget that follows the app's design system.
///
/// Provides several dialog types:
/// - [CustomDialog.alert] - Simple alert dialog with title, message, and actions
/// - [CustomDialog.confirm] - Confirmation dialog with cancel and confirm buttons
/// - [CustomDialog.destructive] - Destructive action dialog with warning styling
/// - [CustomDialog.custom] - Custom dialog with full control over content
class CustomDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final List<DialogAction>? actions;
  final DialogType type;
  final IconData? icon;
  final bool barrierDismissible;

  const CustomDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.actions,
    this.type = DialogType.alert,
    this.icon,
    this.barrierDismissible = true,
  });

  const CustomDialog.alert({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions,
    this.icon,
    this.barrierDismissible = true,
  }) : type = DialogType.alert;

  const CustomDialog.confirm({
    super.key,
    required this.title,
    this.message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    this.icon,
    this.barrierDismissible = true,
  })  : type = DialogType.confirm,
        content = null,
        actions = null;

  const CustomDialog.destructive({
    super.key,
    required this.title,
    this.message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    this.barrierDismissible = true,
  })  : type = DialogType.destructive,
        content = null,
        actions = null,
        icon = Icons.warning_amber_rounded;

  const CustomDialog.custom({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.barrierDismissible = true,
  })  : type = DialogType.custom,
        message = null,
        icon = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: title != null
          ? Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: _getIconColor(theme),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : null,
      content: content ??
          (message != null
              ? Text(
                  message!,
                  style: theme.textTheme.bodyMedium,
                )
              : null),
      actions: _buildActions(context),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  Color _getIconColor(ThemeData theme) {
    switch (type) {
      case DialogType.destructive:
        return theme.colorScheme.error;
      case DialogType.alert:
      case DialogType.confirm:
      case DialogType.custom:
        return theme.colorScheme.primary;
    }
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions != null && actions!.isNotEmpty) {
      return actions!.map((action) => _buildActionButton(context, action)).toList();
    }

    // Default actions based on type
    switch (type) {
      case DialogType.alert:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ];

      case DialogType.confirm:
      case DialogType.destructive:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: type == DialogType.destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(type == DialogType.destructive ? 'Delete' : 'Confirm'),
          ),
        ];

      case DialogType.custom:
        return null;
    }
  }

  Widget _buildActionButton(BuildContext context, DialogAction action) {
    final theme = Theme.of(context);

    switch (action.style) {
      case DialogActionStyle.filled:
        return FilledButton(
          onPressed: action.onPressed,
          style: action.isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                )
              : null,
          child: Text(action.label),
        );

      case DialogActionStyle.outlined:
        return OutlinedButton(
          onPressed: action.onPressed,
          child: Text(action.label),
        );

      case DialogActionStyle.text:
        return TextButton(
          onPressed: action.onPressed,
          style: action.isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                )
              : null,
          child: Text(action.label),
        );
    }
  }

  /// Helper method to show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required CustomDialog dialog,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dialog.barrierDismissible,
      builder: (context) => dialog,
    );
  }

  /// Helper method to show a simple alert
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
  }) {
    return show(
      context: context,
      dialog: CustomDialog.alert(
        title: title,
        message: message,
        icon: icon,
      ),
    );
  }

  /// Helper method to show a confirmation dialog
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData? icon,
  }) async {
    final result = await show<bool>(
      context: context,
      dialog: CustomDialog(
        type: DialogType.confirm,
        title: title,
        message: message,
        icon: icon,
        actions: [
          DialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
            style: DialogActionStyle.text,
          ),
          DialogAction(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
            style: DialogActionStyle.filled,
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Helper method to show a destructive action dialog
  static Future<bool> showDestructive({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: title,
        message: message,
        onConfirm: () {},
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }
}

enum DialogType {
  alert,
  confirm,
  destructive,
  custom,
}

class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final DialogActionStyle style;
  final bool isDestructive;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.style = DialogActionStyle.text,
    this.isDestructive = false,
  });
}

enum DialogActionStyle {
  filled,
  outlined,
  text,
}
