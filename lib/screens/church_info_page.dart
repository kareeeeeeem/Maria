import 'package:flutter/material.dart';
// يتطلب إضافة حزمة url_launcher لتشغيل الروابط والأرقام (قم بإضافتها إلى pubspec.yaml)
// import 'package:url_launcher/url_launcher.dart'; 

// =========================================================
// I. نموذج البيانات والثوابت
// =========================================================

// إعادة تعريف AppColors (للتكامل)
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

// البيانات الأساسية للكنيسة
const String _churchHistory = 'تأسست الكنيسة عام 1950 وهي تخدم المجتمع الروحي والاجتماعي. نهدف إلى تقديم الرعاية الروحية لجميع الأعمار من خلال برامجنا المتعددة.';
const String _churchServices = 'القداسات الأسبوعية، دراسات الكتاب المقدس، اجتماعات الشباب والأسرة، خدمة الافتقاد، ومكتبة الكنيسة.';
const String _churchLeadership = 'يخدم الكنيسة ثلاثة كهنة رئيسيين والعديد من الخدام المتفرغين للمناطق والخدمات المتخصصة.';
const String _churchPhone = '+201012345678';
const String _churchEmail = 'info@churchname.org';
const String _churchFacebook = 'https://www.facebook.com/ChurchOfficialPage';
const String _churchGoogleMapsUrl = 'https://maps.app.goo.gl/YourChurchLocationLink'; // رابط لموقع الكنيسة على خرائط جوجل

// ساعات عمل السكرتارية
const String _secretaryHours = 'الأحد: 10 ص - 2 م\nالاثنين - الخميس: 9 ص - 4 م\nالجمعة: مغلق\nالسبت: 11 ص - 3 م';


// =========================================================
// II. الصفحة الرئيسية (ChurchInfoPage)
// =========================================================

class ChurchInfoPage extends StatelessWidget {
  const ChurchInfoPage({super.key});

  // دالة وهمية لفتح الروابط (تحتاج إلى حزمة url_launcher)
  void _launchURL(BuildContext context, String url, {bool isTel = false, bool isEmail = false}) async {
    String message;
    if (isTel) {
      message = 'جاري الاتصال بـ $url';
    } else if (isEmail) {
      message = 'جاري فتح البريد لإرسال رسالة إلى $url';
    } else {
      message = 'جاري فتح الرابط: $url';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⏳ $message')),
    );

    /*
    // الكود الحقيقي لـ url_launcher
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ تعذر فتح الرابط.')),
      );
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('🏡 بيانات الكنيسة', style: TextStyle(color: AppColors.secondaryGold)),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
                centerTitle: true,

      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. نبذة عن الكنيسة
            _buildInfoCard(
              context,
              title: '📜 نبذة تاريخية وخدمية',
              children: [
                _buildInfoRow(Icons.history, 'التاريخ:', _churchHistory),
                _buildInfoRow(Icons.volunteer_activism, 'الخدمات:', _churchServices),
                _buildInfoRow(Icons.people_alt, 'المسؤولون:', _churchLeadership),
              ],
            ),
            const SizedBox(height: 20),

            // 2. خريطة الوصول
            _buildLocationCard(context),
            const SizedBox(height: 20),

            // 3. أرقام التواصل والبريد والفيسبوك
            _buildContactCard(context),
            const SizedBox(height: 20),

            // 4. ساعات عمل المكتب والسكرتارية
            _buildHoursCard(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // III. الويدجت المساعدة (Helper Widgets)
  // =========================================================

  // ويدجت لإنشاء بطاقة تحتوي على مجموعة معلومات
  Widget _buildInfoCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
              textAlign: TextAlign.right,
            ),
            const Divider(color: AppColors.secondaryGold, thickness: 1.5, height: 20),
            ...children, // عرض قائمة الـ Widgets
          ],
        ),
      ),
    );
  }

  // ويدجت لسطر معلومة بسيط
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // نص القيمة
          Padding(
            padding: const EdgeInsets.only(right: 32.0), // إزاحة للنص
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت لبطاقة الموقع (خريطة جوجل)
  Widget _buildLocationCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📍 خريطة الوصول',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              textAlign: TextAlign.right,
            ),
            const Divider(color: AppColors.secondaryGold, thickness: 1.5, height: 20),
            
            // Placeholder للخريطة (يمكن استبدالها بـ GoogleMap Widget)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('هنا يتم عرض الخريطة المصغرة', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(height: 10),

            // زر فتح الخريطة
            ElevatedButton.icon(
              onPressed: () => _launchURL(context, _churchGoogleMapsUrl),
              icon: const Icon(Icons.directions_walk_rounded, color: AppColors.secondaryGold),
              label: const Text('افتح الموقع على خرائط جوجل', style: TextStyle(color: AppColors.secondaryGold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت لبطاقة التواصل
  Widget _buildContactCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              '📞 التواصل والشبكات الاجتماعية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              textAlign: TextAlign.right,
            ),
          ),
          const Divider(color: AppColors.secondaryGold, thickness: 1.5, indent: 16, endIndent: 16),

          // 1. رقم الهاتف
          ListTile(
            leading: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryBlue),
            title: const Text('رقم الهاتف الرئيسي', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text(_churchPhone, style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.call, color: Colors.green),
            onTap: () => _launchURL(context, 'tel:$_churchPhone', isTel: true),
          ),
          
          // 2. البريد الإلكتروني
          ListTile(
            leading: const Icon(Icons.email_rounded, color: AppColors.primaryBlue),
            title: const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text(_churchEmail, style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.send, color: AppColors.primaryBlue),
            onTap: () => _launchURL(context, 'mailto:$_churchEmail', isEmail: true),
          ),

          // 3. صفحة الفيسبوك
          ListTile(
            leading: const Icon(Icons.facebook, color: AppColors.primaryBlue),
            title: const Text('صفحة الفيسبوك الرسمية', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text(_churchFacebook, style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.open_in_new, color: Colors.blue),
            onTap: () => _launchURL(context, _churchFacebook),
          ),
        ],
      ),
    );
  }

  // ويدجت لساعات العمل
  Widget _buildHoursCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🕒 ساعات عمل المكتب والسكرتارية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              textAlign: TextAlign.right,
            ),
            Divider(color: AppColors.secondaryGold, thickness: 1.5, height: 20),
            Text(
              _secretaryHours,
              style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}