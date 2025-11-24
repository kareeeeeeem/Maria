// lib/screens/donation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للنسخ
import 'package:url_launcher/url_launcher.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E);
  static const Color secondaryGold = Color(0xFFFFF8E1);
  static const Color cardColor = Colors.white;
}

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  final String donationNumber = '01004632660';

  Future<void> _donateNow(BuildContext context, String category) async {
    // نسخ الرقم تلقائيًا
    await Clipboard.setData(ClipboardData(text: donationNumber));

    // نافذة تأكيد
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.cardColor,
        title: const Text(
          '📋 تم نسخ رقم التبرع',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
'.يمكنك التبرع من أي جهة أو طريقة مناسبة لك\n\n'
'.الرب يبارك عطاياك ويكافئ تعب محبتك\n\n'
'الرقم: $donationNumber'
,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
           
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'title': '🤲 الأيتام',
        'verse': '«الدِّينُ الطَّاهِرُ النَّقِيُّ عِنْدَ اللهِ الآبِ، هُوَ: افْتِقَادُ الْيَتَامَى وَالأَرَامِلِ» (يعقوب ١:٢٧)',
        'icon': Icons.child_care_rounded,
      },
      {
        'title': '💊 المرضى',
        'verse': '«كُنْتُ مَرِيضًا فَزُرْتُمُونِي» (متى ٢٥:٣٦)',
        'icon': Icons.local_hospital_rounded,
      },
      {
        'title': '⛪ بناء الكنيسة',
        'verse': '«فَكُلُّ بَيْتٍ يُبْنَى مِنْ شَخْصٍ، وَلكِنَّ بَانِي الْكُلِّ هُوَ اللهُ» (عبرانيين ٣:٤)',
        'icon': Icons.church_rounded,
      },
      {
        'title': '🎓 التعليم الكنسي',
        'verse': '«رَبِّ الْوَلَدَ فِي طَرِيقِهِ فَمَتَى شَاخَ أَيْضًا لاَ يَحِيدُ عَنْهُ» (أمثال ٢٢:٦)',
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': '👨‍👩‍👧 الأسر المحتاجة',
        'verse': '«مَنْ لَهُ مَعِيشَةُ الْعَالَمِ، وَنَظَرَ أَخَاهُ مُحْتَاجًا، وَأَغْلَقَ أَحْشَاءَهُ عَنْهُ، فَكَيْفَ تَثْبُتُ مَحَبَّةُ اللهِ فِيهِ؟» (١ يوحنا ٣:١٧)',
        'icon': Icons.family_restroom_rounded,
      },

 {
        'title': '📚 مدارس الاحد',
        'verse': '«دعوا الأطفال يأتون إليّ، ولا تمنعوهم، لأن لمثل هؤلاء ملكوت الله» (مرقس ١٠:١٤)',
        'icon': Icons.family_restroom_rounded,
      },

      {
        'title': '⛪ خدمة الشباب',
        'verse': '«كَلِمَةُ اللهِ تَثْبُتُ فِيكُمْ وَقَدْ غَلَبْتُمُ الشِّرِّيرَ» (١ يوحنا ٢:١٤)',
        'icon': Icons.people_alt_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('❤️ صفحة التبرعات', style: TextStyle(color: AppColors.secondaryGold)),
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          return Card(
            color: AppColors.cardColor,
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: Icon(item['icon'], color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['title'],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['verse'],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () => _donateNow(context, item['title']),
                    icon: const Icon(Icons.volunteer_activism_rounded, color: AppColors.secondaryGold),
                    label: const Text(
                      'تبرع الآن',
                      style: TextStyle(color: AppColors.secondaryGold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
