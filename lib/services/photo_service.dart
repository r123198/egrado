import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// The camera or photo library could not be used.
class PhotoUnavailableException implements Exception {
  const PhotoUnavailableException({required this.permissionDenied});

  final bool permissionDenied;
}

abstract interface class PhotoService {
  /// The photo's bytes, or null if the teacher backed out.
  /// Throws [PhotoUnavailableException].
  Future<Uint8List?> take(PhotoSource source);
}

class ImagePickerPhotoService implements PhotoService {
  ImagePickerPhotoService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  /// Large enough for reliable reading, small enough to keep phones fast.
  static const double _maxPhotoSide = 2400;

  final ImagePicker _picker;

  @override
  Future<Uint8List?> take(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxPhotoSide,
        maxHeight: _maxPhotoSide,
        imageQuality: 90,
      );
      return await file?.readAsBytes();
    } on PlatformException catch (e) {
      throw PhotoUnavailableException(
        permissionDenied: e.code.contains('denied'),
      );
    }
  }
}
