import 'package:flutter/material.dart';

/// Opens [page] over the whole app, covering the bottom tab bar. Used for
/// everything inside a test, which has its own bottom action bar.
Future<T?> openFullScreen<T>(BuildContext context, Widget page) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<T>(builder: (_) => page));

/// Opens [page] inside the current tab, keeping the tab bar visible.
Future<T?> openInTab<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<T>(builder: (_) => page));
