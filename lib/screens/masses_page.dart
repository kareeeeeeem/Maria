// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
// Firebase Imports (Assume these are available in pubspec.yaml)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// II. كلاس الثوابت والألوان (AppColors)
// =========================================================
class AppColors {
  // ألوان جديدة تليق بالتصميم الكنسي
  static const Color primaryMaroon = Color(0xFF4E342E); // ماروني عميق / عنابي
  static const Color accentGold = Color(0xFFE6C47A); // ذهبي مطفأ / عتيق
  static const Color primaryDarkBlue = Color(0xFF37474F); // لون بديل للعشيات (Dark Slate)
  
  // ✅ تم إضافة البيج وتطبيقه على الخلفية
  static const Color backgroundBeige = Color(0xFFFFF8F0); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

// =========================================================
// I. كلاس نموذج البيانات (MassesSchedule) - مع الفرز الدقيق
// =========================================================
class MassesSchedule {
  final String id;
  final String type; // 'Mass' أو 'Vesper'
  final String title;
  final String day;
  final String time;
  final Timestamp? timestamp; 

  MassesSchedule({
    required this.id,
    required this.type,
    required this.title,
    required this.day,
    required this.time,
    this.timestamp,
  });

  static const Map<String, int> _dayOrder = {
    'الأحد': 1, 'الإثنين': 2, 'الثلاثاء': 3, 'الأربعاء': 4,
    'الخميس': 5, 'الجمعة': 6, 'السبت': 7, 'غير محدد': 8,
  };

  factory MassesSchedule.fromMap(Map<String, dynamic> data, String id) {
    return MassesSchedule(
      id: id,
      type: data['type'] ?? '',
      title: data['title'] ?? 'قداس/عشية',
      day: data['day'] ?? 'غير محدد',
      time: data['time'] ?? 'غير محدد',
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'day': day,
      'time': time,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
  
  // دالة تحليل الوقت (س:دق ص/م) لتحويله إلى دقائق من منتصف الليل
  static int _parseTime(String time) {
    try {
      final parts = time.split(RegExp(r'[:\s]')); 
      if (parts.length < 3) return 0;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = parts[2].trim().toLowerCase();

      // تحويل صيغة 12 ساعة إلى 24 ساعة
      if (period == 'م') {
        if (hour != 12) hour += 12;
      } else if (period == 'ص' && hour == 12) {
        hour = 0; 
      }

      return hour * 60 + minute; 
    } catch (e) {
      return 0; 
    }
  }
  
  // دالة فرز مخصصة مُحسنة: الفرز باليوم ثم بالوقت الفعلي
  int compareTo(MassesSchedule other) {
    final dayA = _dayOrder[day] ?? 9;
    final dayB = _dayOrder[other.day] ?? 9;
    
    // 1. الفرز حسب اليوم
    if (dayA != dayB) {
      return dayA.compareTo(dayB);
    }
    
    // 2. الفرز حسب الوقت الفعلي (باستخدام الدقائق المحللة)
    final timeA = _parseTime(time);
    final timeB = _parseTime(other.time);
    
    return timeA.compareTo(timeB); 
  }
}

// =========================================================
// 2. الصفحة الرئيسية الموحدة (MassesPage)
// =========================================================

class MassesPage extends StatefulWidget {
  const MassesPage({super.key});

  @override
  State<MassesPage> createState() => _MassesPageState();
}

class _MassesPageState extends State<MassesPage> with SingleTickerProviderStateMixin {
  late FirebaseFirestore _db;
  late FirebaseAuth _auth;
  String? _userId;
  bool _isLoading = true;
  // هذا المتغير سيخزن النتيجة النهائية لـ (isAdmin OR IsRector...)
  bool _isAdminStatus = false; 

  List<MassesSchedule> _schedules = [];
  late TabController _tabController;

  // هذا الـ Getter يستخدم النتيجة الموحدة للحقلين
  bool get _isAdmin => _userId != null && _isAdminStatus;
  
  // مفتاح لنموذج الإضافة/التعديل
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFirebaseAndListen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // دالة فحص حقل isAdmin و IsRectorofMassesandVespers في Firestore
  Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();

      // 💡 التعديل هنا: نقرأ حالة الأدمن وحالة "الراعي"
      final bool isAdmin = data?['isAdmin'] ?? false;
      final bool isRector = data?['IsRectorofMassesandVespers'] ?? false; 
      
      // نحدد ما إذا كان يمتلك أي صلاحية تعديل (Admin OR Rector)
      final bool canEdit = isAdmin || isRector; 

      if (mounted) {
        setState(() {
          // نستخدم هذا المتغير لتحديد إمكانية التعديل
          _isAdminStatus = canEdit; 
        });
      }
    } catch (e) {
      print('Failed to check permissions for $uid: $e');
      if (mounted) {
        setState(() { _isAdminStatus = false; });
      }
    }
  }

