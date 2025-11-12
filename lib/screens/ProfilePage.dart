import 'package:churchapp/aus/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:churchapp/aus/login/login_screen.dart';


// =========================================================
// I. نموذج البيانات والثوابت
// تم حذف النماذج والثوابت الخاصة بالحضور والطلبات لأنها لم تعد ضرورية
// =========================================================

// 1. إعادة تعريف AppColors (للتكامل)
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color statusVisited = Colors.green; // للحضور الناجح
}


// 4. البيانات الوهمية (للمستخدم)
const Map<String, String> _dummyUserInfo = {
  'name': 'أحمد إبراهيم جرجس',
  'phone': '01234567890',
  'serviceType': 'خادم منطقة أ / قائد اجتماع الشباب',
};

// =========================================================
// II. الصفحة الرئيسية (ProfilePage)
// =========================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // --------------------------------------------------------
  // دالة تسجيل الخروج (Sign Out Implementation)
  // --------------------------------------------------------
  Future<void> _signOut(BuildContext context) async {
    try {
      // 1. استدعاء دالة تسجيل الخروج من خدمة المصادقة
      await AuthService().signOut();
      
      // 2. إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الخروج بنجاح. نلقاك لاحقاً!')),
      );

      // 3. التوجيه إلى شاشة تسجيل الدخول ومسح جميع الشاشات السابقة
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserLoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // التعامل مع أي خطأ قد يحدث أثناء تسجيل الخروج
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('👤 صفحة المستخدم', style: TextStyle(color: AppColors.secondaryGold)),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. بيانات المستخدم الأساسية (البطاقة الوحيدة المطلوبة)
            _buildUserInfoCard(context),
            const SizedBox(height: 30),

            // 4. أزرار الإجراءات
          ],
        ),
      ),
    );
  }

  // =========================================================
  // III. الويدجت المساعدة (Helper Widgets)
  // =========================================================

  // ويدجت لبطاقة بيانات المستخدم
  Widget _buildUserInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0), // زيادة المساحة الداخلية
        child: Column(
          children: [
            // 🌟 صورة المستخدم
            const CircleAvatar(
              radius: 50, // حجم أكبر
              backgroundColor: AppColors.secondaryGold,
              child: Icon(Icons.person, size: 50, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 15),
            // 🌟 اسم المستخدم
            Text(
              _dummyUserInfo['name']!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary), // خط أكبر
            ),
            const Divider(height: 30, thickness: 1.5), // فاصل أوضح
            
            // 🌟 رقم الموبايل
            _buildDetailRow(Icons.phone_android, 'الموبايل:', _dummyUserInfo['phone']!),
            const SizedBox(height: 8),
            
            // 🌟 نوع الخدمة
            _buildDetailRow(Icons.work, 'نوع الخدمة:', _dummyUserInfo['serviceType']!),
          ],
        ),
      ),
    );
  }

  // ويدجت لسطر تفصيلي
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 22), // أيقونة أكبر
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 16),
          ),
          const Spacer(), // للمساعدة في محاذاة النص لليمين
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.left, // محاذاة القيمة لليسار (باتجاه اليمين في العربية)
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت أزرار الإجراءات
  
}