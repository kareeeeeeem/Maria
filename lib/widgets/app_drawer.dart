import 'package:churchapp/aus/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. استيراد Firebase Auth
import '../const/constants.dart';

// نحولها إلى StatefulWidget للتعامل مع StreamBuilder و Firebase
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // قائمة جميع الأقسام في الدرور (تبقى كما هي)
  final List<Map<String, dynamic>> drawerItems = const [
    {'title': ' الصفحة الرئيسية', 'icon': Icons.home, 'route': '/HomePage'},
    {'title': ' القداسات والعشيات', 'icon': Icons.church, 'route': '/masses'},

    {'title': ' الخمس خبزات وسمكتين', 'icon': Icons.restaurant, 'route': '/StorePage'},
    {'title': ' المكتبه', 'icon': Icons.library_add, 'route': '/InventoryPage'},

    {'title': 'مدارس الاحد', 'icon': Icons.church_sharp, 'route': '/SundaySchoolPage'},
    {'title': ' الاجتماعات الأسبوعية', 'icon': Icons.people, 'route': '/meetings'},
    {'title': ' الأنشطة والفعاليات', 'icon': Icons.event_note, 'route': '/activities'},
    {'title': ' الأخبار والإعلانات', 'icon': Icons.newspaper, 'route': '/news'},
    {'title': ' الافتقاد والخدمة', 'icon': Icons.handshake, 'route': '/service'},
    {'title': ' مطور التطبيق', 'icon': Icons.developer_board, 'route': '/ProfileSkeleton'},
    {'title': ' ارسال الاشعارات', 'icon': Icons.notification_add_outlined, 'route': '/AdminNotificationPage'},


    // {'title': ' الإعدادات', 'icon': Icons.settings, 'route': '/settings'},
    //{'title': ' بيانات الكنيسة', 'icon': Icons.info, 'route': '/about'},
    //{'title': ' لوحة الإدارة', 'icon': Icons.admin_panel_settings, 'route': '/admin', }, 
  ];

  @override
  Widget build(BuildContext context) {
    // 3. استخدام StreamBuilder للاستماع لتغير حالة المصادقة
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // حالة المستخدم: إذا كان snapshot.hasData أو snapshot.data ليس null
        final bool isLoggedIn = snapshot.hasData;
        final User? user = snapshot.data;
        // TODO: يجب ربطisAdmin بدور المستخدم من Firestore
        final bool isAdmin = false; 

        return Drawer(
          backgroundColor: AppColors.cardColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // 4. Header of the Drawer - يتغير بناءً على حالة تسجيل الدخول
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // عند الضغط على الهيدر، انتقل لصفحة البروفايل أو الدخول
                  if (!isLoggedIn) {
                    Navigator.pushNamed(context, '/login'); 
                  } else {
                    Navigator.pushNamed(context, '/profile');
                  }
                },
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.secondaryGold,
                        // عرض صورة المستخدم أو أيقونة افتراضية
                        backgroundImage: user?.photoURL != null 
                            ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null ? 
                             const Icon(Icons.person, size: 30, color: AppColors.primaryBlue) 
                             : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLoggedIn ? (user?.displayName ?? 'أهلاً بك يا خادم') : 'أهلاً بك يا زائر',
                        style: const TextStyle(color: AppColors.secondaryGold, fontSize: 18),
                      ),
                      Text( 
                        isLoggedIn ? (user?.email ?? 'مُسجَّل الدخول') : 'اضغط للتسجيل',
                        style: const TextStyle(color: AppColors.secondaryGold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              // عرض عناصر الدرور
              ...drawerItems.map((item) {
                // شرط لإخفاء لوحة الإدارة
                if (item['isAdmin'] == true && !isAdmin) {
                  return const SizedBox.shrink(); 
                }
                // شرط لإخفاء ملفي الشخصي والإعدادات إذا لم يكن مسجل دخول
                if (!isLoggedIn && (item['route'] == '/profile' || item['route'] == '/settings')) {
                   return const SizedBox.shrink();
                }

                return ListTile(
                  leading: Icon(item['icon'] as IconData, color: AppColors.primaryBlue),
                  title: Text(item['title'] as String,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.pushNamed(context, item['route'] as String); 
                  },
                );
              }).toList(),

              const Divider(),

              // 5. زر تسجيل الدخول/الخروج - يعتمد على حالة isLoggedIn
              ListTile(
                leading: Icon(isLoggedIn ? Icons.logout : Icons.login, color: Colors.red),
                title: Text(isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
                    style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  
                  if (isLoggedIn) {
                    // عملية الخروج
                    await AuthService().signOut();
                    // الانتقال إلى شاشة الدخول (أو الصفحة الرئيسية) بعد الخروج
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', 
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    // عملية الدخول
                    Navigator.pushNamed(context, '/login'); 
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}