import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The bar along the bottom of a test, ZipGrade-style:
/// Key · Print · **Scan** · Export · Edit. Every action is always one tap
/// away in the same place, with Scan — the main job — raised in the middle.
class TestActionBar extends StatelessWidget {
  const TestActionBar({
    super.key,
    required this.scanReady,
    required this.onKey,
    required this.onPrint,
    required this.onScan,
    required this.onExport,
    required this.onEdit,
  });

  /// False until the answer key is complete; Scan then looks quieter and
  /// explains what to do instead of doing nothing.
  final bool scanReady;
  final VoidCallback onKey;
  final VoidCallback onPrint;
  final VoidCallback onScan;

  /// Gets the button's own context so the iPad share popover can point at it.
  final void Function(BuildContext buttonContext) onExport;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BarButton(
                icon: Icons.vpn_key_outlined,
                label: 'Key',
                onTap: onKey,
              ),
              _BarButton(
                icon: Icons.print_outlined,
                label: 'Print',
                onTap: onPrint,
              ),
              _ScanButton(ready: scanReady, onTap: onScan),
              Builder(
                builder: (buttonContext) => _BarButton(
                  icon: Icons.ios_share,
                  label: 'Export',
                  onTap: () => onExport(buttonContext),
                ),
              ),
              _BarButton(icon: Icons.tune, label: 'Edit', onTap: onEdit),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kTouchHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: AppColors.ink),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.ready, required this.onTap});

  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.primary : AppColors.inkMuted;
    return Expanded(
      flex: 2,
      child: Semantics(
        button: true,
        label: ready ? 'Scan papers' : 'Scan papers, needs the answer key',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(18),
            elevation: ready ? 3 : 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 34,
                      color: Colors.white,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
