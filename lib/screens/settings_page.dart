// import 'package:flutter/material.dart';

// // =========================================================
// // I. نموذج البيانات والثوابت
// // =========================================================

// // 1. إعادة تعريف AppColors (للتكامل)
// class AppColors {
//   static const Color primaryBlue = Color(0xFF4E342E); 
//   static const Color secondaryGold = Color(0xFFFFF8E1); 
//   static const Color backgroundColor = Color(0xFFF5F5F5); 
//   static const Color cardColor = Colors.white;
//   static const Color textPrimary = Color(0xFF212121);
//   static const Color textSecondary = Color(0xFF757575);
// }

// // =========================================================
// // II. الصفحة الرئيسية (SettingsPage)
// // =========================================================

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   // حالات وهمية لحفظ الإعدادات
//   bool _notificationsEnabled = true;
//   bool _darkModeEnabled = false;
//   String _selectedLanguage = 'العربية';

//   // دالة وهمية لفتح الاتصال بالدعم
//   void _contactSupport(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('جاري فتح نموذج التواصل مع الدعم...')),
//     );
//     // TODO: تنفيذ فتح البريد الإلكتروني أو نموذج الدعم
//   }

//   // دالة وهمية لإرسال اقتراح
//   void _sendSuggestion(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('جاري فتح نموذج إرسال الاقتراحات...')),
//     );
//     // TODO: تنفيذ فتح صفحة إرسال الاقتراحات
//   }

//   // دالة لعرض مربع حوار اختيار اللغة
//   void _showLanguageDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('اختيار اللغة', textAlign: TextAlign.right),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildLanguageOption(context, 'العربية'),
//               _buildLanguageOption(context, 'English'),
//             ],
//           ),
//         );
//       },
//     );
//   }
  
//   // ويدجت خيار اللغة داخل مربع الحوار
//   Widget _buildLanguageOption(BuildContext context, String lang) {
//     return RadioListTile<String>(
//       title: Text(lang, textAlign: TextAlign.right),
//       value: lang,
//       groupValue: _selectedLanguage,
//       onChanged: (String? value) {
//         if (value != null) {
//           setState(() {
//             _selectedLanguage = value;
//           });
//           Navigator.of(context).pop();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('تم تغيير اللغة إلى $value.')),
//           );
//           // TODO: تنفيذ وظيفة تغيير لغة التطبيق
//         }
//       },
//       activeColor: AppColors.primaryBlue,
//       controlAffinity: ListTileControlAffinity.trailing,
//     );
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         title: const Text('⚙️ الإعدادات', style: TextStyle(color: AppColors.secondaryGold)),
//         backgroundColor: AppColors.primaryBlue,
//         elevation: 0,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: <Widget>[
//           // 1. إعدادات الحساب والتطبيق
//           _buildSettingsSection(
//             title: 'تخصيص التطبيق',
//             children: [
//               // تفعيل/إيقاف الإشعارات
//               _buildSwitchSetting(
//                 title: 'تفعيل الإشعارات',
//                 subtitle: 'استقبال تنبيهات بالأخبار العاجلة ومواعيد القداسات.',
//                 icon: Icons.notifications_active_rounded,
//                 value: _notificationsEnabled,
//                 onChanged: (newValue) {
//                   setState(() {
//                     _notificationsEnabled = newValue;
//                   });
//                 },
//               ),

//               // اختيار اللغة
//               _buildListSetting(
//                 title: 'اختيار اللغة',
//                 subtitle: _selectedLanguage,
//                 icon: Icons.language_rounded,
//                 onTap: () => _showLanguageDialog(context),
//               ),

//               // الوضع الليلي (Dark Mode)
//               _buildSwitchSetting(
//                 title: 'الوضع الليلي (Dark Mode)',
//                 subtitle: 'تفعيل الوضع الداكن لراحة العين.',
//                 icon: Icons.dark_mode_rounded,
//                 value: _darkModeEnabled,
//                 onChanged: (newValue) {
//                   setState(() {
//                     _darkModeEnabled = newValue;
//                   });
//                   // TODO: تنفيذ وظيفة تغيير الثيم (Theme)
//                 },
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 25),

//           // 2. الدعم والمساعدة
//           _buildSettingsSection(
//             title: 'المساعدة والدعم',
//             children: [
//               // تواصل مع الدعم
//               _buildListSetting(
//                 title: 'تواصل مع الدعم الفني',
//                 subtitle: 'لحل المشاكل التقنية واستفسارات التطبيق.',
//                 icon: Icons.support_agent_rounded,
//                 onTap: () => _contactSupport(context),
//               ),

//               // إرسال اقتراح
//               _buildListSetting(
//                 title: 'إرسال اقتراح / ملاحظة',
//                 subtitle: 'نرحب باقتراحاتكم لتطوير التطبيق.',
//                 icon: Icons.lightbulb_outline_rounded,
//                 onTap: () => _sendSuggestion(context),
//               ),

//               // معلومات التطبيق (وهمية)
//                _buildListSetting(
//                 title: 'حول التطبيق',
//                 subtitle: 'الإصدار 1.0.0. سياسة الخصوصية.',
//                 icon: Icons.info_outline_rounded,
//                 onTap: () {
//                   // يمكن عرض مربع حوار بسيط لمعلومات التطبيق
//                   showAboutDialog(
//                     context: context,
//                     applicationName: 'Church App',
//                     applicationVersion: '1.0.0',
//                     applicationLegalese: '© 2025 All Rights Reserved.',
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // III. الويدجت المساعدة (Helper Widgets)
//   // =========================================================

//   // ويدجت لإنشاء قسم الإعدادات (البطاقة الرئيسية)
//   Widget _buildSettingsSection({required String title, required List<Widget> children}) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primaryBlue,
//                 ),
//                 textAlign: TextAlign.right,
//               ),
//             ),
//             const Divider(color: AppColors.backgroundColor, thickness: 1, height: 1),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   // ويدجت لإعداد التبديل (Switch Setting)
//   Widget _buildSwitchSetting({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required bool value,
//     required ValueChanged<bool> onChanged,
//   }) {
//     return SwitchListTile(
//       title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500)),
//       subtitle: Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondary)),
//       value: value,
//       onChanged: onChanged,
//       secondary: Icon(icon, color: AppColors.primaryBlue),
//       activeColor: AppColors.primaryBlue,
//       tileColor: AppColors.cardColor,
//       isThreeLine: true,
//       controlAffinity: ListTileControlAffinity.leading, // وضع زر التبديل على اليسار
//     );
//   }

//   // ويدجت لإعداد القائمة (List Setting)
//   Widget _buildListSetting({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500)),
//       subtitle: Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondary)),
//       leading: Icon(icon, color: AppColors.primaryBlue),
//       trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
//       onTap: onTap,
//       tileColor: AppColors.cardColor,
//     );
//   }
// }