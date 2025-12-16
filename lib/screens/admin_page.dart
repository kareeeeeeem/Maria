import 'package:flutter/material.dart';

// =========================================================
// I. نموذج البيانات والثوابت
// =========================================================

// 1. إعادة تعريف AppColors (للتكامل)
class AppColors {
  static const Color primaryBlue = Color(0xFF1E88E5); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color adminDark = Color(0xFF37474F); // لون خاص بالإدارة
}

// 2. نموذج بيانات لوحة التحكم (لتسهيل إنشاء البطاقات)
class AdminFeature {
  final String title;
  final IconData icon;
  final Color color;

  const AdminFeature({
    required this.title,
    required this.icon,
    required this.color,
  });
}

// 3. قائمة الوظائف الإدارية المطلوبة
final List<AdminFeature> _adminFeatures = [
  const AdminFeature(
    title: 'إدارة المواعيد',
    icon: Icons.schedule,
    color: Color(0xFF26A69A), // Teal
  ),
  const AdminFeature(
    title: 'إرسال إشعارات',
    icon: Icons.notification_add,
    color: Color(0xFFEF5350), // Red
  ),
  const AdminFeature(
    title: 'مراجعة طلبات الافتقاد',
    icon: Icons.handshake,
    color: Color(0xFF66BB6A), // Green
  ),
  const AdminFeature(
    title: 'إدارة المستخدمين',
    icon: Icons.manage_accounts,
    color: Color(0xFFFFA726), // Orange
  ),
  const AdminFeature(
    title: 'تحليل الحضور',
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF42A5F5), // Light Blue
  ),
  const AdminFeature(
    title: 'تعديل الأخبار',
    icon: Icons.edit_note,
    color: Color(0xFFAB47BC), // Purple
  ),
];

// =========================================================
// II. الصفحة الرئيسية (AdminPage)
// =========================================================

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ⬅️ ملاحظة هامة: يجب إضافة فحص الصلاحيات هنا
    const bool isUserAdmin = true; // يتم استبدالها بفحص حقيقي (مثلاً: Firebase Auth Role Check)

    if (!isUserAdmin) {
      return const Scaffold(
        appBar:  _AdminAppBar(),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Text(
              '⚠️ ليس لديك الصلاحية الكافية للوصول إلى لوحة الإدارة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    
    // واجهة لوحة الإدارة للمستخدمين المصرح لهم
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const _AdminAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'لوحة تحكم الكنيسة (للخدام والكهنة)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.adminDark,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(color: AppColors.primaryBlue, thickness: 2, indent: 40, endIndent: 40, height: 25),

            // عرض الوظائف في شبكة
            GridView.builder(
              shrinkWrap: true, // مهم ليعمل داخل SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // لمنع التمرير المزدوج
              itemCount: _adminFeatures.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // عمودين
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.25, // نسبة العرض إلى الارتفاع
              ),
              itemBuilder: (context, index) {
                return _AdminFeatureCard(feature: _adminFeatures[index]);
              },
            ),
            
            const SizedBox(height: 30),
            
            // منطقة إحصائيات سريعة
            _buildQuickStatsCard(),
          ],
        ),
      ),
    );
  }

  // ويدجت لعرض إحصائيات سريعة
  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📈 إحصائيات سريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.adminDark),
              textAlign: TextAlign.right,
            ),
            const Divider(color: AppColors.secondaryGold, thickness: 1.5, height: 15),
            _buildStatRow('إجمالي المستخدمين المسجلين:', '1,560', Icons.group),
            _buildStatRow('طلبات الافتقاد الجديدة:', '5 طلبات', Icons.new_releases_rounded),
            _buildStatRow('آخر قداس تم إضافته:', 'قداس الأحد القادم', Icons.access_time_filled),
          ],
        ),
      ),
    );
  }

  // ويدجت لصف الإحصائية
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminDark),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// شريط التطبيق الخاص بالإدارة (_AdminAppBar)
// ---------------------------------------------------------

class _AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AdminAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('لوحة الإدارة', style: TextStyle(color: AppColors.secondaryGold)),
      backgroundColor: AppColors.adminDark,
      iconTheme: const IconThemeData(color: AppColors.secondaryGold),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('إعدادات المسؤول...')),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


// ---------------------------------------------------------
// بطاقة وظيفة الإدارة (_AdminFeatureCard)
// ---------------------------------------------------------

class _AdminFeatureCard extends StatelessWidget {
  final AdminFeature feature;
  const _AdminFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: feature.color.withOpacity(0.9), // استخدام لون مميز للبطاقة
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('جاري فتح صفحة: ${feature.title}')),
          );
          // TODO: تنفيذ الانتقال إلى شاشة الإدارة المحددة
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                feature.icon,
                size: 40,
                color: AppColors.secondaryGold,
              ),
              const SizedBox(height: 10),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}