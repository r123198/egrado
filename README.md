# eGrado

Check bubble answer sheets with a phone camera. The app reads every answer,
finds the student, works out the score, and saves it. Teachers never type a
grade.

Runs on Android phones, iPhones, and tablets. Everything is stored on the
device and can be exported to Excel.

## App flow

1. **Welcome tour** (first launch only): four short pages with Skip and
   Next. You can see it again from Account → *How eGrado works*.
2. **Sign in** with Google, or with email and password (create an account,
   reset a forgotten password). Errors are written in plain language.
3. **Bottom tabs**: **Tests** (every test, newest first), **Classes**, and
   **Account**. Each tab keeps its own history, so the tab bar stays
   visible while you move around inside it.
4. **Inside a test**, a bottom action bar works like ZipGrade's:
   **Key · Print · Scan · Export · Edit**, with Scan raised in the middle.
   Buttons never go grey. If one can't act yet, it says why and offers the
   next step (for example, Scan before the key exists opens the key).

Each signed-in teacher gets their own database file on the device, so
teachers who share a tablet never see each other's classes.

## How a teacher uses it

1. **Add a class** and add the students: tap **Read names from a photo** and
   photograph the printed class list (or pick a saved photo or screenshot),
   or type/paste one name per line. The names land in the box to be checked
   before saving. Each student gets a number.
2. **New test.** Choose how many questions (up to 60) and how many choices
   (A–C, A–D or A–E).
3. **Set the answer key.** Tap the letters, or shade one sheet with the right
   answers and scan it.
