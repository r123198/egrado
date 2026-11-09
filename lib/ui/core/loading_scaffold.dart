import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';

/// Shown for the moment it takes a screen's data to load.
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Shown when a screen's saved data could not be read.
class LoadErrorScaffold extends StatelessWidget {
  const LoadErrorScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const EmptyState(
        icon: Icons.sd_card_alert_outlined,
        title: 'Your saved grades could not be opened',
        message:
            'Nothing has been deleted. Please close eGrado and open it '
            'again. If this keeps happening, restart the phone.',
      ),
    );
  }
}
