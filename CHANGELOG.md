# Changelog

## 0.2.0

זיהוי סטיית תוכן של ה-DB המקומי ו-fallback להורדה מלאה.

- `PatchApplyException.isContentMismatch` — מבחין כשל hash (from/to) מכשלי
  preflight אחרים, כדי שהצרכן יציע הורדה מלאה במקום לולאת נסה-שוב.
- `ContentHashStampStore` — חותמת `<db>.contenthash.json` עם ה-hash שאומת
  בעדכון האחרון (מוגנת בגודל/mtime); מאפשרת לזהות סטייה בלי לחשב hash.
- `LibraryUpdatePlanner.plan(localContentHash: ...)` — חותמת שאינה תואמת
  לנקודת המוצא של מסלול הדלתא מובילה להורדה מלאה מראש.
- `LibraryUpdatePlan`: תוכניות דלתא נושאות את ה-DB המלא כ-fallback
  (`toFullDownloadFallback`), ו-`targetContentHash` להחתמה אחרי הצלחה.

## 0.1.0

גרסה ראשונית — הוצאה מ-`otzaria/lib/library_update/` לחבילת Dart עצמאית.

- **מקור:** commit `d6d4e9facf5da322e83bdfbc199b899d3b210915` בריפו Otzaria.
- מנוע צריכת הפצות SeforimLibrary: מודלים, גילוי/תכנון מסלול, הורדה ואימות,
  hash לוגי (תואם `LogicalContentHasher.kt` של Kotlin), והחלת patch אטומית.
- חבילת Dart טהורה — ללא תלות ב-Flutter. חילוץ zstd מוזרק על-ידי הצרכן.
