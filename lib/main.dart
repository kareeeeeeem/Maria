// lib/main.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:churchapp/aus/signup/MemberShipSignUp.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import 'package:churchapp/routes.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:churchapp/firebase_options.dart'; 

// =========================================================================
// 🔔 إضافات الإشعارات المحلية (Local Notifications Imports)
// =========================================================================
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart' show rootBundle; 

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// قائمة الآيات (ستُحمّل من verses.txt)
List<String> versesList = [];

// =========================================================================
// 🌐 ثوابت Supabase (بدون تغيير)
// =========================================================================
const String SUPABASE_URL ='https://zmvhirhhbavjkdjbyrpl.supabase.co'; 
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptdmhpcmhoYmF2amtkamJ5cnBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3MjA0NDcsImV4cCI6MjA4MDI5NjQ0N30.axhqAPmfyd-quxOaYemRZIib_Rs95Bf_GZWeMfW5mJQ';
// =========================================================================
// 🔥 ثوابت ومتغيرات OneSignal (بدون تغيير)
// =========================================================================
const OneSignalAppId ='a3d9efe8-e736-45fc-98fa-2d4a9d4051c5';
final notificationsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);


// =========================================================================
// 🔔 دالة تهيئة الإشعارات المحلية (Initialization)
// =========================================================================

Future<void> requestAndroidPermissions() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // خاص بنظام Android 13 (API 33) والأحدث
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    // هذه الدالة ستعرض للمستخدم شاشة طلب الإذن
    final bool? granted = await androidImplementation.requestNotificationsPermission();
    if (granted == true) {
      print("✅ تم منح إذن الإشعارات بنجاح.");
    } else {
      print("❌ لم يتم منح إذن الإشعارات.");
    }
  }
}
Future<void> _initializeLocalNotifications() async {
  // تهيئة المناطق الزمنية
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Cairo')); 

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_onesignal_default');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true);

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
  print("✅✅✅✅✅ Local Notifications initialized successfully!");
}

// =========================================================================
// 📖 دالة تحميل الآيات من ملف (Loading Verses)
// =========================================================================

Future<void> _loadVerses() async {
  try {
    String fileContent = await rootBundle.loadString('assets/verses.txt');
    versesList = fileContent.split('\n').where((s) => s.trim().isNotEmpty).toList();
    print("📖 Loaded ${versesList.length} verses from file.");
  } catch (e) {
    print("❌ Error loading verses.txt: $e");
  }
}

// =========================================================================
// ⏰ دالة جدولة إشعار الآية اليومية (Scheduling) - الحل الآمن
// =========================================================================

Future<void> _scheduleDailyVerseNotification() async {
  if (versesList.isEmpty) return; 

  await flutterLocalNotificationsPlugin.cancelAll(); 

  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    9, // 9 صباحاً
    0, 
    0, 
  );

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  
  int dayOfYear = scheduledDate.difference(tz.TZDateTime(tz.local, scheduledDate.year, 1, 1)).inDays;
  int verseIndex = dayOfYear % versesList.length; 
  String verseForToday = versesList[verseIndex];
print("🔍 Verse list length: ${versesList.length}. Selected index: $verseIndex. Verse: $verseForToday");


  const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_verse_channel_id', 
        'إشعار الآية اليومية',
        channelDescription: 'قناة لعرض الآيات اليومية المجدولة',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails());

  await flutterLocalNotificationsPlugin.zonedSchedule(
      0, 
      'آية اليوم', 
      verseForToday, 
      scheduledDate,
      notificationDetails,
      // الوضع الآمن الذي لا يتطلب إذن Exact Alarm
      androidScheduleMode: AndroidScheduleMode.inexact, 
      matchDateTimeComponents: DateTimeComponents.time, // التكرار يومياً في نفس التوقيت
      payload: 'daily_verse');
      
  print("⏰ Daily verse scheduled for ${scheduledDate.toIso8601String()} using safe mode.");
}

Future<void> requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // طلب إذن الإشعارات لنظام Android 13+
  final bool? granted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  if (granted == true) {
    print("✅ تم منح إذن الإشعارات بنجاح.");
  } else {
    print("❌ لم يتم منح إذن الإشعارات.");
  }
}
// =========================================================================
// 🧪 دالة اختبار الإشعار الفوري (للتأكد من عمل النظام الآن) - نسخة آمنة وخالية من الأخطاء
// =========================================================================

