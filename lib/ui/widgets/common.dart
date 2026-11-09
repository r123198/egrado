import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// White card on the paper background with a clear edge.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
    this.padding = const EdgeInsets.all(Gap.m),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: borderColor, width: 1.5),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A full-width button with an icon, a label, and an optional second line
/// explaining what it does.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.detail,
    this.primary = true,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(icon, size: 34),
        const SizedBox(width: Gap.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (detail case final detail?)
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 30),
      ],
    );
    const padding = EdgeInsets.symmetric(horizontal: Gap.m, vertical: 16);
    return SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(padding: padding),
              child: content,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(padding: padding),
              child: content,
            ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.l, bottom: Gap.s),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Friendly "nothing here yet" message that says what to do next.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xl, horizontal: Gap.m),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppColors.inkMuted),
          const SizedBox(height: Gap.m),
          Text(title, style: theme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: Gap.s),
          Text(
            message,
            style: theme.bodyLarge?.copyWith(color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Round badge with a student number, used in every list of students.
class NumberBadge extends StatelessWidget {
  const NumberBadge(this.number, {super.key, this.muted = false});

  final int number;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: muted ? AppColors.paper : AppColors.primarySoft,
        border: Border.all(
          color: muted ? AppColors.line : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: muted ? AppColors.inkMuted : AppColors.primary,
        ),
      ),
    );
  }
}

/// Coloured strip with an icon, used for warnings and confirmations so
/// meaning never depends on colour alone.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppColors.check,
    this.background = AppColors.checkSoft,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks before anything that deletes or replaces data.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.wrong)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Single-field text dialog (class name, student name…).
Future<String?> askForText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      label: label,
      initial: initial,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String initial;
  final String confirmLabel;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 22),
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
