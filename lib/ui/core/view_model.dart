import 'dart:async';

import 'package:flutter/foundation.dart';

/// Base for every screen's ViewModel: owns its stream subscriptions and
/// turns storage errors into a simple success/failure for the View.
abstract class ViewModel extends ChangeNotifier {
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _isDisposed = false;
  bool _loadFailed = false;

  bool get isDisposed => _isDisposed;

  /// True when this screen's saved data could not be read.
  bool get loadFailed => _loadFailed;

  /// Listens to [stream] until this ViewModel is disposed.
  @protected
  void listen<T>(Stream<T> stream, void Function(T value) onData) {
    _subscriptions.add(
      stream.listen(
        onData,
        onError: (Object e, StackTrace s) {
          debugPrint('$runtimeType stream error: $e');
          onStreamError(e);
        },
      ),
    );
  }

  /// Called when a watched query fails.
  @protected
  void onStreamError(Object error) {
    _loadFailed = true;
    notifyListeners();
  }

  /// Runs a save/delete. Returns false (and logs) if storage failed, so
  /// the View can tell the teacher plainly.
  @protected
  Future<bool> runCommand(Future<void> Function() command) async {
    try {
      await command();
      return true;
    } on Exception catch (e) {
      debugPrint('$runtimeType command failed: $e');
      return false;
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
