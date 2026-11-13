import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/shared_pdf_inbox.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.nullstate.nestprep/shared_pdf');
  const inbox = ChannelSharedPdfInbox();
  late Directory folder;
  late List<Object?> asked;

  void answer(Map<String, String>? filed) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        asked.add(call.arguments);
        return filed;
      });

  setUp(() {
    folder = Directory.systemTemp.createTempSync('shared_pdf');
    asked = [];
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    folder.deleteSync(recursive: true);
  });

  test('reads the filed PDF by its token, then deletes the copy', () async {
    final file = File('${folder.path}/taken.pdf')..writeAsBytesSync([1, 2, 3]);
    answer({'path': file.path, 'name': 'DOUGH IT EASY (1).pdf'});

    final pdf = await inbox.take('4F1C2D3E-1111-2222');

    expect(asked, [
      {'token': '4F1C2D3E-1111-2222'},
    ]);
    expect(pdf?.bytes, [1, 2, 3]);
    expect(pdf?.name, 'DOUGH IT EASY');
    expect(file.existsSync(), isFalse);
  });

  test('a share the phone no longer has is null', () async {
    answer(null);
    expect(await inbox.take('4F1C2D3E-1111-2222'), isNull);
    answer({'path': '${folder.path}/gone.pdf', 'name': 'Gone.pdf'});
    expect(await inbox.take('4F1C2D3E-1111-2222'), isNull);
  });

  test('one too big to read is refused, and its copy deleted', () async {
    answer({'name': 'Huge.pdf', 'tooLarge': 'true'});
    await expectLater(
      inbox.take('4F1C2D3E-1111-2222'),
      throwsA(const OwnRecipeFailure(OwnRecipeProblem.documentTooLarge)),
    );
    final file = File('${folder.path}/huge.pdf');
    file.openSync(mode: FileMode.write)
      ..setPositionSync(100 * 1024 * 1024)
      ..writeByteSync(0)
      ..closeSync();
    answer({'path': file.path, 'name': 'Huge.pdf'});
    await expectLater(
      inbox.take('4F1C2D3E-1111-2222'),
      throwsA(const OwnRecipeFailure(OwnRecipeProblem.documentTooLarge)),
    );
    expect(file.existsSync(), isFalse);
  });
}
