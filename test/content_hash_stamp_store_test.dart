import 'dart:io';

import 'package:test/test.dart';
import 'package:seforim_library_updater/src/services/content_hash_stamp_store.dart';

void main() {
  late Directory tempDir;
  late String dbPath;
  const store = ContentHashStampStore();

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('stamp_test');
    dbPath = '${tempDir.path}${Platform.pathSeparator}seforim.db';
    File(dbPath).writeAsStringSync('fake-db-content');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('ContentHashStampStore', () {
    test('roundtrip: write ואז read מחזיר את החותמת', () {
      store.write(dbPath, dbVersion: 18, contentHash: 'abc123');
      final stamp = store.read(dbPath);
      expect(stamp, isNotNull);
      expect(stamp!.dbVersion, 18);
      expect(stamp.contentHash, 'abc123');
    });

    test('אין קובץ חותמת → null', () {
      expect(store.read(dbPath), isNull);
    });

    test('ה-DB השתנה אחרי הכתיבה (גודל שונה) → חותמת לא עדכנית → null', () {
      store.write(dbPath, dbVersion: 18, contentHash: 'abc123');
      File(dbPath).writeAsStringSync('fake-db-content-modified');
      expect(store.read(dbPath), isNull);
    });

    test('קובץ ה-DB נמחק → null', () {
      store.write(dbPath, dbVersion: 18, contentHash: 'abc123');
      File(dbPath).deleteSync();
      expect(store.read(dbPath), isNull);
    });

    test('JSON פגום → null בלי חריגה', () {
      File(store.stampPathFor(dbPath)).writeAsStringSync('not-json{');
      expect(store.read(dbPath), isNull);
    });

    test('JSON חסר שדות → null', () {
      File(store.stampPathFor(dbPath))
          .writeAsStringSync('{"dbVersion": 18, "contentHash": "abc"}');
      expect(store.read(dbPath), isNull);
    });

    test('invalidate מוחק את החותמת', () {
      store.write(dbPath, dbVersion: 18, contentHash: 'abc123');
      store.invalidate(dbPath);
      expect(store.read(dbPath), isNull);
      expect(File(store.stampPathFor(dbPath)).existsSync(), isFalse);
    });

    test('write על DB שאינו קיים נבלע בשקט', () {
      final missing = '${tempDir.path}${Platform.pathSeparator}missing.db';
      expect(
        () => store.write(missing, dbVersion: 1, contentHash: 'x'),
        returnsNormally,
      );
      expect(store.read(missing), isNull);
    });
  });
}
