import 'package:egrado/services/photo_service.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';

/// Asks whether to use the camera or a saved photo.
Future<PhotoSource?> askPhotoSource(
  BuildContext context, {
  String title = 'Get the answer sheet',
  String savedDetail = 'Photos or scans already on this device',
}) => showModalBottomSheet<PhotoSource>(
  context: context,
  builder: (_) => _SourceSheet(title: title, savedDetail: savedDetail),
);

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.title, required this.savedDetail});

  final String title;
  final String savedDetail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Gap.m),
            BigActionButton(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              detail: 'Use the camera now',
              onPressed: () => Navigator.pop(context, PhotoSource.camera),
            ),
            const SizedBox(height: Gap.s),
            BigActionButton(
              icon: Icons.photo_library_outlined,
              label: 'Choose a saved photo',
              detail: savedDetail,
              primary: false,
              onPressed: () => Navigator.pop(context, PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain-language tips shown while waiting and after a failed read.
class PhotoTips extends StatelessWidget {
  const PhotoTips({super.key});

  static const _tips = [
    'Lay the sheet flat on a table.',
    'Make sure all four black corner squares are in the photo.',
    'Use good light and avoid strong shadows.',
    'Hold the phone straight above the sheet.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in _tips)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
