// File: lib/screens/feasts/feasts_page.dart

import 'package:flutter/material.dart';

// =========================================================
// 🔴 I. الثوابت والألوان (AppColors)
// =========================================================

// تم نسخ الألوان من الأكواد التي أرسلتها سابقاً
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // بني داكن
  static const Color secondaryGold = Color(0xFFFFF8E1); // ذهبي فاتح
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFE53935); // اللون الأحمر للتمييز
}

// =========================================================
// 📝 II. نموذج البيانات والقائمة الثابتة
// =========================================================

// 1. نموذج البيانات (FeastModel)
class FeastModel {
  final String title;
  final String dateGregorian; // التاريخ الميلادي
  final String dateCoptic;    // التاريخ القبطي

  const FeastModel({
    required this.title,
    required this.dateGregorian,
    required this.dateCoptic,
  });
}

// 2. قائمة البيانات (The Data List)
final List<FeastModel> feastsList = [
  // هذه التواريخ خاصة بعام 1741-1742 قبطي / 2014 ميلادي
  const FeastModel(title: 'عيد الميلاد المجيد', dateGregorian: 'الثلاثاء 7 يناير', dateCoptic: '29 كيهك 1741'),
  const FeastModel(title: 'عيد الختان', dateGregorian: 'الثلاثاء 14 يناير', dateCoptic: '6 طوبة 1741'),
  const FeastModel(title: 'عيد الغطاس', dateGregorian: 'الأحد 19 يناير', dateCoptic: '11 طوبة 1741'),
  const FeastModel(title: 'عرس قانا الجليل', dateGregorian: 'الثلاثاء 21 يناير', dateCoptic: '13 طوبة 1741'),
  const FeastModel(title: 'بدء صوم يونان', dateGregorian: 'الاثنين 10 فبراير', dateCoptic: '3 أمشير 1741'),
  const FeastModel(title: 'فصح يونان', dateGregorian: 'الخميس 13 فبراير', dateCoptic: '6 أمشير 1741'),
  const FeastModel(title: 'دخول السيد المسيح الهيكل', dateGregorian: 'السبت 15 فبراير', dateCoptic: '8 أمشير 1741'),
  const FeastModel(title: 'بدء الصوم الاربعيني المقدس', dateGregorian: 'الاثنين 24 فبراير', dateCoptic: '17 أمشير 1741'),
  const FeastModel(title: 'عيد ظهور الصليب المقدس', dateGregorian: 'الأربعاء 19 مارس', dateCoptic: '10 برمهات 1741'),
  const FeastModel(title: 'عيد البشارة المجيد', dateGregorian: 'الاثنين 7 أبريل', dateCoptic: '29 برمهات 1741'),
  const FeastModel(title: 'ختام الصوم الاربعيني المقدس', dateGregorian: 'الجمعة 11 أبريل', dateCoptic: '3 برمودة 1741'),
  const FeastModel(title: 'سبت لعازر', dateGregorian: 'السبت 12 أبريل', dateCoptic: '4 برمودة 1741'),
  const FeastModel(title: 'أحد الشعانين', dateGregorian: 'الأحد 13 أبريل', dateCoptic: '5 برمودة 1741'),
  const FeastModel(title: 'خميس العهد', dateGregorian: 'الخميس 17 أبريل', dateCoptic: '9 برمودة 1741'),
  const FeastModel(title: 'الجمعة العظيمة', dateGregorian: 'الجمعة 18 أبريل', dateCoptic: '10 برمودة 1741'),
  const FeastModel(title: 'سبت الفرح', dateGregorian: 'السبت 19 أبريل', dateCoptic: '11 برمودة 1741'),
  const FeastModel(title: 'عيد القيامة المجيد', dateGregorian: 'الأحد 20 أبريل', dateCoptic: '12 برمودة 1741'),
  const FeastModel(title: 'شم النسيم', dateGregorian: 'الاثنين 21 أبريل', dateCoptic: '13 برمودة 1741'),
  const FeastModel(title: 'أحد توما', dateGregorian: 'الأحد 27 أبريل', dateCoptic: '19 برمودة 1741'),
  const FeastModel(title: 'عيد الصعود', dateGregorian: 'الخميس 29 مايو', dateCoptic: '21 بشنس 1741'),
  const FeastModel(title: 'عيد دخول السيد المسيح أرض مصر', dateGregorian: 'الأحد 1 يونيو', dateCoptic: '24 بشنس 1741'),
  const FeastModel(title: 'عيد حلول الروح القدس_عيد العنصره', dateGregorian: 'الأحد 8 يونيو', dateCoptic: '1 بؤونة 1741'),
  const FeastModel(title: 'بدء صوم الرسل', dateGregorian: 'الاثنين 9 يونيو', dateCoptic: '2 بؤونة 1741'),
  const FeastModel(title: 'عيد إستشهاد القديسين بطرس وبولس', dateGregorian: 'السبت 12 يوليو', dateCoptic: '5 أبيب 1741'),
  const FeastModel(title: 'بدء صوم السيدة العذراء مريم', dateGregorian: 'الخميس 7 أغسطس', dateCoptic: '1 مسرى 1741'),
  const FeastModel(title: 'عيد التجلى المجيد', dateGregorian: 'الثلاثاء 19 أغسطس', dateCoptic: '13 مسرى 1741'),
  const FeastModel(title: 'عيد إظهار صعود جسد السيدة العذراء', dateGregorian: 'الجمعة 22 أغسطس', dateCoptic: '16 مسرى 1741'),
  const FeastModel(title: 'عيد النيروز', dateGregorian: 'الخميس 11 سبتمبر', dateCoptic: '1 توت 1742'),
  const FeastModel(title: 'تذكار ظهور الصليب المقدس', dateGregorian: 'السبت 27 سبتمبر', dateCoptic: '17 توت 1742'),
  const FeastModel(title: 'بدء صوم الميلاد', dateGregorian: 'الثلاثاء 25 نوفمبر', dateCoptic: '16 هاتور 1742'),
];


