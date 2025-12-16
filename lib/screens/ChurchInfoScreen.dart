import 'dart:ui';
import 'package:flutter/material.dart';

//========================================================================
// 1. App Colors & Data Structure (محدث)
//========================================================================

class AppColors {
  // الألوان التي أرسلتها
  static const Color primaryBlue = Color(0xFF4E342E); // البني الداكن
  static const Color secondaryGold = Color(0xFFFFF8E1); // الذهبي الفاتح
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFE53935);
  
  // ألوان إضافية للدعم
  static const Color primaryDark = primaryBlue;       
  static const Color accentColor = secondaryGold;     
  static const Color primaryColor1 = primaryBlue;     
  static const Color whiteColor = cardColor;         
  static const Color fieldFillColor = Color(0xFF5D4037); 
}

class ChurchData {
  final String name;
  final String address;
  final String description;
  final IconData icon;
  final Color color;
  final String founder;            
  
  ChurchData({
    required this.name,
    required this.address,
    required this.description,
    required this.icon,
    required this.color,
    required this.founder,
  });
}

// البيانات المجمعة للكنيستين (مع تصحيح أيقونة العذراء)
final List<ChurchData> churches = [
  ChurchData(
    name: 'كنيسة القديس نيقولاوس ببنها',
    address: 'الشهيد عادل إبراهيم أبو سينا، قسم بنها، بنها',
    description:
        'تُعد كنيسة القديس نيقولاوس (مارنيقولا) في بنها منارة روحية وتاريخية في الإيبارشية. تأسست كمركز عبادة لخدمة الأسر القبطية في المنطقة، وتحمل اسم شفيع البحارة والمسافرين. تتميز الكنيسة بقداساتها الدورية، بالإضافة إلى اجتماعات دراسة الكتاب المقدس والخدمات الاجتماعية النشطة التي تخدم شريحة واسعة من المجتمع. تشتهر الكنيسة بتصميمها المعماري الذي يمزج بين العمارة القبطية التقليدية والعناصر الحديثة، مما يجعلها مكاناً مثالياً للصلاة والتأمل. كما تقام فيها احتفالات سنوية كبرى بعيد القديس نيقولاوس في ديسمبر.',
    icon: Icons.church,
    color: AppColors.secondaryGold,
    founder: 'تم تجديدها وتوسيعها في منتصف القرن العشرين.', 
  ),
  ChurchData(
    name: 'كنيسة السيدة العذراء مريم ببنها',
    address: 'سعد زغلول، قسم بنها، بنها',
    description:
        'هي الكنيسة الأم والأقدم في بنها، وهي مركز روحي له تاريخ طويل يمتد لعدة قرون. تقع في قلب المدينة وتعتبر مزاراً مهماً لكل الأقباط. سُميت باسم القديسة العذراء، والدة الإله، وتحتوي على أيقونات تاريخية نادرة. بالإضافة إلى القداسات المنتظمة، تشتهر الكنيسة بخدمة افتقاد متكاملة، ودورها الحيوي في رعاية الشباب والأنشطة الكشفية. تقام بها صلوات التمجيد الخاصة بالعذراء كل شهر في كيهك، مما يجعلها مركزاً حقيقياً للإيمان والخدمة في بنها.',
    icon: Icons.brightness_high, // تم تصحيح الأيقونة
    color: AppColors.secondaryGold.withOpacity(0.8),
    founder: 'يرجع تاريخها للقرن التاسع عشر وتعتبر أقدم كنيسة بالمدينة.',
  ),
];


//========================================================================
// 2. شاشة معلومات الكنائس (ChurchInfoScreen)
//========================================================================

