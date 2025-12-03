import 'package:churchapp/screens/NewsPage.dart';
import 'package:churchapp/screens/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // لاستخدام Random لجلب الآية العشوائية
import 'dart:async'; // لاستخدام Timer
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat; 
// يجب عليك التأكد من وجود هذه الملفات في المسار الصحيح
import 'app_drawer.dart'; 


// ==================================================================
// 🔴 الثوابت ونماذج البيانات (Constants and Models)
// ==================================================================

// 1. تعريف AppColors
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // لون بني داكن/كحلي
  static const Color secondaryGold = Color(0xFFFFF8E1); // لون ذهبي فاتح/كريمي
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color.fromARGB(255, 1, 64, 127); // لون أحمر غامق/أزرق غامق للتنبيه
}

// 2. نموذج بيانات الأخبار
class ChurchPost {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool isUrgent; 

  const ChurchPost({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isUrgent = false,
  });

  factory ChurchPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return ChurchPost(
      id: doc.id,
      title: data?['title'] ?? 'عنوان مفقود',
      body: data?['body'] ?? 'محتوى مفقود',
      date: (data?['date'] as Timestamp? ?? Timestamp.now()).toDate(), 
      isUrgent: data?['isUrgent'] ?? false,
    );
  }
}

// دالة تحويل الوقت إلى نص مناسب
String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd | hh:mm a', 'ar').format(date);
}


// ******************************************************************
// 🔴 دالة محاكاة لجلب آية اليوم من قائمة محلية
// ******************************************************************

