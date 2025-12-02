import 'package:churchapp/aus/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../const/constants.dart'; // افترض وجود هذا الملف

// نحولها إلى StatefulWidget للتعامل مع جلب البيانات من Firestore
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // 🔒 متغير لتخزين حالة الأدمن العام
  bool _isAdmin = false;
  // 📌 متغير لتخزين حالة مدير مدارس الأحد
  bool _isSchoolManager = false; 
  // 🧭 متغير لتخزين حالة مدير شؤون المفقودين
  bool _isMissingPersonManager = false; 
  // 🔔 متغير لتخزين حالة مرسل الإشعارات الجديد
  bool _isNotificationSender = false; 
  // 🧑‍💻 متغير لتخزين معلومات إضافية للمستخدم (مثل الاسم الكامل أو الدور)
  Map<String, dynamic>? _userExtraData;
  
  // 📌 قائمة جميع الأقسام في الدرور
  final List<Map<String, dynamic>> drawerItems = const [

        {'title': 'الإنجيل', 'icon': Icons.menu_book, 'route': '/bible', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
        // {'title': 'الأجبية', 'icon': Icons.brightness_3, 'route': '/agpeya', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},

    // {'title': ' الصفحة الرئيسية', 'icon': Icons.home, 'route': '/HomePage', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' القداسات والعشيات', 'icon': Icons.church, 'route': '/masses', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' الخمس خبزات وسمكتين', 'icon': Icons.restaurant, 'route': '/StorePage', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' الاجتماعات الأسبوعية', 'icon': Icons.people, 'route': '/meetings', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' الأنشطة والرحلات', 'icon': Icons.event_note, 'route': '/activities', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' الأخبار والإعلانات', 'icon': Icons.newspaper, 'route': '/news', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' المكتبه', 'icon': Icons.library_add, 'route': '/InventoryPage', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' الافتقاد', 'icon': Icons.handshake, 'route': '/service', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},
    {'title': ' مطور التطبيق', 'icon': Icons.developer_board, 'route': '/HowUsViewPage', 'requiresAuth': false, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false}, 
    {'title': ' مدارس الاحد', 'icon': Icons.school_outlined, 'route': '/SundaySchoolHome', 'requiresAuth': true, 'requiresAdmin': false, 'requiresSchoolManager': true, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false}, 
    
    // 🔔 عنصر إرسال الاشعارات: يتطلب إما المدير العام أو مرسل الإشعارات (تم التعديل هنا)
   {'title': ' ارسال الاشعارات', 'icon': Icons.notification_add_outlined, 'route': '/AdminNotificationPage', 'requiresAuth': true, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': true},
  
    // 🔍 عنصر سجل طلبات الافتقاد: يتطلب إما المدير العام أو مدير شؤون المفقودين
    {'title': 'سجل طلبات الافتقاد', 'icon': Icons.home_mini, 'route': '/AdminRequestsPage', 'requiresAuth': true, 'requiresAdmin': false, 'requiresSchoolManager': false, 'requiresMissingPersonManager': true, 'requiresNotificationSender': false},
  
   
   // ⛪ عنصر سجل الكنيسة: يتطلب المدير العام فقط
   {'title': ' سجل الكنيسه', 'icon': Icons.people_alt, 'route': '/VisitationScreen', 'requiresAuth': true, 'requiresAdmin': true, 'requiresSchoolManager': false, 'requiresMissingPersonManager': false, 'requiresNotificationSender': false},

  
  ];

  @override
  void initState() {
    super.initState();
    // 💡 الاستماع لحالة المصادقة لبدء جلب بيانات Firestore
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserRole(user.uid);
      } else {
        // إعادة تعيين الحالة عند الخروج
        setState(() {
          _isAdmin = false;
          _isSchoolManager = false; 
          _isMissingPersonManager = false; 
          _isNotificationSender = false; // إعادة تعيين الدور الجديد
          _userExtraData = null;
        });
      }
    });
  }

  // 🔒 دالة جلب دور المستخدم من Firestore
  Future<void> _fetchUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          // تحديث حالة الأدمن العام
          _isAdmin = data['isAdmin'] == true; 
          
          // 📌 جلب حالة مدير مدارس الأحد
          _isSchoolManager = data['isSchoolManager'] == true; 
          
          // 🧭 جلب حالة مدير شؤون المفقودين
          _isMissingPersonManager = data['isMissingPersonManager'] == true; 

          // 🔔 جلب حالة مرسل الإشعارات
          _isNotificationSender = data['isNotificationSender'] == true;
          
          _userExtraData = data;
        });
        print('User $uid Roles: isAdmin=$_isAdmin, isSchoolManager=$_isSchoolManager, isMissingPersonManager=$_isMissingPersonManager, isNotificationSender=$_isNotificationSender');
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  // 5. دالة بناء الهيدر بناءً على حالة المستخدم
  Widget _buildDrawerHeader(BuildContext context, User? user, bool isLoggedIn) {
    String fullName = isLoggedIn 
        ? (_userExtraData?['fullName'] ?? user?.displayName ?? 'أهلاً بك يا خادم')
        : 'أهلاً بك يا زائر';
    
    String name;
    
    // 🔴 منطق عرض أول اسمين فقط
    if (isLoggedIn) {
      // إزالة المسافات الزائدة وتقسيم الاسم الكامل إلى قائمة كلمات
      final nameParts = fullName.trim().split(RegExp(r'\s+'));
      
      if (nameParts.length >= 2) {
        // إذا كان هناك اسمان أو أكثر: نأخذ الأول والثاني
        name = '${nameParts[0]} ${nameParts[1]}';
      } else if (nameParts.isNotEmpty) {
        // إذا كان هناك اسم واحد فقط
        name = nameParts[0];
      } else {
        // في حالة الاسم فارغ لسبب ما، نستخدم النص الافتراضي
        name = 'أهلاً بك يا خادم';
      }
    } else {
      // حالة الزائر
      name = 'أهلاً بك يا زائر';
    }
    
    String emailOrStatus = isLoggedIn 
        ? (user?.email ?? 'مُسجَّل الدخول') 
        : 'اضغط للتسجيل';
        

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
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
              backgroundImage: user?.photoURL != null 
                  ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? 
                   const Icon(Icons.person, size: 30, color: AppColors.primaryBlue) 
                   : null,
            ),
            const SizedBox(height: 8),
            Text(
              name, // ⬅️ تم استخدام المتغير 'name' المعدل هنا
              style: const TextStyle(color: AppColors.secondaryGold, fontSize: 18, fontFamily: "Cairo", fontWeight: FontWeight.bold),
            ),
            Text( 
              emailOrStatus,
              style: const TextStyle(color: AppColors.secondaryGold, fontSize: 14, fontFamily: "Cairo"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. استخدام StreamBuilder للاستماع لتغير حالة المصادقة
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final User? user = snapshot.data;
        final bool isLoggedIn = snapshot.hasData;

        return Drawer(
          backgroundColor: AppColors.cardColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // 4. Header of the Drawer - يتغير بناءً على حالة تسجيل الدخول وحالة الأدمن
              _buildDrawerHeader(context, user, isLoggedIn),
              
              // عرض عناصر الدرور
              ...drawerItems.map((item) {
                final bool requiresAuth = item['requiresAuth'] == true;
                final bool requiresAdmin = item['requiresAdmin'] == true;
                final bool requiresSchoolManager = item['requiresSchoolManager'] == true;
                final bool requiresMissingPersonManager = item['requiresMissingPersonManager'] == true; 
                final bool requiresNotificationSender = item['requiresNotificationSender'] == true; // جلب الدور الجديد
                
                // منطق الإخفاء:

                // 1. إذا كان العنصر يتطلب مصادقة ولم يسجل المستخدم دخوله
                if (requiresAuth && !isLoggedIn) {
                   return const SizedBox.shrink();
                }

                // 2. إذا كان العنصر يتطلب صلاحيات إدارية خاصة:
                if (requiresAdmin || requiresSchoolManager || requiresMissingPersonManager || requiresNotificationSender) { // تحديث الشرط ليشمل الدور الجديد
                  bool shouldShow = false;
                  
                  // 🗝️ القاعدة الذهبية: إذا كان المستخدم هو المدير العام (_isAdmin)، فإنه يرى جميع الأقسام الإدارية.
                  if (_isAdmin) {
                      shouldShow = true;
                  } 
                  // 🔑 القاعدة الخاصة: إذا لم يكن المدير العام، تحقق من الصلاحيات المحددة.
                  else {
                      if (requiresSchoolManager && _isSchoolManager) {
                          shouldShow = true;
                      }
                      if (requiresMissingPersonManager && _isMissingPersonManager) { 
                          shouldShow = true;
                      }
                      // فحص الدور الجديد
                      if (requiresNotificationSender && _isNotificationSender) {
                          shouldShow = true;
                      }
                  }
                  
                  // إذا لم تتوفر أي من الصلاحيات المطلوبة، يتم إخفاء العنصر
                  if (!shouldShow) {
                    return const SizedBox.shrink(); 
                  }
                }

                return ListTile(
                  leading: Icon(item['icon'] as IconData, color: AppColors.primaryBlue),
                  title: Text(item['title'] as String,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: "Cairo")),
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
                    style: const TextStyle(color: Colors.red, fontFamily: "Cairo")),
                onTap: () async {
                  Navigator.pop(context);
                  
                  if (isLoggedIn) {
                    await AuthService().signOut();
                    // 🔄 الانتقال إلى مسار شاشة البداية /StartScreen
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/StartScreen', // ⬅️ تم التعديل إلى مسار شاشة البداية
                      (Route<dynamic> route) => false,
                    );
                  } else {
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