import 'dart:convert';
import 'dart:io';

/// חותמת ה-content hash הידוע של ה-DB המקומי, כפי שאומת בעדכון האחרון.
class ContentHashStamp {
  final int dbVersion;
  final String contentHash;

  /// גודל ו-mtime של קובץ ה-DB בזמן הכתיבה — לזיהוי חותמת שאינה עדכנית.
  final int fileSize;
  final int fileMtimeMs;

  const ContentHashStamp({
    required this.dbVersion,
    required this.contentHash,
    required this.fileSize,
    required this.fileMtimeMs,
  });

  Map<String, Object> toJson() => {
        'dbVersion': dbVersion,
        'contentHash': contentHash,
        'fileSize': fileSize,
        'fileMtimeMs': fileMtimeMs,
      };

  static ContentHashStamp? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final dbVersion = json['dbVersion'];
    final contentHash = json['contentHash'];
    final fileSize = json['fileSize'];
    final fileMtimeMs = json['fileMtimeMs'];
    if (dbVersion is! int ||
        contentHash is! String ||
        contentHash.isEmpty ||
        fileSize is! int ||
        fileMtimeMs is! int) {
      return null;
    }
    return ContentHashStamp(
      dbVersion: dbVersion,
      contentHash: contentHash,
      fileSize: fileSize,
      fileMtimeMs: fileMtimeMs,
    );
  }
}

/// שומר וקורא את חותמת ה-hash בקובץ צד ליד ה-DB (`<db>.contenthash.json`).
///
/// ה-hash כבר חושב ואומת בסוף כל עדכון (toContentHash) — שמירתו מאפשרת
/// ל-planner לזהות סטיית תוכן *לפני* הורדת patch, במקום להיכשל אחרי
/// ההחלה. חותמת שה-גודל/mtime שלה אינם תואמים לקובץ הנוכחי נחשבת לא
/// עדכנית ומוחזרת כ-null (הפלנר פשוט מתנהג כאילו אין מידע).
class ContentHashStampStore {
  const ContentHashStampStore();

  String stampPathFor(String dbPath) => '$dbPath.contenthash.json';

  /// קורא את החותמת של [dbPath], או null אם אינה קיימת/פגומה/לא עדכנית.
  ContentHashStamp? read(String dbPath) {
    try {
      final stampFile = File(stampPathFor(dbPath));
      if (!stampFile.existsSync()) return null;
      final stamp = ContentHashStamp.fromJson(
        jsonDecode(stampFile.readAsStringSync()),
      );
      if (stamp == null) return null;
      final db = File(dbPath);
      if (!db.existsSync()) return null;
      final stat = db.statSync();
      if (stat.size != stamp.fileSize ||
          stat.modified.millisecondsSinceEpoch != stamp.fileMtimeMs) {
        return null;
      }
      return stamp;
    } catch (_) {
      return null;
    }
  }

  /// כותב חותמת עבור [dbPath] עם הגודל/mtime הנוכחיים של הקובץ.
  /// כשל כתיבה נבלע — החותמת היא אופטימיזציה, לא דרישת נכונות.
  void write(
    String dbPath, {
    required int dbVersion,
    required String contentHash,
  }) {
    try {
      final stat = File(dbPath).statSync();
      final stamp = ContentHashStamp(
        dbVersion: dbVersion,
        contentHash: contentHash,
        fileSize: stat.size,
        fileMtimeMs: stat.modified.millisecondsSinceEpoch,
      );
      File(stampPathFor(dbPath)).writeAsStringSync(jsonEncode(stamp.toJson()));
    } catch (_) {}
  }

  /// מוחק את החותמת — נקרא כשההחלה נכשלת על סטיית תוכן והחותמת הופרכה.
  void invalidate(String dbPath) {
    try {
      final stampFile = File(stampPathFor(dbPath));
      if (stampFile.existsSync()) stampFile.deleteSync();
    } catch (_) {}
  }
}