// قائمة الآيات المحلية (تم اختصارها للمثال)
const List<String> localBibleVerses = [
  'لِأَنَّهُ هُوَ الَّذِي يُعْطِي جَمِيعاً حَيَاةً وَنَفْساً وَكُلَّ شَيْءٍ. (أعمال الرسل 17:25)',
  'مَعَ الْمَسِيحِ صُلِبْتُ، فَأَحْيَا لَا أَنَا، بَلِ الْمَسِيحُ يَحْيَا فِيَّ. (غلاطية 2:20)',
  'الرَّبُّ رَاعِيَّ فَلَا يُعْوِزُنِي شَيْءٌ. (المزامير 23:1)',
  'كُلُّ شَيْءٍ مُسْتَطَاعٌ لِلْمُؤْمِنِ. (مرقس 9:23)',
  'اَللهُ مَحَبَّةٌ. (يوحنا الأولى 4:8)',
  'طُوبَى لِلأَنْقِيَاءِ الْقَلْبِ، لأَنَّهُمْ يُعَايِنُونَ اللهَ. (متى 5:8)',
  'جَاهِدْ جِهَادَ الإِيمَانِ الْحَسَنَ. (تيموثاوس الأولى 6:12)',
  'فَلْيُضِئْ نُورُكُمْ هَكَذَا قُدَّامَ النَّاسِ. (متى 5:16)',
  'لَا تَخَفْ، فَإِنِّي مَعَكَ. (إشعياء 41:10)',
  'مِنْ أَجْلِ ذَلِكَ أَقُولُ لَكُمْ: كُلُّ مَا تَطْلُبُونَهُ حِينَما تُصَلُّونَ، فَآمِنُوا أَنْ تَنَالُوهُ، فَيَكُونَ لَكُمْ. (مرقس 11:24)',
  'وَلَكِنْ مُنْذُ الْآنَ سَتَرَوْنَ ابْنَ الإِنْسَانِ جَالِساً عَنْ يَمِينِ الْقُوَّةِ وَآتِياً عَلَى سَحَابِ السَّمَاءِ. (متى 26:64)',
  'اَلْمَحَبَّةُ لَا تَسْقُطُ أَبَداً. (كورنثوس الأولى 13:8)',
  'لَا تَهْتَمُّوا بِشَيْءٍ، بَلْ فِي كُلِّ شَيْءٍ بِالصَّلَاةِ وَالدُّعَاءِ مَعَ الشُّكْرِ، لِتُعْلَمْ طِلْبَاتُكُمْ لَدَى اللهِ. (فيلبي 4:6)',
  'إِنَّمَا خَلَقَ كُلَّ شَيْءٍ بِكَلِمَةِ قُوَّتِهِ. (عبرانيين 1:3)',
  'الَّذِي لَمْ يُشْفِقْ عَلَى ابْنِهِ، بَلْ بَذَلَهُ لأَجْلِنَا أَجْمَعِينَ، كَيْفَ لَا يَهَبُنَا أَيْضاً مَعَهُ كُلَّ شَيْءٍ؟ (رومية 8:32)',
  'وَنَحْنُ نَعْلَمُ أَنَّ كُلَّ الأَشْيَاءِ تَعْمَلُ مَعاً لِلْخَيْرِ لِلَّذِينَ يُحِبُّونَ اللهَ. (رومية 8:28)',
  'اِسْهَرُوا وَصَلُّوا لِئَلَّا تَدْخُلُوا فِي تَجْرِبَةٍ. (متى 26:41)',
  'لِأَنَّ أُجْرَةَ الْخَطِيَّةِ هِيَ مَوْتٌ، وَأَمَّا هِبَةُ اللهِ فَهِيَ حَيَاةٌ أَبَدِيَّةٌ بِالْمَسِيحِ يَسُوعَ رَبِّنَا. (رومية 6:23)',
  'الْفِرْحَةُ بِالرَّبِّ هِيَ قُوَّتُكُمْ. (نحميا 8:10)',
  'كُلُّ الْكِتَابِ هُوَ مُوحًى بِهِ مِنَ اللهِ، وَنَافِعٌ لِلتَّعْلِيمِ وَالتَّوْبِيخِ، لِلتَّقْوِيمِ وَالتَّأْدِيبِ الَّذِي فِي الْبِرِّ. (تيموثاوس الثانية 3:16)',
  'اَلنَّامُوسُ بِالْمُوسَى أُعْطِيَ، أَمَّا النِّعْمَةُ وَالْحَقُّ فَبِيَسُوعَ الْمَسِيحِ صَارَا. (يوحنا 1:17)',
  'إِنْ سَلَكْنَا فِي النُّورِ كَمَا هُوَ فِي النُّورِ، فَلَنَا شَرِكَةٌ بَعْضِنَا مَعَ بَعْضٍ. (يوحنا الأولى 1:7)',
  'أَنَا هُوَ الْقِيَامَةُ وَالْحَيَاةُ. (يوحنا 11:25)',
  'قُوَّةُ اللهِ فِي الضَّعْفِ تُكَمَّلُ. (كورنثوس الثانية 12:9)',
  'لَكِنْ فِي كُلِّ هَذِهِ نَحْنُ أَعْظَمُ مِنْ غَالِبِينَ بِالَّذِي أَحَبَّنَا. (رومية 8:37)',
  'لَا تَكُنْ صَدِيقاً لِصَاحِبِ غَضَبٍ، وَمَعَ رَجُلٍ سَاخِطٍ لَا تَذْهَبْ. (الأمثال 22:24)',
  'الْحِكْمَةُ خَيْرٌ مِنَ الْقُوَّةِ. (الجامعة 9:16)',
  'لِأَنَّنَا إِنْ عَشْنَا فَلِلرَّبِّ نَعِيشُ، وَإِنْ مُتْنَا فَلِلرَّبِّ نَمُوتُ. (رومية 14:8)',
  'اِثْبُتُوا فِيَّ وَأَنَا فِيكُمْ. (يوحنا 15:4)',
  'فَإِنَّ اللهَ لَمْ يُعْطِنَا رُوحَ الْفَشَلِ، بَلْ رُوحَ الْقُوَّةِ وَالْمَحَبَّةِ وَالنُّصْحِ. (تيموثاوس الثانية 1:7)',
  'اَلرَّبُّ صَالِحٌ، حِصْنٌ فِي يَوْمِ الضَّيقِ، وَهُوَ يَعْرِفُ الْمُتَوَكِّلِينَ عَلَيْهِ. (ناحوم 1:7)',
  'أَنَا هُوَ نُورُ الْعَالَمِ. (يوحنا 8:12)',
  'اَلرَّبُّ قَرِيبٌ لِكُلِّ الَّذِينَ يَدْعُونَهُ. (المزامير 145:18)',
  'لِيَكُنْ مِزَاجُكُمْ بِلَا حُبِّ الْمَالِ. (عبرانيين 13:5)',
  'اُخْلُعُوا الإِنْسَانَ الْعَتِيقَ مَعَ أَعْمَالِهِ. (كولوسي 3:9)',
  'مُبَارَكٌ الرَّجُلُ الَّذِي يَتَّكِلُ عَلَى الرَّبِّ. (إرميا 17:7)',
  'اَلْحَيَاةُ وَالْمَوْتُ فِي يَدِ اللِّسَانِ. (الأمثال 18:21)',
  'عَظِيمٌ هُوَ سِرُّ التَّقْوَى. (تيموثاوس الأولى 3:16)',
  'اَلْحُبُّ لَا يَصْنَعُ شَرّاً لِلْقَرِيبِ. (رومية 13:10)',
  'طُوبَى لِمَنْ يَغْفِرُ لَهُ إِثْمُهُ وَتُسْتَرُ خَطِيَّتُهُ. (المزامير 32:1)',
  'اَللَّهُ لَا يَرُدُّ سُؤَالَ الْمُتَضَرِّعِينَ. (أيوب 35:13)',
  'اَلْكَلِمَةُ صَارَتْ جَسَداً وَحَلَّتْ بَيْنَنَا. (يوحنا 1:14)',
  'وَنَعْمَلُ بِكُلِّ مَا هُوَ مُسَرٌّ وَمُفِيدٌ. (تيطس 3:8)',
  'لِأَنَّ الْمَسِيحَ أَيْضاً مَاتَ مَرَّةً وَاحِدَةً مِنْ أَجْلِ الْخَطَايَا. (بطرس الأولى 3:18)',
  'أَطِيعُوا مُرْشِدِيكُمْ وَاخْضَعُوا. (عبرانيين 13:17)',
  'فِي الْحَقِيقَةِ، كَلَامُ اللهِ حَيٌّ وَفَعَّالٌ. (عبرانيين 4:12)',
  'اَلْخَطِيئَةُ لَا تَسُودُكُمْ. (رومية 6:14)',
  'وَأَمَّا ثَمَرُ الرُّوحِ فَهُوَ مَحَبَّةٌ، فَرَحٌ، سَلَامٌ. (غلاطية 5:22)',
  'فَرَحاً فِي الرَّبِّ كُلَّ حِينٍ. (فيلبي 4:4)',
  'أَنَا الْكَرْمَةُ وَأَنْتُمُ الأَغْصَانُ. (يوحنا 15:5)',
  'لِيَكُنْ كَلَامُكُمْ كُلَّ حِينٍ بِنِعْمَةٍ، مُصْلَحاً بِمِلْحٍ. (كولوسي 4:6)',
  'اِفْعَلْ كُلَّ شَيْءٍ لِمَجْدِ اللهِ. (كورنثوس الأولى 10:31)',
  'إِنْ أَحْبَبْتُمُونِي فَاحْفَظُوا وَصَايَايَ. (يوحنا 14:15)',
  'اَلْمَخَافَةُ هِيَ مَخَافَةُ الرَّبِّ، لِأَنَّهُ يُعْطِي الْحِكْمَةَ. (الأمثال 2:6)',
  'اَلْإِيمَانُ هُوَ الثِّقَةُ بِمَا يُرْجَى وَالإِيقَانُ بِأُمُورٍ لَا تُرَى. (عبرانيين 11:1)',
  'اِفْرَحُوا مَعَ الْفَرِحِينَ وَابْكُوا مَعَ الْبَاكِينَ. (رومية 12:15)',
  'لِأَنَّ اللهَ لَمْ يُقَدِّرْنَا لِلْغَضَبِ، بَلْ لِإِحْرَازِ الْخَلَاصِ. (تسالونيكي الأولى 5:9)',
  'اَلْمَسِيحُ يَسُوعُ جَاءَ إِلَى الْعَالَمِ لِيُخَلِّصَ الْخُطَاةَ. (تيموثاوس الأولى 1:15)',
  'لَا تَسْمَحْ لِلشَّرِّ أَنْ يَغْلِبَكَ، بَلِ اغْلِبِ الشَّرَّ بِالْخَيْرِ. (رومية 12:21)',
  'فَأَنْتُمْ نُورُ الْعَالَمِ. (متى 5:14)',
  'لَا تُطْفِئُوا الرُّوحَ. (تسالونيكي الأولى 5:19)',
  'اَلْكَرَمُ لِكُلِّ مَنْ يَعْمَلُ الْخَيْرَ. (رومية 2:10)',
  'وَنَحْنُ أَيْضاً نُجَاهِدُ جِهَاداً شَرِيفاً. (تيموثاوس الثانية 2:5)',
  'اِعْتَمِدُوا عَلَى الرَّبِّ كُلَّ حِينٍ. (إشعياء 26:4)',
  'لَا تَكُنْ صَدِيقاً لِصَاحِبِ غَضَبٍ. (الأمثال 22:24)',
  'اُطْلُبُوا أَوَّلاً مَلَكُوتَ اللهِ وَبِرَّهُ. (متى 6:33)',
  'اَلْمَحَبَّةُ تَصْبِرُ طَوِيلاً، وَتَرْفُقُ. (كورنثوس الأولى 13:4)',
  'اَلرَّبُّ يُحَارِبُ عَنْكُمْ وَأَنْتُمْ تَصْمُتُونَ. (الخروج 14:14)',
  'الْمَسِيحُ يُحِبُّ الْكَنِيسَةَ وَبَذَلَ نَفْسَهُ لِأَجْلِهَا. (أفسس 5:25)',
  'اَلْأَفْضَلُ مِنَ الشَّرَفِ هُوَ الْحِكْمَةُ. (الأمثال 3:35)',
  'لَا تَقْضُوا عَلَى أَحَدٍ. (متى 7:1)',
  'إِنَّكُمْ أَبْنَاءُ النُّورِ وَأَبْنَاءُ النَّهَارِ. (تسالونيكي الأولى 5:5)',
  'كُلُّ مَا هُوَ حَقٌّ، كُلُّ مَا هُوَ جَلِيلٌ... فَفِي هَذِهِ افْتَكِرُوا. (فيلبي 4:8)',
  'فِي الْعَالَمِ سَيَكُونُ لَكُمْ ضِيقٌ. (يوحنا 16:33)',
  'اَلْمُؤْمِنُ بِهِ لَا يُدَانُ. (يوحنا 3:18)',
  'لَا نُحِبَّ بِالْكَلَامِ وَلَا بِاللِّسَانِ، بَلْ بِالْعَمَلِ وَالْحَقِّ. (يوحنا الأولى 3:18)',
  'اَلْقُوَّةُ وَالْمَجْدُ لِلَّهِ. (بطرس الأولى 4:11)',
  'عِيشُوا كَأَوْلَادِ النُّورِ. (أفسس 5:8)',
  'اَلْحَيَاةُ هِيَ مَعْرِفَةُ اللهِ. (يوحنا 17:3)',
  'لَا شَيْءَ يَفْصِلُنَا عَنْ مَحَبَّةِ اللهِ. (رومية 8:39)',
  'اَللَّهُ يَفْحَصُ الْقُلُوبَ. (رومية 8:27)',
  'الْبَسُوا الْمَحَبَّةَ الَّتِي هِيَ رِبَاطُ الْكَمَالِ. (كولوسي 3:14)',
  'لِأَنَّهُ هُوَ سَلَامُنَا. (أفسس 2:14)',
  'اَلصِّدِّيقُ يُزْهِرُ كَالنَّخْلَةِ. (المزامير 92:12)',
  'اَلنِّعْمَةُ لِكُلِّ الَّذِينَ يُحِبُّونَ رَبَّنَا يَسُوعَ الْمَسِيحَ. (أفسس 6:24)',
  'اَلْمَجْدُ للهِ فِي الأَعَالِي وَعَلَى الأَرْضِ السَّلَامُ. (لوقا 2:14)',
  'أَلْقِ عَلَى الرَّبِّ هَمَّكَ فَيَعُولُكَ. (المزامير 55:22)',
  'وَلَا تَشْغَلُوا أَنْفُسَكُمْ بِأُمُورِ الْعَالَمِ. (كورنثوس الأولى 7:31)',
  'اَلْغَضَبُ لَا يَصْنَعُ بِرَّ اللهِ. (يعقوب 1:20)',
  'اِقْتَرِبُوا إِلَى اللهِ فَيَقْتَرِبَ إِلَيْكُمْ. (يعقوب 4:8)',
  'طُوبَى لِلَّذِينَ يَجُوعُونَ وَيَعْطَشُونَ إِلَى الْبِرِّ. (متى 5:6)',
  'مِنْ أَجْلِ ذَلِكَ خَرَجَ الْمَسِيحُ إِلَى الْجَلْجَلَةِ. (عبرانيين 13:12)',
  'اِعْلَمُوا أَنَّ الرَّبَّ قَدِ اصْطَفَى تَقِيَّهُ. (المزامير 4:3)',
  'فَاحْفَظُوا كَلِمَةَ نِعْمَتِهِ. (أعمال الرسل 20:32)',
  'اَلرَّبُّ يُقَوِّي شَعْبَهُ بِالسَّلَامِ. (المزامير 29:11)',
  'اَلْخَلاصُ لِلرَّبِّ. (المزامير 3:8)',
  'أَنَا وَأَبِي وَاحِدٌ. (يوحنا 10:30)',
  'اَلنِّعْمَةُ مُعْطَاةٌ لَنَا فِي الْمَسِيحِ يَسُوعَ. (تيموثاوس الثانية 2:1)',
  'الْمُحِبُّ لَا يُنْتَفَخُ. (كورنثوس الأولى 13:4)',
  'وَالرَّبُّ نَفْسُهُ يَسِيرُ أَمَامَكَ. (التثنية 31:8)',
  'اِتْرُكُوا كُلَّ مَرَارَةٍ وَسَخْطٍ وَغَضَبٍ. (أفسس 4:31)',
  'تَمَجَّدُوا بِاللهِ. (رومية 5:11)',
  'اَلْمَسِيحُ يُحِبُّنَا أَوَّلاً. (يوحنا الأولى 4:19)',
  'كُلُّ مَا تَفْعَلُونَهُ فَافْعَلُوهُ مِنْ كُلِّ النَّفْسِ. (كولوسي 3:23)',
  'لَا تَخْفُوا، بَلْ تَكَلَّمُوا. (أعمال الرسل 18:9)',
  'اَلرُّوحُ يُعْطِي حَيَاةً. (كورنثوس الثانية 3:6)',
  'لِأَنَّ اللهَ لَيْسَ إِلَهَ فَوْضَى بَلْ سَلَامٍ. (كورنثوس الأولى 14:33)',
  'اَلْإِنْسَانُ لَا يَحْيَا بِالْخُبْزِ وَحْدَهُ. (متى 4:4)',
  'اَلصِّدْقُ خَيْرٌ مِنْ كُلِّ الذَّبَائِحِ. (الأمثال 21:3)',
  'اَلْقَلْبُ النَّقِيُّ لَا يَخَافُ. (الأمثال 28:1)',
  'وَهُمْ سَيَدْعُونَ اسْمَهُ عِمَّانُوئِيلَ. (متى 1:23)',
  'لِكُلِّ شَيْءٍ زَمَانٌ. (الجامعة 3:1)',
];

