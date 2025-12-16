import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// =====================================================
// 🎨 Custom Theme Colors - ألوان التصميم المبهرة
// =====================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // أزرق ملكي عميق (للعناوين والأزرار الرئيسية)
  static const Color accentGold = Color(0xFFFFC107); // ذهبي فاتح (للإبراز)
  static const Color creamBackground = Color(0xFFFFF8E1); // خلفية كريمية مريحة
  static const Color softGrey = Color(0xFFE0E0E0); // رمادي فاتح للحدود والبطاقات
  static const Color textDark = Color(0xFF333333); // نص داكن للقراءة
}


// =====================================================
// 1. Models - نماذج البيانات (بدون تغيير في المنطق)
// =====================================================

/// يمثل محتوى إصحاح واحد للعرض
class ChapterContent {
  final int chapterNumber;
  final List<String> verses;

  ChapterContent({required this.chapterNumber, required this.verses});
}

// 🛠️ خريطة للترجمة من الأسماء الإنجليزية الشائعة إلى العربية (للتأكد من العرض الصحيح)
const Map<String, String> _englishToArabicBookNames = {
  // العهد القديم (Old Testament)
  'Genesis': 'سفر التكوين', 'Exodus': 'سفر الخروج', 'Leviticus': 'سفر اللاويين', 
  'Numbers': 'سفر العدد', 'Deuteronomy': 'سفر التثنية', 'Joshua': 'سفر يشوع', 
  'Judges': 'سفر القضاة', 'Ruth': 'سفر راعوث', '1 Samuel': 'سفر صموئيل الأول', 
  '2 Samuel': 'سفر صموئيل الثاني', '1 Kings': 'سفر الملوك الأول', '2 Kings': 'سفر الملوك الثاني', 
  '1 Chronicles': 'سفر أخبار الأيام الأول', '2 Chronicles': 'سفر أخبار الأيام الثاني', 'Ezra': 'سفر عزرا', 
  'Nehemiah': 'سفر نحميا', 'Esther': 'سفر أستير', 'Job': 'سفر أيوب', 
  'Psalms': 'سفر المزامير', 'Proverbs': 'سفر الأمثال', 'Ecclesiastes': 'سفر الجامعة', 
  'Song of Solomon': 'سفر نشيد الأنشاد', 'Isaiah': 'سفر إشعياء', 'Jeremiah': 'سفر إرميا', 
  'Lamentations': 'سفر مراثي إرميا', 'Ezekiel': 'سفر حزقيال', 'Daniel': 'سفر دانيال', 
  'Hosea': 'سفر هوشع', 'Joel': 'سفر يوئيل', 'Amos': 'سفر عاموس', 
  'Obadiah': 'سفر عوبديا', 'Jonah': 'سفر يونان', 'Micah': 'سفر ميخا', 
  'Nahum': 'سفر ناحوم', 'Habakkuk': 'سفر حبقوق', 'Zephaniah': 'سفر صفنيا', 
  'Haggai': 'سفر حجى', 'Zechariah': 'سفر زكريا', 'Malachi': 'سفر ملاخي', 

  // العهد الجديد (New Testament)
  'Matthew': 'إنجيل متى', 'Mark': 'إنجيل مرقس', 'Luke': 'إنجيل لوقا', 
  'John': 'إنجيل يوحنا', 'Acts': 'سفر أعمال الرسل', 'Romans': 'رسالة رومية', 
  '1 Corinthians': 'رسالة كورنثوس الأولى', '2 Corinthians': 'رسالة كورنثوس الثانية', 'Galatians': 'رسالة غلاطية', 
  'Ephesians': 'رسالة أفسس', 'Philippians': 'رسالة فيلبي', 'Colossians': 'رسالة كولوسي', 
  '1 Thessalonians': 'رسالة تسالونيكي الأولى', '2 Thessalonians': 'رسالة تسالونيكي الثانية', '1 Timothy': 'رسالة تيموثاوس الأولى', 
  '2 Timothy': 'رسالة تيموثاوس الثانية', 'Titus': 'رسالة تيطس', 'Philemon': 'رسالة فليمون', 
  'Hebrews': 'رسالة العبرانيين', 'James': 'رسالة يعقوب', '1 Peter': 'رسالة بطرس الأولى', 
  '2 Peter': 'رسالة بطرس الثانية', '1 John': 'رسالة يوحنا الأولى', '2 John': 'رسالة يوحنا الثانية', 
  '3 John': 'رسالة يوحنا الثالثة', 'Jude': 'رسالة يهوذا', 'Revelation': 'سفر الرؤيا',

  // بدائل إنجليزية أخرى شائعة
  'Gen': 'سفر التكوين', 'Exod': 'سفر الخروج', 'Matt': 'إنجيل متى', 'Rev': 'سفر الرؤيا',
  'Corinthians 1': 'رسالة كورنثوس الأولى', 'Corinthians 2': 'رسالة كورنثوس الثانية',
  'Thessalonians 1': 'رسالة تسالونيكي الأولى', 'Thessalonians 2': 'رسالة تسالونيكي الثانية',
  'Timothy 1': 'رسالة تيموثاوس الأولى', 'Timothy 2': 'رسالة تيموثاوس الثانية',
  'Peter 1': 'رسالة بطرس الأولى', 'Peter 2': 'رسالة بطرس الثانية',
  'John 1': 'رسالة يوحنا الأولى', 'John 2': 'رسالة يوحنا الثانية', 'John 3': 'رسالة يوحنا الثالثة',
};


