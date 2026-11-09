import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// The phone could not open or save the file.
class ClassRecordFileException implements Exception {
  const ClassRecordFileException();
}

@immutable
class PickedWorkbook {
  const PickedWorkbook(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Opening the teacher's E-Class Record and handing back the filled copy.
abstract interface class ClassRecordFileService {
  /// Lets the teacher choose an .xlsx file. Null if they cancel.
  /// Throws [ClassRecordFileException].
  Future<PickedWorkbook?> pickWorkbook();

  /// Asks where to save the file. False if the teacher cancels.
  /// Throws [ClassRecordFileException].
  Future<bool> saveWorkbook(String fileName, Uint8List bytes);

  /// Opens the share menu (Drive, Messenger, email, Excel…).
  /// Throws [ClassRecordFileException].
  Future<void> shareWorkbook(String fileName, Uint8List bytes, {Rect? origin});
}

class DeviceClassRecordFileService implements ClassRecordFileService {
  const DeviceClassRecordFileService();

  @override
  Future<PickedWorkbook?> pickWorkbook() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose your E-Class Record',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (file == null) return null;
      final picked = PickedWorkbook(file.name, await file.readAsBytes());
      // The picker may keep a copy (learner names, grades) in its cache.
      await FilePicker.clearTemporaryFiles();
      return picked;
    } on PlatformException {
      throw const ClassRecordFileException();
    } on FileSystemException {
      throw const ClassRecordFileException();
    }
  }

  @override
  Future<bool> saveWorkbook(String fileName, Uint8List bytes) async {
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save the filled class record',
        fileName: fileName,
        bytes: bytes,
        mimeType: _xlsxMime,
      );
      return uri != null;
    } on PlatformException {
      throw const ClassRecordFileException();
    }
  }

  @override
  Future<void> shareWorkbook(
    String fileName,
    Uint8List bytes, {
    Rect? origin,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: _xlsxMime)],
            subject: fileName,
            sharePositionOrigin: origin,
          ),
        );
      } finally {
        // Learner names and grades shouldn't linger in the cache.
        if (await file.exists()) await file.delete();
      }
    } on FileSystemException {
      throw const ClassRecordFileException();
    } on PlatformException {
      throw const ClassRecordFileException();
    }
  }
}
