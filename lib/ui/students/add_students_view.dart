import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:egrado/services/name_list_reader.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/scan/photo_source_sheet.dart';
import 'package:egrado/ui/students/add_students_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Adds many students at once: typed, pasted from a spreadsheet column, or
/// read from a photo of the class list.
class AddStudentsPage extends StatelessWidget {
  const AddStudentsPage(this.classId, {super.key});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddStudentsViewModel(
        classId,
        context.read<ClassRepository>(),
        photos: context.read<PhotoService>(),
        nameReader: context.read<NameListReader>(),
      ),
      child: const _AddStudentsView(),
    );
  }
}

class _AddStudentsView extends StatefulWidget {
  const _AddStudentsView();

  @override
  State<_AddStudentsView> createState() => _AddStudentsViewState();
}

class _AddStudentsViewState extends State<_AddStudentsView> {
  final _names = TextEditingController();

  @override
  void dispose() {
    _names.dispose();
    super.dispose();
  }

  Future<void> _readPhoto(BuildContext context) async {
    final viewModel = context.read<AddStudentsViewModel>();
    final source = await askPhotoSource(
      context,
      title: 'Photo of the class list',
      savedDetail: 'Photos or screenshots already on this device',
    );
    if (source == null) return;
    final outcome = await viewModel.readNamesFromPhoto(source);
    if (!context.mounted) return;
    switch (outcome) {
      case NamesFound(:final count):
        showMessage(
          context,
          'Found $count ${count == 1 ? 'name' : 'names'}. '
          'Please check them, then tap Add.',
        );
      case NoNamesFound():
        showMessage(
          context,
          'No names were found. Try again in good light, '
          'with the list filling the photo.',
        );
      case NamePhotoFailed(:final message):
        showMessage(context, message);
      case NamePhotoCancelled():
        break;
    }
  }

  /// Keeps the text box in step when the ViewModel changes the names
  /// (after reading a photo).
  void _mirror(String text) {
    if (_names.text == text) return;
    _names.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (await context.read<AddStudentsViewModel>().save()) {
      navigator.pop();
    } else if (context.mounted) {
      showMessage(context, Messages.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddStudentsViewModel>();
    _mirror(viewModel.text);
    final added = viewModel.preview;
    final dropped = viewModel.droppedCount;
    return Scaffold(
      appBar: AppBar(title: const Text('Add students')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text(
            'Take a photo of your class list, or write one name per line. '
            'Numbers are given in order.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Gap.m),
          if (viewModel.isReadingPhoto)
            const _ReadingNames()
          else
            BigActionButton(
              icon: Icons.document_scanner_outlined,
              label: 'Read names from a photo',
              detail: 'Camera, or a saved photo or screenshot',
              primary: false,
              onPressed: () => _readPhoto(context),
            ),
          const SizedBox(height: Gap.m),
          TextField(
            controller: _names,
            minLines: 6,
            maxLines: 14,
            style: const TextStyle(fontSize: 22, height: 1.5),
            textCapitalization: TextCapitalization.words,
            onChanged: viewModel.updateNames,
            decoration: const InputDecoration(
              hintText: 'Dela Cruz, Juan\nSantos, Maria\n…',
            ),
          ),
          if (added.isNotEmpty) ...[
            SectionTitle('Will be added (${added.length})'),
            for (final s in added)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.xs),
                child: Row(
                  children: [
                    NumberBadge(s.number),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Text(
                        s.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (dropped > 0) ...[
            const SizedBox(height: Gap.m),
            NoticeBanner(
              icon: Icons.warning_amber_rounded,
              text:
                  '$dropped ${dropped == 1 ? 'name' : 'names'} left out: '
                  'a class can have up to $kMaxStudentNumber students.',
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: FilledButton(
            onPressed: added.isEmpty ? null : () => _save(context),
            child: Text(
              added.isEmpty
                  ? 'Add names above'
                  : 'Add ${added.length} '
                        '${added.length == 1 ? 'student' : 'students'}',
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingNames extends StatelessWidget {
  const _ReadingNames();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Text(
              'Reading names…',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