/// يمثل البيانات الكاملة لسفر واحد (مستخرجة من الملف الشامل)
class BibleBookData {
  final String abbrev; 
  final String bookName; 
  // قائمة الإصحاحات، وكل إصحاح هو قائمة من الآيات (String)
  final List<List<String>> allChaptersVerses; 
  
  int get chapterCount => allChaptersVerses.length;

  BibleBookData({
    required this.abbrev,
    required this.bookName,
    required this.allChaptersVerses,
  });

  // تحويل من JSON مع مرونة في البحث عن أسماء المفاتيح مع دعم الترجمة
  factory BibleBookData.fromJson(Map<String, dynamic> json) {
    String rawBookName = '';
    String rawAbbrev = '';
    
    // 1. محاولة استخلاص الاسم الخام للسفر (قد يكون عربي أو إنجليزي أو غير معروف)
    rawBookName = (json['سفر'] as String?) ?? 
                  (json['book'] as String?) ?? 
                  (json['name'] as String?) ?? 
                  'سفر غير معروف';
                            
    // 2. محاولة استخلاص الاختصار الخام
    rawAbbrev = (json['اختصار'] as String?) ?? 
                (json['abbrev'] as String?) ?? 
                (json['id'] as String?) ?? 
                'غير معروف';

    // 3. 💡 الترجمة: إذا كان الاسم الخام إنجليزياً، يتم ترجمته إلى الاسم العربي
    String finalBookName = _englishToArabicBookNames[rawBookName.trim()] ?? rawBookName;
    
    // 4. معالجة الإصحاحات
    final List<dynamic> chaptersJson = json['chapters'] as List<dynamic>? ?? [];
    
    final allChaptersVerses = chaptersJson.map((chapter) {
      // كل إصحاح هو قائمة من الآيات (strings)
      return (chapter as List<dynamic>? ?? [])
          .map((verse) {
             // 🛠️ تأكد من أن الآية نص
             return (verse is String) ? verse : (verse?.toString() ?? "");
          })
          .toList();

    }).toList();

    return BibleBookData(
      abbrev: rawAbbrev,
      bookName: finalBookName, // نستخدم الاسم المترجم أو الخام
      allChaptersVerses: allChaptersVerses,
    );
  }
}

// =====================================================
// 2. Service - خدمة قراءة البيانات مع التخزين المؤقت
// =====================================================

class BibleService {
  // التخزين المؤقت
  List<BibleBookData>? _bibleDataCache;

  // المسار يجب أن يكون assets/ar_svd.json
  static const String assetPath = 'assets/ar_svd.json'; 

  Future<List<BibleBookData>> loadBibleData() async {
    if (_bibleDataCache != null) {
      return _bibleDataCache!;
    }
    
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      // هنا نقوم بتحويل كل عنصر في القائمة إلى BibleBookData
      _bibleDataCache = jsonList.map((data) => 
        BibleBookData.fromJson(data as Map<String, dynamic>)
      ).toList();

      if (_bibleDataCache!.isNotEmpty && _bibleDataCache![0].bookName.contains('غير معروف')) {
          debugPrint("WARNING: JSON keys (book/abbrev/سفر/اختصار) might be wrong or file is malformed. Check the file structure.");
      }

      return _bibleDataCache!;

    } on FlutterError catch (e) {
      debugPrint("ERROR: Asset not found or path incorrect. $assetPath - $e");
      return _generateMockData(e.toString());
    } catch (e) {
      debugPrint("ERROR: JSON parsing or loading failed: $e");
      return _generateMockData(e.toString());
    }
  }

  // بيانات وهمية للتشغيل في حال الخطأ
  List<BibleBookData> _generateMockData(String error) {
     return [
        BibleBookData(
          abbrev: 'mock',
          bookName: 'سفر وهمي (خطأ في التحميل)',
          allChaptersVerses: [[ 
             "1. خطأ في قراءة بيانات الأسفار. $error",
             "2. تأكد أن ملف ar_svd.json موجود مباشرة في مجلد assets وليس داخل مجلد فرعي (مثل assets/lottie).",
             "3. تأكد أن الملف ليس فارغاً أو تالفاً."
          ]],
        ),
      ];
  }

  // استخراج محتوى إصحاح معين من بيانات السفر المخزنة
  ChapterContent getChapterContent(BibleBookData book, int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < book.allChaptersVerses.length) {
      return ChapterContent(
        chapterNumber: chapterIndex + 1, 
        verses: book.allChaptersVerses[chapterIndex],
      );
    }
    return ChapterContent(chapterNumber: chapterIndex + 1, verses: ["المرجع غير موجود."]);
  }
}