4. **Print answer sheets.** Print *one per student* (name printed and number
   already shaded, so it can't be shaded wrong) or blank sheets.
5. **Check papers.** Photograph each sheet. The app shows the student, the
   score, and every answer, with unclear marks in yellow. Tap **Save score**,
   and the camera opens for the next paper.
6. **Export.** This makes a spreadsheet (CSV, opens in Excel or Google Sheets)
   with each student's score, percent, and every answer.

Fixing the answer key later re-grades every saved paper automatically.

## Grades and the E-Class Record

Each test can **count toward** a term (or quarter) as Written Work, a
Performance Task, or an exam (Summative Test 1, Summative Test 2, Term Exam,
or the DO 8 Quarterly Assessment). Set it when you create or edit a test.

- **Grades** (from the class screen) shows each learner's term grade, worked
  out with the DepEd rules: DO 015, s. 2026 (three terms, adjusted
  transmutation table for SY 2026-2027, zero-based from SY 2027-2028), the
  Grade 12 rule for SY 2026-2027 (DO 8 weights with the adjusted table), or
  DO 8, s. 2015 for schools still on quarters. Pick the subject once per
  class so the app knows the weights.
- **Fill my E-Class Record** opens the teacher's own class record (.xlsx),
  matches learners by name, and writes each test's Highest Possible Score and
  raw scores into the right term and column. The class record's own formulas
  then compute PS, WS and the term grade. Filling again updates the same
  columns; columns the teacher typed into by hand are never overwritten.

`lib/class_record/` finds the layout by reading the file (the "HIGHEST
POSSIBLE SCORE" row, the WW/PT/EX headers, and the learner rows), so the
Grades 2-10 three-term, Strengthened SHS, and DO 8 quarterly templates all
work. It edits only the cells it fills and asks Excel to recalculate on open.
`test/fixtures/ecr/` holds the real DepEd templates the tests run against.

## Design choices for older teachers

- **Atkinson Hyperlegible** typeface (Braille Institute), so I/l/1 and O/0
  never look alike.
- 20 pt body text and 64 px-tall buttons. Text-on-background contrast is 7:1
  or higher (WCAG AAA).
- Colour never carries meaning alone. Right, wrong, and "please check" each
  have their own icon.
- Respects the phone's text-size setting (up to 1.6×). Tests check that no
  screen overflows at 1.6× on a 360 px phone.
- One clear main action per screen, plain words, and a confirmation before
  anything is deleted.

## How the reading works

`lib/omr/` is plain Dart, and the same file (`sheet_layout.dart`) drives both
the printed PDF and the reader:

1. Shrink the photo and binarize it against each pixel's neighbourhood, so
   shadows and uneven light don't matter.
2. Find the four solid corner squares, then fit a perspective transform from
   page millimetres to photo pixels. An extra square next to the top-left
   corner tells which way up the page is, so sideways and upside-down photos
   still work.
3. Measure how much of the centre of each bubble is dark. One filled bubble
   counts as the answer. Blanks, double marks, and half-erased marks are
   flagged for the teacher instead of being guessed silently.

## Reading class lists from photos

Text recognition runs on the phone, offline, and the photo is never
uploaded: Google ML Kit on Android (`MainActivity.kt`, bundled model) and
Apple Vision on iOS (`AppDelegate.swift`), behind the
`egrado/text_recognition` channel. (The `google_mlkit_text_recognition`
plugin can't be used on iOS here: its Swift package needs an older
`gtm-session-fetcher` than Firebase does.)

`lib/domain/name_list.dart` turns the recognised lines into names. It
joins words on the same row, drops row numbers, scores and headings
("NAMES", "BOYS"), and reads lists printed in columns (boys | girls) one
column at a time.

## Architecture (MVVM + Provider + Drift)

```
lib/
├── domain/        Pure Dart models and rules (scoring, numbering students)
├── data/
│   ├── database/      Drift tables and AppDatabase (offline SQLite)
│   └── repositories/  Interfaces + Drift implementations, exposed as streams
├── services/      Device features: camera, sheet reader, printing, export
├── omr/ sheet/ export/   Answer-sheet reader, printable PDF, CSV builder
├── data/auth/     AuthRepository + Firebase implementation
├── ui/<feature>/  One folder per screen:
│   ├── *_view_model.dart   ChangeNotifier: state and commands, no widgets
│   └── *_view.dart         Widgets only: watches the ViewModel, navigates
└── app_providers.dart   Composition root: every repository and service
```

- **Model**: `domain/` plus repositories. Screens never touch the database
  directly.
- **ViewModel**: each extends `ui/core/view_model.dart`. It subscribes to
  repository streams, so screens update live when data changes. Saves return
  `true` or `false`, and the View shows a plain message when a save fails.
- **View**: each `…Page` creates its ViewModel with `ChangeNotifierProvider`
  and reads it with `context.watch`. Dialogs, navigation, and snackbars live
  in the View.
- **Database**: deleting a class cascades to its students, tests, and scores
  through foreign keys. A score is keyed by student number, so it survives
  the student being removed from the class list.

## Firebase setup (project `egrado-dddb4`)

Already done: the Android and iOS apps `com.maalam.egrado` are registered,
`lib/firebase_options.dart` and both platform config files are generated,
and this Mac's **debug** SHA-1 and SHA-256 fingerprints are added to the
Android app.

Google sign-in is set up: the Google and Email providers are on, the config
files include the Google OAuth clients, and iOS has the `REVERSED_CLIENT_ID`
URL scheme and `GIDClientID` in `ios/Runner/Info.plist`.

**Before releasing on Android**, add the release signing fingerprints in
Firebase → Project settings → the `com.maalam.egrado` Android app → Add
fingerprint:

- the upload keystore's SHA-1 and SHA-256 (`keytool -list -v -keystore
  <file> -alias upload`), and
- if you use Play App Signing, the **app signing key** SHA-1 and SHA-256
  from Play Console → Test and release → App integrity.

Then download `google-services.json` again, or re-run `flutterfire
configure`.

## Icons and splash

The source artwork is in `assets/icons/`. After changing it, regenerate:

```bash
fvm dart run flutter_launcher_icons
fvm dart run flutter_native_splash:create
```

The Android adaptive icon uses `assets/icons/launcher_foreground.png`,
sized to stay inside the circular mask.

## Development

The Firebase config files hold API keys and are not in the repo
(`lib/firebase_options.dart`, `android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist`). Create them once per machine:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=egrado-dddb4 --platforms=android,ios \
  --android-package-name=com.maalam.egrado --ios-bundle-id=com.maalam.egrado
```

Then:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # after editing tables
fvm flutter test                                                # unit + widget
fvm flutter test integration_test -d <device-id>                # on a device
fvm flutter run
```

- Unit tests run the repositories and ViewModels against an in-memory SQLite
  database.
- Widget tests pump real screens on that database, with the camera, printer,
  and share sheet faked.
- The integration test runs on a device: it saves a class, closes the app,
  and checks that the class is still there when the app reopens.
- `test/fixtures/` holds simulated phone photos of sheets printed from the
  real PDF generator.