Future<String> fetchDailyVerse() async {
  final int randomIndex = Random().nextInt(localBibleVerses.length);
  await Future.delayed(const Duration(milliseconds: 500)); 
  return localBibleVerses[randomIndex];
}


// ==================================================================
// 🔴 الصفحة الرئيسية (HomePage)
// ==================================================================

class HomePage extends StatefulWidget {
  static const String routeName = "/HomePage"; 
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// 🛑 التعديل الأول: إضافة with SingleTickerProviderStateMixin
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin { 
  // قائمة بأزرار الوصول السريع
  final List<Map<String, dynamic>> quickActions = const [
        {'title': 'الإنجيل', 'icon': Icons.menu_book, 'route': '/bible'},

    {'title': ' القداسات و العشيات', 'icon': Icons.church, 'route': '/masses'},
    {'title': 'الخمس خبزات', 'icon': Icons.food_bank, 'route': '/StorePage'},
    {'title': 'الاجتماعات', 'icon': Icons.groups_2, 'route': '/meetings'},
    {'title': 'الأنشطة والرحلات', 'icon': Icons.event, 'route': '/events'},
        {'title': 'الافتقاد', 'icon': Icons.event, 'route': '/service'},
  ];

  // متغيرات الحالة
  String _dailyVerse = 'جاري جلب الآية...';
  List<ChurchPost> _urgentNewsList = []; 
  List<ChurchPost> _latestNews = []; 
  bool _isLoadingVerse = true;
  bool _isLoadingNews = true;
  bool _hasFetchError = false; // 👈 متغير جديد لتتبع خطأ الجلب
  DateTime? _lastPressed; // 👈 متغير لتتبع ضغطة زر الرجوع

  // متغير التحكم في شريط الأخبار العاجلة والتمرير التلقائي
  final PageController _pageController = PageController();
  Timer? _tickerTimer;
  
  // ✅ متحكم الحركة المستمرة (النبض)
  late AnimationController _pulseController;
  // ✅ منحنى الحركة لتأثير النبض
  late Animation<double> _pulseAnimation;
  
  // استخدام المتغير العالمي __app_id 
  final String _appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
  late final CollectionReference _newsCollection;
  bool _isLocaleInitialized = false; 
  
  @override
  void initState() {
    super.initState();
    
    _initializeLocale();
    _newsCollection = FirebaseFirestore.instance.collection('artifacts').doc(_appId).collection('public').doc('data').collection('news');
    
    _getDailyVerse();
    _fetchNewsData(); 
    // بدء التمرير التلقائي للأخبار العاجلة بعد جلب البيانات
    _startNewsTickerTimer(); 
    
    // 🚀 تهيئة متحكم الحركة المستمرة (النبض/الدوران)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // مدة الحركة (ثانية واحدة)
    );

    // 🚀 تعريف الحركة (تأثير النبض البسيط من حجم 1.0 إلى 1.15)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // 🚀 تشغيل الحركة في حلقة مستمرة (ذهاب وإياب)
    _pulseController.repeat(reverse: true); 
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tickerTimer?.cancel(); // إلغاء المؤقت عند التخلص من الصفحة
    _pulseController.dispose(); // 🛑 التعديل الثالث: التخلص من المتحكم
    super.dispose();
  }