class ChurchInfoScreen extends StatelessWidget {
  static const String routeName = '/church_info';
  const ChurchInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('معلومات عن كنائس بنها', style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             
            
            // بناء بطاقة لكل كنيسة
            ...churches.map((church) => _buildChurchCard(context, church)).toList(),
            
            const SizedBox(height: 30),
            
            // 🔄 الترتيب الجديد: سيرة السيدة العذراء أولاً
            _buildVirginMarySection(),
            
            // سيرة القديس نيقولاوس ثانياً
            _buildSaintNicholasSection(),
            
          ],
        ),
      ),
    );
  }

  //========================================================================
  // 3. مكونات الشاشة (Widgets)
  //========================================================================

  Widget _buildChurchCard(BuildContext context, ChurchData church) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.fieldFillColor.withOpacity(0.9), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: church.color, width: 3),
          boxShadow: [
            BoxShadow(
              color: church.color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(church.icon, color: church.color, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    church.name,
                    style: TextStyle(
                      color: church.color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.whiteColor, height: 25),
            
            // الوصف
            Text(
              church.description,
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 15),

            // العنوان
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppColors.whiteColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    church.address,
                    style: TextStyle(
                      color: AppColors.whiteColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // الدالة المساعدة _buildDetailSection لم تعد مستخدمة في بطاقة الكنيسة، لكن تم الحفاظ عليها للاستخدام في سير القديسين.
  Widget _buildDetailSection(IconData icon, String title, String value, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 26.0, top: 4.0),
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.whiteColor, 
                fontSize: 14, 
                height: 1.4),
          ),
        ),
      ],
    );
  }


  
  // دالة لسيرة السيدة العذراء مريم
  Widget _buildVirginMarySection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 30), // ⚠️ تم تغيير الهامش السفلي ليسبق نيقولاوس
      decoration: BoxDecoration(
        color: AppColors.primaryColor1.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accentColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '👑 سيرة السيدة العذراء مريم 👑',
            style: TextStyle(
              color: AppColors.accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'السيدة العذراء مريم، والدة الإله، هي أعظم القديسات وأكرم من الكاروبيم والسيرابيم. وُلدت من القديسين يواقيم وحنة، وخدمت في الهيكل منذ طفولتها. باختيار إلهي فريد، صارت العروس الطاهرة التي حملت المسيح، كلمة الله المتجسد، لخلاص العالم. عاشت العذراء حياة ملؤها الطاعة والاتكال والصمت والتأمل. يكرّمها الأقباط في شهر كيهك ويصومون صومها الشهير. هي دائمة الشفاعة لأجل البشرية.',
            style: const TextStyle(
                color: AppColors.whiteColor, 
                fontSize: 15, 
                height: 1.6,
                fontStyle: FontStyle.italic
            ),
            textAlign: TextAlign.justify,
          ),
          const Divider(color: AppColors.accentColor, height: 20),
          _buildDetailRow(Icons.face, 'أشهر ألقابها:', 'والدة الإله (ثيؤطوكوس)، العذراء الطاهرة.', AppColors.whiteColor),
          _buildDetailRow(Icons.favorite, 'عيد النياحة:', '21 طوبة (يناير)، وهو يوم صعود جسدها للسماء.', AppColors.whiteColor),
        ],
      ),
    );
  }

  Widget _buildSaintNicholasSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      // ⚠️ تم حذف الهامش العلوي لأنه الآن يتبع قسم العذراء مباشرة
      decoration: BoxDecoration(
        color: AppColors.primaryColor1.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accentColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '🌟 سيرة القديس نيقولاوس أسقف ميرة (مارنيقولا) 🌟',
            style: TextStyle(
              color: AppColors.accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'القديس نيقولاوس أسقف ميرة، المعروف بـ "سانتا كلوز" الحديث، هو قديس عظيم من القرن الرابع الميلادي. وُلد في آسيا الصغرى (تركيا حالياً) واشتهر بكرمه السري وعمله للعجائب. أهم القصص عنه هي إنقاذه لثلاث فتيات فقيرات من الزواج القسري عن طريق إلقاء أكياس من الذهب لهن في الليل. كان مدافعاً قوياً عن الإيمان الأرثوذكسي وحضر مجمع نيقية. تذكار نياحته هو 6 ديسمبر.',
            style: TextStyle(
                color: AppColors.whiteColor, 
                fontSize: 15, 
                height: 1.6,
                fontStyle: FontStyle.italic
            ),
            textAlign: TextAlign.justify,
          ),
          const Divider(color: AppColors.accentColor, height: 20),
          
          _buildDetailRow(Icons.calendar_month, 'تاريخ النياحة:', '6 ديسمبر 343 م', AppColors.whiteColor),
          _buildDetailRow(Icons.local_library, 'أشهر قصة:', 'إنقاذه لبنات الرجل الفقير (أصل بابا نويل).', AppColors.whiteColor),
          _buildDetailRow(Icons.directions_boat, 'شفيع:', 'البحارة والمسافرين والأطفال.', AppColors.whiteColor),
        ],
      ),
    );
  }
  Widget _buildDetailRow(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}