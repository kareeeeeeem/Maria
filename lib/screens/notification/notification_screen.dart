// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

// 🔔 ValueNotifier المشترك (المصدر الرئيسي) - يجب أن يكون هذا التعريف في ملف عام أو يتم استيراده
final ValueNotifier<List<Map<String, dynamic>>> notificationsNotifier =
    ValueNotifier<List<Map<String, dynamic>>>([]);

class NotificationsPage extends StatefulWidget {
  static const String routeName = "/NotificationsPage"; 

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  late VoidCallback _notifierListener;

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // يمكن إبقائها للتحميل الأولي

    _notifierListener = () {
      if (!mounted) return; 
      setState(() {
        _notifications = notificationsNotifier.value;
        _loadUnreadCount(); // تحديث العداد
      });
      _playNotificationEffect();
    };

    notificationsNotifier.addListener(_notifierListener);
  }
  
  Future<void> _loadUnreadCount() async {
    final count = notificationsNotifier.value.where((n) => n['isRead'] == false).length;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _unreadCount = count;
    });
    await prefs.setInt('unread_count', count);
  }

  @override
  void dispose() {
    notificationsNotifier.removeListener(_notifierListener);
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_notifications');
    
    if (!mounted) return;

    if (data != null) {
      final loadedList = List<Map<String, dynamic>>.from(jsonDecode(data) as List<dynamic>);
      
      notificationsNotifier.value = loadedList.map((n) {
        if (n is Map<String, dynamic>) {
          return {
            ...n,
            'isRead': n.containsKey('isRead') ? n['isRead'] : false, 
          };
        }
        return null;
      }).where((n) => n != null).cast<Map<String, dynamic>>().toList();
      
      _notifications = notificationsNotifier.value;
    }
    await _loadUnreadCount(); 
  }

  // =======================================================
  // 🔥🔥 التعديل النهائي لضمان حفظ حالة isRead بشكل دائم 🔥🔥
  // =======================================================
  Future<void> _markNotificationAsRead(int index) async {
    // 1. الحصول على القائمة الحالية من ValueNotifier (هي المصدر الرئيسي للحقيقة)
    final currentList = notificationsNotifier.value;

    if (currentList.isEmpty || index < 0 || index >= currentList.length) return;
    
    // ⚠️ عرض التفاصيل إذا كانت مقروءة بالفعل ثم الخروج
    if (currentList[index]['isRead'] == true) {
      _showNotificationDetails(context, currentList[index]);
      return; 
    }

    // 2. إنشاء نسخة جديدة من القائمة
    final updatedList = List<Map<String, dynamic>>.from(currentList);
    
    // 3. تحديث الإشعار المحدد في النسخة الجديدة
    updatedList[index] = {...currentList[index], 'isRead': true};

    // 4. تحديث الـ ValueNotifier ليعكس التغيير (يتم تحديث الـ UI)
    notificationsNotifier.value = updatedList;
    
    // 5. إعادة حفظ القائمة المُحدَّثة في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', jsonEncode(updatedList));

    // 6. إعادة حساب العداد وتحديثه
    await _loadUnreadCount();
    
    // 7. عرض التفاصيل
    if(mounted) {
      _showNotificationDetails(context, updatedList[index]);
    }
  }
  
  
  
  
    // ✅ الدالة لعرض تفاصيل الإشعار في نافذة منبثقة
  // =======================================================
  void _showNotificationDetails(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            notification['title'] ?? 'عنوان الإشعار', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  notification['body'] ?? 'لا يوجد محتوى', 
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Text(
                  "تاريخ الإرسال: ${formatTime(notification['time'])}", 
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)), 
            ),
          ],
        );
      },
    );
  }
  // =======================================================

  Future<void> _playNotificationEffect() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 300);
      }
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint("⚠️ Error playing effect: $e");
    }
  }

  String formatTime(String timeIso) {
    final time = DateTime.parse(timeIso);
    final diff = DateTime.now().difference(time);
    
    if (diff.inMinutes < 60) return "${diff.inMinutes} minet left";
    if (diff.inHours < 24) return "${diff.inHours} hour left";
    return DateFormat('dd MMM yyyy • hh:mm a').format(time);
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    // حفظ قائمة JSON فارغة صراحةً
    await prefs.setString('saved_notifications', jsonEncode([]));
    await prefs.setInt('unread_count', 0); // تصفير العداد

    notificationsNotifier.value = []; // تفريغ الـ ValueNotifier في الذاكرة
    if (!mounted) return;
    setState(() {
      _notifications.clear();
      _unreadCount = 0;
    });
    
    print("✅ All notifications cleared and empty list saved to SharedPreferences.");
  }

  // 🔥 دالة تُستدعى عند الضغط على زر الجرس لمسح العداد (مسح جميع الإشعارات غير المقروءة)
  void _markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    
    // إنشاء قائمة جديدة للتحديث
    final updatedList = notificationsNotifier.value.map((n) {
      return {...n, 'isRead': true}; 
    }).toList();
    
    // تحديث القائمة المشتركة إلى isRead: true
    notificationsNotifier.value = updatedList;
    
    // حفظ التغيير
    await prefs.setString('saved_notifications', jsonEncode(updatedList));
    
    // تحديث العداد
    await _loadUnreadCount(); // سيقوم بحساب العداد ليصبح 0

    if (!mounted) return;
    setState(() {}); // تحديث الواجهة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E342E),
        title: const Text(
          "notifications", // Notifications
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 5, end: 8),
            showBadge: _unreadCount > 0,
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.deepOrange,
              padding: EdgeInsets.all(6),
            ),
            badgeContent: Text(
              '$_unreadCount',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), 
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: _markAllAsRead, // استدعاء دالة مسح العداد
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                "no notifications until now💤", // No notifications yet
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final isNew = n['isRead'] == false;
                
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isNew 
                          ? [Colors.redAccent.shade700, Colors.deepPurple.shade900]
                          : [Colors.grey.shade800, Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isNew ? Colors.redAccent.withOpacity(0.5) : Colors.black54,
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () {
                        // عند النقر: يتم تحديد الإشعار كمقروء ثم عرض التفاصيل (يتم ذلك داخل _markNotificationAsRead)
                        _markNotificationAsRead(index);
                      },
                      
                      leading: CircleAvatar(
                        backgroundColor: isNew ? Colors.white : Colors.grey.shade800,
                        child: Icon(Icons.notifications_active, color: isNew ? Colors.red : Colors.white), 
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              n['title'],
                              style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: isNew ? FontWeight.bold : FontWeight.w600 
                              ),
                            ),
                          ),
                          if (isNew) 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "NEW",
                                style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            n['body'],
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatTime(n['time']),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}