  Future<void> _initializeFirebaseAndListen() async {
    try {
      _db = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;

      _auth.authStateChanges().listen((User? user) async {
        if (mounted) {
          setState(() { _userId = user?.uid; });
          
          if (user != null) {
            await _checkAdminStatus(user.uid);
          } else {
            setState(() { _isAdminStatus = false; });
             try {
               await _auth.signInAnonymously(); 
             } catch (e) {
                print('Anonymous Auth Failed: $e');
             }
          }
        }
      });
      
      _startListeningToSchedules(); 

    } catch (e) {
      print('Firebase Initialization/Auth Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  CollectionReference get _schedulesCollection {
     return _db.collection('masses_schedules');
  }

  void _startListeningToSchedules() {
    _schedulesCollection.snapshots().listen((snapshot) {
      final updatedSchedules = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>; 
        return MassesSchedule.fromMap(data, doc.id);
      }).toList();
      
      updatedSchedules.sort((a, b) => a.compareTo(b));

      if (mounted) {
        setState(() {
          _schedules = updatedSchedules;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      print('Firestore Listen Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحميل المواعيد من قاعدة البيانات.')),
        );
      }
    });
  }

  void _deleteSchedule(String id) async {
    // التحقق من الصلاحية يعتمد الآن على _isAdmin الذي تم تحديث منطق الصلاحيات به
    if (!_isAdmin) return; 
    try {
      await _schedulesCollection.doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الموعد بنجاح!')),
        );
      }
    } catch (e) {
      print('Delete Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حذف الموعد.')),
        );
      }
    }
  }

  // دالة الإضافة/التعديل (تم تطبيق الألوان عليها)
  void _showScheduleForm({MassesSchedule? schedule}) {
    // التحقق من الصلاحية يعتمد الآن على _isAdmin الذي تم تحديث منطق الصلاحيات به
    if (!_isAdmin) return;
    
    // القيم الأولية للنموذج
    String currentTitle = schedule?.title ?? '';
    String currentDay = schedule?.day ?? 'الأحد';
    String currentTime = schedule?.time ?? '7:00 ص';
    String currentType = schedule?.type ?? 'Mass';

    final List<String> days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final List<String> types = ['Mass', 'Vesper'];

    // دالة مساعدة لإنشاء حقول الإدخال بالألوان المطلوبة
    Widget _buildStyledFormField({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0), 
        child: Theme(
          data: Theme.of(context).copyWith(
            // تحديد لون التمييز لحقول الإدخال
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.brown).copyWith(secondary: AppColors.primaryMaroon),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: AppColors.textSecondary),
              // توحيد شكل الحدود
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide(color: AppColors.primaryMaroon)),
              // لون التركيز الماروني
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide(color: AppColors.primaryMaroon, width: 2)),
            ),
          ),
          child: child,
        ),
      );
    }


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75, 
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Form( 
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      schedule == null ? '➕ إضافة موعد جديد' : '✏️ تعديل موعد',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primaryMaroon,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: AppColors.accentGold, thickness: 2),
                    const SizedBox(height: 15),

                    Expanded(
                      child: ListView(
                        children: [
                          _buildStyledFormField(
                            child: TextFormField(
                              initialValue: currentTitle,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(labelText: 'عنوان الموعد (مثال: قداس منتصف الأسبوع)'),
                              onChanged: (value) => currentTitle = value,
                              validator: (value) => value!.trim().isEmpty ? 'العنوان مطلوب' : null,
                            ),
                          ),

                          _buildStyledFormField(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'النوع'),
                              value: currentType,
                              items: types.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type == 'Mass' ? 'قداس' : 'عشية'),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setModalState(() { currentType = newValue; });
                                }
                              },
                            ),
                          ),

                          _buildStyledFormField(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'اليوم'),
                              value: currentDay,
                              items: days.map((String day) {
                                return DropdownMenuItem<String>(value: day, child: Text(day));
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setModalState(() { currentDay = newValue; });
                                }
                              },
                            ),
                          ),

                          _buildStyledFormField(
                            child: TextFormField(
                              initialValue: currentTime,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(labelText: 'الوقت (مثال: 7:00 ص)'),
                              onChanged: (value) => currentTime = value,
                              validator: (value) => value!.trim().isEmpty ? 'الوقت مطلوب' : null,
                              keyboardType: TextInputType.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // زر الحفظ (بالألوان المطلوبة)
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveSchedule(
                            isUpdate: schedule != null,
                            id: schedule?.id,
                            title: currentTitle,
                            day: currentDay,
                            time: currentTime,
                            type: currentType,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                        shadowColor: AppColors.primaryMaroon.withOpacity(0.5),
                      ),
                      child: Text(
                        schedule == null ? 'إضافة الموعد' : 'حفظ التعديلات',
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _saveSchedule({
    required bool isUpdate,
    String? id,
    required String title,
    required String day,
    required String time,
    required String type,
  }) async {
    
    final newSchedule = MassesSchedule(
      id: id ?? '',
      title: title.trim(),
      day: day,
      time: time.trim(),
      type: type,
    );

    try {
      if (isUpdate && id != null) {
        await _schedulesCollection.doc(id).update(newSchedule.toMap());
        if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح.')));
        }
      } else {
        await _schedulesCollection.add(newSchedule.toMap());
        if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الموعد الجديد بنجاح.')));
        }
      }
    } catch (e) {
      print('Save Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل حفظ/تحديث الموعد.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBeige, // ✅ تم تطبيق الخلفية البيج
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryMaroon),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige, // ✅ تم تطبيق الخلفية البيج
      appBar: AppBar(
        title: const Text('القداسات والعشيات', 
        style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),       

         centerTitle: true,
        backgroundColor: AppColors.primaryMaroon,
        elevation: 8,
        shadowColor: AppColors.primaryMaroon.withOpacity(0.5),
        actions: const [],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'القداسات', icon: Icon(Icons.local_fire_department)),
            Tab(text: 'العشيات', icon: Icon(Icons.dark_mode_rounded)),
          ],
          labelColor: AppColors.accentGold,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.only(bottom: 5.0),
          indicator: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.accentGold, width: 3)),
          ),
        ),
      ),
      
      floatingActionButton: _isAdmin // يعتمد على منطق (Admin OR Rector)
          ? FloatingActionButton.extended(
              onPressed: () => _showScheduleForm(),
              label: const Text('إضافة موعد', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_rounded, color: AppColors.accentGold),
              backgroundColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
            )
          : null,

      body: TabBarView(
        controller: _tabController,
        children: [
          _ScheduleList(
            schedules: _schedules.where((s) => s.type == 'Mass').toList(),
            isAdmin: _isAdmin, // يعتمد على منطق (Admin OR Rector)
            onEdit: _showScheduleForm,
            onDelete: _deleteSchedule,
            emptyMessage: _isAdmin
                ? '🎉 لا توجد قداسات مُجدولة. استخدم زر الإضافة لتبدأ.'
                : '🎉 لا توجد قداسات مُجدولة حالياً.',
          ),
          _ScheduleList(
            schedules: _schedules.where((s) => s.type == 'Vesper').toList(),
            isAdmin: _isAdmin, // يعتمد على منطق (Admin OR Rector)
            onEdit: _showScheduleForm,
            onDelete: _deleteSchedule,
            emptyMessage: _isAdmin
                ? '🕯️ لا توجد عشيات مُجدولة. استخدم زر الإضافة لتبدأ.'
                : '🕯️ لا توجد عشيات مُجدولة حالياً.',
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 3. ويدجت عرض القائمة (محسّن بصريًا ومنطقيًا)
// =========================================================

class _ScheduleList extends StatelessWidget {
  final List<MassesSchedule> schedules;
  final bool isAdmin;
  final String emptyMessage;

  final void Function({MassesSchedule? schedule}) onEdit;
  final void Function(String) onDelete;

  const _ScheduleList({
    required this.schedules,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.emptyMessage,
  });

  // دالة مساعدة للحصول على الأيقونة والتدرج اللوني
  Map<String, dynamic> _getScheduleVisuals(MassesSchedule schedule) {
    final List<Color> iconGradient;
    final IconData icon;

    if (schedule.type == 'Mass') {
      icon = Icons.church_rounded;
      iconGradient = [AppColors.primaryMaroon, AppColors.primaryMaroon.withOpacity(0.7)];
    } else {
      icon = Icons.nights_stay_rounded;
      iconGradient = [AppColors.primaryDarkBlue, AppColors.primaryDarkBlue.withOpacity(0.7)];
    }

    return {'icon': icon, 'gradient': iconGradient};
  }


  void _showDeleteConfirmation(BuildContext context, MassesSchedule schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل أنت متأكد أنك تريد حذف موعد "${schedule.title}"؟', textAlign: TextAlign.right),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () { Navigator.of(ctx).pop(); },
          ),
          TextButton(
            child: const Text('حذف', style: TextStyle(color: AppColors.primaryMaroon)), 
            onPressed: () {
              onDelete(schedule.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
        actionsAlignment: MainAxisAlignment.start, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined, size: 60, color: AppColors.accentGold.withOpacity(0.5)),
              const SizedBox(height: 15),
              Text(
                emptyMessage,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final visuals = _getScheduleVisuals(schedule);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Material(
            color: AppColors.cardColor,
            elevation: 6,
            shadowColor: AppColors.primaryMaroon.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              // يتم تفعيل التعديل فقط إذا كانت لديه صلاحية (Admin OR Rector)
              onTap: isAdmin 
                  ? () => onEdit(schedule: schedule)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ تم تفعيل التذكير لموعد ${schedule.title}!')
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    // 1. أيقونة الموعد (مع التدرج اللوني)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: visuals['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Icon(
                        visuals['icon'],
                        color: AppColors.accentGold,
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 20),

                    // 2. تفاصيل الموعد
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          Text(
                            schedule.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.primaryMaroon),
                            textAlign: TextAlign.right, 
                          ),
                          const SizedBox(height: 6),
                          // أيقونة اليوم والوقت مفصولة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end, 
                            children: [
                              Text(schedule.time, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.access_time_filled, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Text(schedule.day, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            ].reversed.toList(), 
                          ),
                        ],
                      ),
                    ),

                    // 3. العرض المشروط لأزرار الإدارة
                    if (isAdmin) // يعتمد على منطق (Admin OR Rector)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: AppColors.accentGold, size: 28),
                            onPressed: () => onEdit(schedule: schedule),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Color(0xFFC62828), size: 28),
                            onPressed: () => _showDeleteConfirmation(context, schedule),
                            tooltip: 'حذف',
                          ),
                        ],
                      )
                    else
                      // أيقونة التذكير لليوزر العادي
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Icon(Icons.notifications_active_outlined, color: AppColors.primaryMaroon.withOpacity(0.7), size: 28),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}