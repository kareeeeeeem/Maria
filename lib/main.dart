import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:churchapp/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:churchapp/firebase_options.dart';

// =========================================================================
// 🔥 ثوابت ومتغيرات OneSignal
// =========================================================================
// ✅ قم بتحديث هذا بالـ App ID الخاص بك
const OneSignalAppId ='a3d9efe8-e736-45fc-98fa-2d4a9d4051c5';
// 👀 notifier مشترك لإدارة حالة الإشعارات (للعرض في الواجهة)
// يستخدم لتخزين الإشعارات كقائمة من الخرائط
final notificationsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);




// =========================================================================
// 🔔 دالة تهيئة OneSignal
// =========================================================================
Future<void> _initializeOneSignal() async {
  // تخطي التهيئة على الويب لأن OneSignal لا يدعمها بشكل كامل حالياً
  if (kIsWeb) {
    print("🔔 OneSignal initialization skipped on Web platform.");
    return;
  }
  
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(OneSignalAppId);
  await OneSignal.Notifications.requestPermission(true);
  OneSignal.User.pushSubscription.optIn();

  final prefs = await SharedPreferences.getInstance();
  final String? savedString = prefs.getString('saved_notifications');

  // 1. تحميل الإشعارات المحفوظة من SharedPreferences
  if (savedString != null) {
    try {
      List<dynamic> loadedList = jsonDecode(savedString);
      List<Map<String, dynamic>> finalLoadedList = loadedList.map((notif) {
        if (notif is Map<String, dynamic>) {
          return {
            "title": notif["title"] ?? "No title",
            "body": notif["body"] ?? "No message",
            "time": notif["time"] ?? DateTime.now().toIso8601String(),
            // نعتبر الإشعار مقروءاً إذا كان الحقل مفقوداً أو غير صحيح
            "isRead": (notif.containsKey("isRead") && notif["isRead"] is bool) ? notif["isRead"] : true,
          };
        }
        return null;
      }).where((n) => n != null).cast<Map<String, dynamic>>().toList();
      
      notificationsNotifier.value = finalLoadedList;
      
      // تحديث عداد الإشعارات غير المقروءة
      await prefs.setInt('unread_count', finalLoadedList.where((n) => n["isRead"] == false).length);
    } catch (e) {
      print("Error loading saved notifications: $e");
    }
  }
  
  // 2. معالج استقبال الإشعار أثناء عمل التطبيق (Foreground)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
    final notif = event.notification;
    final newNotif = {
      "title": notif.title ?? "No title",
      "body": notif.body ?? "No message",
      "time": DateTime.now().toIso8601String(),
      "isRead": false, // الإشعار الجديد دائماً غير مقروء
    };

    // إضافة الإشعار الجديد إلى بداية القائمة
    notificationsNotifier.value = [newNotif, ...notificationsNotifier.value]; 

    // حفظ القائمة المحدثة بالكامل
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', jsonEncode(notificationsNotifier.value));
    
    // تحديث عداد الإشعارات غير المقروءة
    await prefs.setInt('unread_count', notificationsNotifier.value.where((n) => n["isRead"] == false).length);

    event.notification.display();
    print("📩 Notification received: $newNotif");
  });

  OneSignal.Notifications.addClickListener((event) {
    print("🔔 Notification clicked: ${event.notification.jsonRepresentation()}");
    // يمكنك هنا إضافة منطق التوجيه إلى شاشة الإشعارات
  });

  print("✅ OneSignal initialized successfully!");
}

// =========================================================================
// 🏁 الدالة الرئيسية main
// =========================================================================
String initialRoute = '/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  await _initializeOneSignal();
  
  // 🧭🧭🧭 منطق التحقق من حالة تسجيل الدخول (التوكن) 🧭🧭🧭
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // افترض أنك تخزن التوكن تحت مفتاح 'user_token'
  final String? userToken = prefs.getString('user_token');
  // إذا كان هناك توكن، اذهب إلى الشاشة الرئيسية
  if (userToken != null && userToken.isNotEmpty) {
    initialRoute = '/HomePage'; 
  } else {
    // إذا لم يكن هناك توكن، اذهب إلى شاشة البدء/Onboarding
    initialRoute = '/'; 
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الكنيسة', // أضفت العنوان لضمان اكتمال الـ MaterialApp
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue), // أضفت ثيم مبسط لضمان التشغيل
      
      // builder: (context, child) {
      //   return Directionality(
      //     // تم تغيير الـ textDirection إلى RTL لدعم واجهة عربية نموذجية
      //     textDirection: TextDirection.rtl, 
      //     child: child!,
      //   );
      // },
      
      routes: routes, // استخدام الـ Map الذي تم استيراده
      initialRoute: initialRoute, 
    );
  }
}