Future<void> _showInstantTestNotification() async {
  if (versesList.isEmpty) return; 
const int TEST_NOTIFICATION_ID = 99; // ⬅️ رقم مختلف عن 0
  const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel_id', 
        'اختبار الإشعارات',
        channelDescription: 'قناة اختبار فوري',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails());
      
  await flutterLocalNotificationsPlugin.zonedSchedule(
      TEST_NOTIFICATION_ID, // ⬅️ استخدمنا ID مختلف هنا, 
      'آية اليوم', 
      ' ${versesList.first}', 
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // بعد 5 ثوانٍ
      notificationDetails,
      // الوضع الآمن الذي لا يتطلب أذونات إضافية
      androidScheduleMode: AndroidScheduleMode.inexact,
      // تم حذف uiLocalNotificationDateInterpretation
      payload: 'instant_test');
      
  print("🔥 Instant test notification scheduled for 5 seconds from now.");
}


// =========================================================================
// 🔔 دالة تهيئة OneSignal (بدون تغيير)
// =========================================================================
Future<void> _initializeOneSignal() async {
  // ... (منطق OneSignal السابق يبقى كما هو)
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

  if (savedString != null) {
    try {
      List<dynamic> loadedList = jsonDecode(savedString);
      List<Map<String, dynamic>> finalLoadedList = loadedList.map((notif) {
        if (notif is Map<String, dynamic>) {
          return {
            "title": notif["title"] ?? "No title",
            "body": notif["body"] ?? "No message",
            "time": notif["time"] ?? DateTime.now().toIso8601String(),
            "isRead": (notif.containsKey("isRead") && notif["isRead"] is bool) ? notif["isRead"] : true,
          };
        }
        return null;
      }).where((n) => n != null).cast<Map<String, dynamic>>().toList();
      
      notificationsNotifier.value = finalLoadedList;
      
      await prefs.setInt('unread_count', finalLoadedList.where((n) => n["isRead"] == false).length);
    } catch (e) {
      print("Error loading saved notifications: $e");
    }
  }
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
    
    final notif = event.notification;
    final newNotif = {
      "title": notif.title ?? "No title",
      "body": notif.body ?? "No message",
      "time": DateTime.now().toIso8601String(),
      "isRead": false,
    };

    final currentNotifications = notificationsNotifier.value; 
    final updatedNotifications = [newNotif, ...currentNotifications];
    notificationsNotifier.value = updatedNotifications; 

    final prefs = await SharedPreferences.getInstance(); 
    await prefs.setString('saved_notifications', jsonEncode(updatedNotifications));
    
    await prefs.setInt('unread_count', updatedNotifications.where((n) => n["isRead"] == false).length);

    event.notification.display();
    print("📩 Notification received and persisted: $newNotif");
  });

  OneSignal.Notifications.addClickListener((event) {
    print("🔔 Notification clicked: ${event.notification.jsonRepresentation()}");
  });

  print("✅✅✅✅✅ OneSignal initialized successfully!");
}

// =========================================================================
// 🏁 الدالة الرئيسية main - تتضمن تهيئة الإشعارات المحلية والجدولة
// =========================================================================
String initialRoute = '/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  // 🆕 تهيئة Supabase Storage (للتخزين)
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  await _initializeOneSignal();
  
  // 1. تهيئة الإشعارات المحلية أولاً
  await _initializeLocalNotifications();
  
  // 2. طلب الإذن (الآن فقط يعمل بشكل صحيح بعد تهيئة الـ Plugin)
  await requestAndroidPermissions(); // ⬅️ ضع هذا السطر هنا

  await _loadVerses();
  
  // 3. جدولة الإشعار اليومي 
  await _scheduleDailyVerseNotification();
 
  // 4. اختبار الإشعار الفوري (بعد 5 ثوانٍ)
  //await _showInstantTestNotification();
  
  await dotenv.load(fileName: ".env");

  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? userToken = prefs.getString('user_token');
  
  // 🎯 القراءة مع قيمة افتراضية: إذا لم يتم تعيين data_completed من قبل، افترض أنها false
  final bool dataCompleted = prefs.getBool('data_completed') ?? false; 
  
  // ----------------------------------------------------
  // طباعة الحالة الحالية في Console
  // ----------------------------------------------------
  print("حالة التوكن: ${userToken != null && userToken.isNotEmpty ? 'موجود' : 'غير موجود'}");
  print("حالة اكتمال البيانات (القيمة المخزنة): $dataCompleted");
  // ----------------------------------------------------

if (userToken != null && userToken.isNotEmpty) {
  // المستخدم مسجل دخوله (لديه توكن صالح)
  if (dataCompleted) {
    // 1. التوكن موجود والبيانات مكتملة: اذهب إلى الصفحة الرئيسية
    initialRoute = '/HomePage'; 
  } else {
    // 2. التوكن موجود لكن البيانات غير مكتملة: اذهب لجمع البيانات
    initialRoute = MemberDataEntryScreen.routeName; // /MemberDataEntryScreen
  }
} else {
  // 3. لا يوجد توكن: اذهب إلى شاشة تسجيل الدخول.
  initialRoute = 'StartScreen'; // ⬅️ المسار الافتراضي عند عدم وجود مستخدم
}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: routes,
      initialRoute: initialRoute, 
    );
  }
}