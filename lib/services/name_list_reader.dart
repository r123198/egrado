import 'dart:io';

import 'package:egrado/domain/name_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Text recognition could not run on this photo or device.
class NameReadException implements Exception {
  const NameReadException(this.reason);

  final String reason;

  @override
  String toString() => 'NameReadException: $reason';
}

/// Reads student names from a photo of a class list.
abstract interface class NameListReader {
  /// The names found, in reading order (possibly empty).
  /// Throws [NameReadException].
  Future<List<String>> readNames(Uint8List photo);
}

/// On-device text recognition: Google ML Kit on Android, Apple Vision on
/// iOS (see `MainActivity.kt` and `AppDelegate.swift`). Works offline and
/// the photo never leaves the phone.
class OnDeviceNameListReader implements NameListReader {
  const OnDeviceNameListReader();

  static const _channel = MethodChannel('egrado/text_recognition');

  @override
  Future<List<String>> readNames(Uint8List photo) async {
    // Both engines read from a file, which also lets them honour the
    // photo's rotation (EXIF).
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/class_list_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    try {
      await file.writeAsBytes(photo, flush: true);
      final lines = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'readLines',
        {'path': file.path},
      );
      return namesFromTextLines([
        for (final line in lines ?? const <Map<Object?, Object?>>[])
          ?_toLine(line),
      ]);
    } on PlatformException catch (e) {
      debugPrint('Text recognition failed: ${e.code} ${e.message}');
      throw NameReadException(e.message ?? e.code);
    } on MissingPluginException {
      throw const NameReadException('Text recognition is not available.');
    } on FileSystemException catch (e) {
      throw NameReadException(e.message);
    } finally {
      if (file.existsSync()) await file.delete();
    }
  }

  static TextLineBox? _toLine(Map<Object?, Object?> line) {
    if (line case {
      'text': final String text,
      'left': final num left,
      'top': final num top,
      'right': final num right,
      'bottom': final num bottom,
    }) {
      return TextLineBox(
        text,
        left: left.toDouble(),
        top: top.toDouble(),
        right: right.toDouble(),
        bottom: bottom.toDouble(),
      );
    }
    return null;
  }
}