// =====================================================
// 3. UI Entry Point - مدخل الواجهة (شاشة التحميل الأولية)
// =====================================================

/// الصفحة الرئيسية لقارئ الإنجيل - تبدأ بتحميل البيانات.
class BibleFeaturePage extends StatelessWidget {
  final BibleService service = BibleService();

  BibleFeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text(
          "الكتاب المقدس", 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        elevation: 8,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<BibleBookData>>(
          future: service.loadBibleData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.accentGold),
                    SizedBox(height: 16),
                    Text(
                      "جارِ تحميل كنوز المعرفة...", 
                      style: TextStyle(fontSize: 18, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty || snapshot.data![0].abbrev == 'mock') {
              final errorMessage = snapshot.data != null && snapshot.data!.isNotEmpty 
                  ? snapshot.data![0].allChaptersVerses[0].join('\n') 
                  : "خطأ غير محدد في تحميل الملف. راجع pubspec.yaml.";

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    errorMessage, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }
            
            // إذا تم التحميل بنجاح، نذهب إلى صفحة الأسفار
            return BibleBooksPage(allBooks: snapshot.data!);
          },
        ),
      ),
    );
  }
}


/// 1️⃣ شاشة اختيار السفر (الكتاب) - تصميم فاخر للبطاقات
class BibleBooksPage extends StatelessWidget {
  final List<BibleBookData> allBooks;

  const BibleBooksPage({super.key, required this.allBooks});

  @override
  Widget build(BuildContext context) {
    const int oldTestamentCount = 39; 
    final bool canSplit = allBooks.length >= oldTestamentCount;

    final List<BibleBookData> oldTestament = canSplit ? allBooks.sublist(0, oldTestamentCount) : allBooks;
    final List<BibleBookData> newTestament = canSplit && allBooks.length > oldTestamentCount ? allBooks.sublist(oldTestamentCount) : [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookList(context, "العهد القديم", oldTestament, Icons.history_edu),
        if (newTestament.isNotEmpty) ...[
          const SizedBox(height: 30),
          _buildBookList(context, "العهد الجديد", newTestament, Icons.menu_book),
        ],
      ],
    );
  }

  Widget _buildBookList(BuildContext context, String title, List<BibleBookData> books, IconData icon) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 5.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accentGold, size: 28),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            childAspectRatio: 2.2, // نسبة عرض/ارتفاع البطاقة
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: books.length,
          itemBuilder: (context, i) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BibleChaptersPage(book: books[i]),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), 
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      books[i].bookName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w700, 
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 2️⃣ شاشة اختيار الإصحاح (الفصل) - تصميم أزرار مميز
class BibleChaptersPage extends StatelessWidget {
  final BibleBookData book;

  const BibleChaptersPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final int totalChapters = book.chapterCount; 

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(book.bookName, style: const TextStyle(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        elevation: 8,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, 
            childAspectRatio: 1.0, 
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: totalChapters,
          itemBuilder: (context, chapterIndex) {
            final chapterNumber = chapterIndex + 1; 

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BibleVersesPage(
                      book: book,
                      chapterIndex: chapterIndex, 
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(15), // زوايا مستديرة أكثر
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3), 
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$chapterNumber',
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentGold, // الرقم باللون الذهبي
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 3️⃣ شاشة عرض الآيات - تصميم مريح للقراءة
class BibleVersesPage extends StatelessWidget {
  final BibleBookData book;
  final int chapterIndex; 

  const BibleVersesPage({super.key, required this.book, required this.chapterIndex});

  @override
  Widget build(BuildContext context) {
    final BibleService service = BibleService();
    final ChapterContent chapterContent = service.getChapterContent(book, chapterIndex);
    
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(
          "${book.bookName} إصحاح ${chapterContent.chapterNumber}", 
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        elevation: 8,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Scrollbar( // إضافة شريط تمرير أنيق
          child: ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: chapterContent.verses.length,
            itemBuilder: (context, verseIndex) {
              final int verseNumber = verseIndex + 1;
              final String verseText = chapterContent.verses[verseIndex];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: SelectableText.rich( 
                  TextSpan( 
                    children: [
                      TextSpan(
                        text: '$verseNumber. ', // إضافة نقطة
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900, // وزن أثقل
                          color: AppColors.accentGold, // رقم الآية باللون الذهبي
                        ),
                      ),
                      TextSpan(
                        text: verseText,
                        style: const TextStyle(
                          fontSize: 19, // خط أكبر قليلاً
                          height: 1.8, // تباعد سطور أكبر للراحة
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}