  // دالة لتهيئة بيانات اللغة العربية 
  Future<void> _initializeLocale() async {
    try {
      // يفضل نقل هذا الاستدعاء إلى دالة main()
      await initializeDateFormatting('ar', null);
    } catch (e) {
      debugPrint('Error initializing locale data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    }
  }
  
  // دالة جلب آية اليوم
  Future<void> _getDailyVerse() async {
    final verse = await fetchDailyVerse();
    if (mounted) {
      setState(() {
        _dailyVerse = verse;
        _isLoadingVerse = false;
      });
    }
  }

  // جلب الأخبار العاجلة والأخبار العادية من Firestore 
  Future<void> _fetchNewsData() async {
    if (mounted) {
      setState(() {
        _isLoadingNews = true;
        _hasFetchError = false;
      });
    }

    try {
      // 2.1 جلب الخبر العاجل الأحدث (5 أخبار كحد أقصى)
      final urgentQuerySnapshot = await _newsCollection
          .where('isUrgent', isEqualTo: true)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      _urgentNewsList = urgentQuerySnapshot.docs.map((doc) => ChurchPost.fromFirestore(doc)).toList();
      
      // 2.2 جلب أحدث 3 أخبار غير عاجلة
      final latestNewsQuerySnapshot = await _newsCollection
          .where('isUrgent', isEqualTo: false)
          .orderBy('date', descending: true)
          .limit(3)
          .get();

      _latestNews = latestNewsQuerySnapshot.docs.map((doc) => ChurchPost.fromFirestore(doc)).toList();

    } catch (e) {
      debugPrint('❌❌ خطأ فادح في جلب بيانات الأخبار في HomePage: $e');
      if (mounted) {
        setState(() {
          _hasFetchError = true; // الإشارة إلى وجود خطأ في الجلب
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  // دالة تشغيل مؤقت التمرير التلقائي للأخبار العاجلة
  void _startNewsTickerTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_urgentNewsList.isNotEmpty && _pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _urgentNewsList.length) {
          nextPage = 0; 
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  // 💡 الدالة المُعدلة لضمان الخروج القاطع
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final lastPressed = _lastPressed;
    
    const exitDuration = Duration(seconds: 2); 

    if (lastPressed == null || now.difference(lastPressed) > exitDuration) {
      _lastPressed = now; 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'اضغط مرة أخرى للخروج ', 
            textAlign: TextAlign.center, 
            style: TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold),
          ),
          duration: exitDuration,
          backgroundColor: AppColors.primaryBlue, 
          behavior: SnackBarBehavior.floating, 
          
          margin: const EdgeInsets.only(bottom: 20, left: 60, right: 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), 
        ),
      );
      
      return false; // منع الخروج
    }
    
    // 💥 عند الضغطة الثانية، نستخدم SystemNavigator.pop لطلب الخروج من النظام مباشرة
    SystemNavigator.pop();
    // نرجع true للسماح لـ WillPopScope بالعمل، لكن النظام سينتهي فعلياً عبر pop()
    return true; 
  }


  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return WillPopScope( 
      onWillPop: _onWillPop,
      child: Directionality( 
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          
          // 1. الـ AppBar (شريط التطبيق العلوي)
          appBar: AppBar(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            automaticallyImplyLeading: false,
            // 🛑 تطبيق الأيقونة المتحركة (النبض)
            leading: Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () {
                    // فتح الدرج الجانبي يدوياً
                    Scaffold.of(context).openDrawer(); 
                  },
                  // 🚀 استخدام ScaleTransition لتطبيق تأثير النبض/الحجم
                  icon: ScaleTransition(
                    scale: _pulseAnimation, // استخدام متحكم النبض
                    child: const Icon(
                      Icons.dashboard_rounded, 
                      color: AppColors.secondaryGold,
                      size: 28, // حجم أكبر لجعل النبض أوضح
                    ),
                  ),
                );
              },
            ),
            actions: [
              // زر الإشعارات 
              IconButton(
                icon: const Icon(Icons.notifications, color: AppColors.secondaryGold),
                onPressed: () {
                   Navigator.pushNamed(context, NotificationsPage.routeName);
                },
              ),
            ],
          ),
          // 2. الـ Drawer 
          drawer: const AppDrawer(),
          
          // 3. جسم الصفحة (Body)
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoadingVerse = true;
                _isLoadingNews = true;
              });
              await _getDailyVerse();
              await _fetchNewsData(); 
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // أ. بانر آية اليوم
                _buildVerseOfTheDay(),
                
                const SizedBox(height: 20),
                
                // ب. شريط الأخبار العاجلة (News Ticker) 
                _buildNewsTicker(),

                const SizedBox(height: 20),
                
                // ج. أزرار الوصول السريع (Quick Access)
                _buildQuickActionsGrid(context),

                const SizedBox(height: 20),
                
                // هـ. أحدث أخبار الكنيسة (3 أخبار عادية)
                 Text(' أخبار الكنيسة بأختصار',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                _buildLatestNewsSection(context),

                // زر عرض المزيد للأخبار
                if (_latestNews.isNotEmpty || _urgentNewsList.isNotEmpty || _hasFetchError)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/news'); 
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('عرض كل الأخبار كامله', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. آية اليوم (Widget)
  Widget _buildVerseOfTheDay() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '💫 آية اليوم',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.secondaryGold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _isLoadingVerse
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryGold, strokeWidth: 2))
              : Text(
                  _dailyVerse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryGold,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }
  
  // 2. شريط الأخبار العاجلة (News Ticker)
  Widget _buildNewsTicker() {
    
    if (_isLoadingNews) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.alertRed.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const LinearProgressIndicator(color: AppColors.secondaryGold),
      );
    }
    
    if (_urgentNewsList.isEmpty) { 
        return const SizedBox.shrink(); 
    }

    // بناء الشريط العاجل
    return Container(
      height: 60, 
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.alertRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.secondaryGold, size: 22),
          const SizedBox(width: 8),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _urgentNewsList.length,
              itemBuilder: (context, index) {
                final post = _urgentNewsList[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الاخبار العاجله: ${post.title}',
                    style: const TextStyle(color: AppColors.secondaryGold, fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, 
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          
          // زر للتمرير يظهر فقط إذا كان هناك أكثر من خبر واحد (يمكن الاعتماد على التمرير التلقائي الآن)
          if (_urgentNewsList.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: InkWell(
                onTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeIn,
                  );
                },
                child: const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryGold, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // 3. أزرار الوصول السريع 
  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 1.8, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: quickActions.length,
      itemBuilder: (context, index) {
        final action = quickActions[index];
        return InkWell(
          onTap: () {
             if (action['route'] != null) {
                Navigator.pushNamed(context, action['route'] as String);
              }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(action['icon'] as IconData, color: AppColors.primaryBlue, size: 30),
                const SizedBox(height: 8),
                Text(
                  action['title'] as String,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  

  // 4. أحدث الأخبار العادية 
  Widget _buildLatestNewsSection(BuildContext context) {
    if (_isLoadingNews) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    
    // معالجة خطأ الجلب
    if (_hasFetchError) {
      return Column(
        children: [
          const Text('❌ حدث خطأ أثناء جلب الأخبار من الخادم.', style: TextStyle(color: Colors.red, fontSize: 16)),
          TextButton(
            onPressed: _fetchNewsData, 
            child: const Text('أعد المحاولة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    
    // عرض رسالة في حالة عدم وجود أخبار
    if (_latestNews.isEmpty) {
      return const Center(child: Text('لا توجد أخبار كنسية لعرضها حالياً.'));
    }

    return Column(
      children: _latestNews.map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: AppColors.cardColor, 
            child: ListTile(
              leading: const Icon(Icons.article, color: AppColors.primaryBlue), 
              
              title: Text(post.title, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary), 
                textAlign: TextAlign.right,
              ),
              subtitle: Text(
                '${_formatDate(post.date)} - ${post.body}', 
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), 
                textAlign: TextAlign.right,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              onTap: () {
             Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsPage(), 
                    // تأكد أن NewsDetailsPage هو اسم الصفحة التي ستنشئها
                  ),
                );              },
            ),
          ),
        );
      }).toList(),
    );
  
  }
}