// =========================================================
// 🖥️ III. الـ Widget الأساسي للصفحة (FeastsPage)
// =========================================================

class FeastsPage extends StatelessWidget {
  static const String routeName = '/feasts';
  
  const FeastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // توجيه النص من اليمين لليسار (RTL)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        
        // شريط التطبيق العلوي
        appBar: AppBar(
          title: const Text('🗓️ أجندة الأعياد والأصوام', 
            style: TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold)
          ),
          backgroundColor: AppColors.primaryBlue,
          centerTitle: true,
          elevation: 0,
        ),
        
        // جسم الصفحة (قائمة البطاقات)
        body: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: feastsList.length,
          itemBuilder: (context, index) {
            final feast = feastsList[index];
            return _FeastCard(feast: feast);
          },
        ),
      ),
    );
  }
}

// =========================================================
// 🖼️ IV. الـ Widget الخاص ببطاقة العيد الواحد (المُعدَّل)
// =========================================================

class _FeastCard extends StatelessWidget {
  final FeastModel feast;

  const _FeastCard({required this.feast});

  // دالة مساعدة للحصول على اسم الشهر الحالي باللغة العربية
  String _getCurrentArabicMonth() {
    // جدول الأشهر الميلادية باللغة العربية (كما هو مستخدم في قائمة الأعياد)
    const Map<int, String> arabicMonths = {
      1: 'يناير', 2: 'فبراير', 3: 'مارس', 4: 'أبريل', 
      5: 'مايو', 6: 'يونيو', 7: 'يوليو', 8: 'أغسطس', 
      9: 'سبتمبر', 10: 'أكتوبر', 11: 'نوفمبر', 12: 'ديسمبر',
    };
    final currentMonth = DateTime.now().month;
    return arabicMonths[currentMonth] ?? '';
  }

  // دالة مساعدة لتحديد الأيقونة بناءً على نوع العيد
  IconData _getFeastIcon(String title) {
    if (title.contains('عيد القيامة')) return Icons.celebration;
    if (title.contains('ميلاد')) return Icons.star;
    if (title.contains('صوم')) return Icons.calendar_today;
    if (title.contains('الغطاس') || title.contains('قانا')) return Icons.water;
    if (title.contains('الصليب')) return Icons.cruelty_free_outlined; 
    if (title.contains('السيدة العذراء')) return Icons.church_outlined; 
    if (title.contains('الصعود') || title.contains('حلول الروح القدس')) return Icons.cloud_queue; 
    return Icons.event_note;
  }
  
  // دالة مساعدة لتحديد اللون بناءً على نوع العيد/الصوم (للعنوان فقط)
  Color _getTitleColor(String title) {
    if (title.contains('عيد القيامة') || title.contains('الميلاد')) return AppColors.primaryBlue;
    if (title.contains('صوم') || title.contains('جمعة')) return AppColors.alertRed; 
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    
    // 💡 المنطق الجديد لتمييز الشهر الحالي 💡
    final currentArabicMonth = _getCurrentArabicMonth();
    final isCurrentMonth = feast.dateGregorian.contains(currentArabicMonth);
    
    // اللون والحدود الخاصة بالبطاقة ستعتمد على ما إذا كانت تقع في الشهر الحالي
    final cardBorderColor = isCurrentMonth ? AppColors.alertRed : Colors.transparent;
    final cardBackgroundColor = isCurrentMonth ? AppColors.alertRed.withOpacity(0.1) : AppColors.cardColor;
    
    // تحديد ما إذا كانت صوماً (لا تزال تُستخدم للعنوان والوصف إن أردت)
    final isFast = feast.title.contains('صوم') || feast.title.contains('الجمعة العظيمة');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: isCurrentMonth ? 8 : 4, // رفع مستوى الظل لتمييز الشهر الحالي
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // الحد الأحمر البارز يُستخدم فقط للشهر الحالي
        side: BorderSide(
          color: cardBorderColor, 
          width: isCurrentMonth ? 2.0 : 0.0,
        ),
      ),
      // خلفية البطاقة (تدرج أحمر خفيف للشهر الحالي)
      color: cardBackgroundColor,
      
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. العنوان والأيقونة
            Row(
              children: [
                Icon(_getFeastIcon(feast.title), color: _getTitleColor(feast.title), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    // إذا كان الشهر الحالي، أضف رمزاً لافتاً في البداية
                    isCurrentMonth ? '⭐ ${feast.title}' : feast.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTitleColor(feast.title),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            
            const Divider(color: AppColors.textSecondary, height: 25, thickness: 0.5),

            // 2. تفاصيل التواريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // التاريخ القبطي
                const Icon(Icons.calendar_month, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 5),
                Text(
                  feast.dateCoptic,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
                
                const SizedBox(width: 20),
                
                // التاريخ الميلادي
                const Icon(Icons.date_range, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 5),
                Text(
                  feast.dateGregorian,
                  style: const TextStyle(fontSize: 14, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),

              ].reversed.toList(), // لعرض العناصر من اليمين لليسار مع المحاذاة اليمنى
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 🧪 للاختبار: يمكنك إضافة الـ main التالي لتجربة الصفحة
// =========================================================

/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agenda Demo',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Cairo', // افترض وجود خط عربي
      ),
      // تأكد من أن routeName هو المسار الوحيد
      home: const FeastsPage(),
    );
  }
}
*/