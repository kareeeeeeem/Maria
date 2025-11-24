import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:intl/intl.dart'; 

// =========================================================
// I. نموذج البيانات والثوابت 
// =========================================================

class AppColors {
  // اللون الأساسي: بني حجري عميق (Deep Stone) - يوفر فخامة وثبات
  static const Color primaryStone = Color(0xFF4E342E); 
  // لون التمييز: ذهب غني (Rich Gold) - للمسات المبهرة
  static const Color accentGold = Color(0xFFFFD700); 
  // لون الخلفية: بيج دافئ جداً (Warm Beige) - يضمن الهدوء المطلوب
  static const Color backgroundBeige = Color(0xFFFFF8F0); 
  
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFB71C1C); // أحمر داكن للإنذار
}

// 2. نموذج بيانات الحدث/الفعالية
class ChurchEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
  });

  // دالة تحويل من Firestore Document إلى ChurchEvent Object
  factory ChurchEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final timestamp = data?['date'] as Timestamp?;
    
    if (data == null || 
        timestamp == null || 
        data['title'] == null || 
        data['description'] == null || 
        data['location'] == null) {
      
      debugPrint('Error parsing document ${doc.id}: Missing required fields or invalid timestamp.');
      return ChurchEvent(
        id: doc.id,
        title: 'حدث غير صالح',
        description: 'البيانات مفقودة أو غير صالحة',
        date: DateTime.now(),
        location: 'غير محدد',
      );
    }

    return ChurchEvent(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      date: timestamp.toDate(), 
      location: data['location'] as String,
    );
  }

  // دالة تحويل ChurchEvent Object إلى Map للاستخدام في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date), 
      'location': location,
    };
  }
}

// =========================================================
// II. الصفحة الرئيسية (ActivitiesPage) - تصميم فخم
// =========================================================

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
   // حالة المشرف
  bool _isAdmin = false; 
  // حالة مدير الاجتماعات/الأنشطة
  bool _isMeetingsManager = false;
  // حالة التحميل الأولي
  bool _isLoading = true; 
  
  bool _isLocaleInitialized = false; 
  
  // خاصية مجمعة للتحقق من صلاحية التعديل (Admin أو Manager)
  bool get _canEdit => _isAdmin || _isMeetingsManager; // 🟢 تم استخدام هذه الخاصية الآن في واجهة المستخدم

  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
  late final CollectionReference _eventsCollection;

  @override
  void initState() {
    super.initState();
    
    // إعداد مسار المجموعة
    _eventsCollection = _firestore.collection('artifacts').doc(appId).collection('public').doc('data').collection('events');
    
    _initializeLocale();
    _setupAuthListener(); // إعداد مستمع المصادقة وفحص الدور
  }
  
  // دالة فحص حقل isAdmin و isMeetingsManager في Firestore
    Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      
      // القراءة الآمنة لحقلي isAdmin و isMeetingsManager
      final bool isAdmin = data?['isAdmin'] ?? false;
      final bool isMeetingsManager = data?['isMeetingsManager'] ?? false; 
      
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isMeetingsManager = isMeetingsManager; 
          _isLoading = false; 
        });
      }
      debugPrint('User $uid status: isAdmin=$_isAdmin, isMeetingsManager=$_isMeetingsManager, Can Edit=$_canEdit');
    } catch (e) {
      debugPrint('Admin/Manager Status Check Error: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isMeetingsManager = false; 
          _isLoading = false; 
        });
      }
    }
  }
  
  // دالة إعداد مستمع المصادقة
  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // إذا كان المستخدم مسجلاً الدخول، تحقق من صلاحياته
        _checkAdminStatus(user.uid);
      } else {
        // إذا لم يكن مسجلاً الدخول، إبقِ الصلاحيات على False
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isMeetingsManager = false; 
            _isLoading = false; 
          });
        }
      }
    });
  }


  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('ar', null);
    } catch (e) {
      debugPrint('Error initializing locale data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    }
  }

  void _navigateToAddEvent() {
    // 🟢 التحقق باستخدام _canEdit بدلاً من _isAdmin
    if (!_canEdit) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون مصادقاً عليه كمسؤول أو مدير للقيام بهذه العملية.')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEventScreen(eventsCollection: _eventsCollection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // إظهار شاشة التحميل إذا لم يتم تهيئة اللغة أو لم يتم الانتهاء من فحص الأدمن
    if (!_isLocaleInitialized || _isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBeige, // تم التحديث
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryStone)), // تم التحديث
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige, // تم التحديث
      appBar: AppBar(
        title: const Text(
          '🎉 الأنشطة والفعاليات', 
          style: TextStyle(
            color: AppColors.accentGold, // لون الذهب
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )
        ),
        backgroundColor: AppColors.primaryStone, // لون الحجر
        elevation: 8, // زيادة الـ elevation
        shadowColor: AppColors.primaryStone.withOpacity(0.5),
        centerTitle: true,
      ),
      
      // 🟢 تمرير _canEdit إلى قائمة الأحداث
      body: _EventsList(eventsCollection: _eventsCollection, canEdit: _canEdit),

      // 🟢 زر إضافة الفعالية يظهر لمن لديه صلاحية التعديل
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddEvent,
              label: const Text('إضافة فعالية', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              icon: const Icon(Icons.add_location_alt_rounded),
              backgroundColor: AppColors.primaryStone, // لون الحجر
              foregroundColor: AppColors.accentGold, // لون الذهب
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // حواف أكبر
              elevation: 10, // بهرجة
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// =========================================================
// III. مكونات الأحداث والفعاليات (Events) - تصميم فخم
// =========================================================

class _EventsList extends StatelessWidget {
  final CollectionReference eventsCollection;
  final bool canEdit; // 🟢 تم تغييرها إلى canEdit
  const _EventsList({required this.eventsCollection, required this.canEdit}); // 🟢 تم تغييرها إلى canEdit

  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه الفعالية؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );

    if (confirm == true) {
      try {
        await eventsCollection.doc(eventId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم حذف الفعالية بنجاح.')),
          );
        }
      } catch (e) {
        debugPrint('Delete Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ فشل الحذف: قد لا تملك الأذونات اللازمة أو هناك مشكلة في الاتصال.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // طلب البيانات فقط، والترتيب سيتم بعد الجلب
      stream: eventsCollection.snapshots(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryStone)); // لون الحجر
        }

        if (snapshot.hasError) {
          debugPrint('Firestore Error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'خطأ في جلب البيانات: ${snapshot.error}. تأكد من الاتصال بالإنترنت.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.alertRed, fontSize: 16),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد فعاليات قادمة حالياً.',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          );
        }

        final events = snapshot.data!.docs.map((doc) {
          try {
            return ChurchEvent.fromFirestore(doc);
          } catch (e) {
            debugPrint('Error parsing document ${doc.id}: $e');
            return null;
          }
        }).whereType<ChurchEvent>().toList(); 
        
        // الترتيب حسب التاريخ في الذاكرة (لتجنب مشاكل الـ Index في Firestore)
        events.sort((a, b) => a.date.compareTo(b.date));


        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _EventCard(
              event: events[index],
              canEdit: canEdit, // 🟢 تمرير صلاحية التعديل
              // زر الحذف يظهر لمن لديه صلاحية التعديل
              onDelete: () => _deleteEvent(context, events[index].id),
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final ChurchEvent event;
  final bool canEdit; // 🟢 تم تغييرها إلى canEdit
  final VoidCallback onDelete;

  const _EventCard({required this.event, required this.canEdit, required this.onDelete}); // 🟢 تم تغييرها إلى canEdit

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.primaryStone, size: 20), // لون الحجر
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd | hh:mm a', 'ar');
    final formattedDate = formatter.format(event.date);

    final bool isPastEvent = event.date.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0), // زيادة الهوامش قليلاً
      elevation: 8, // رفع الـ elevation لتبدو مبهرة أكثر
      shadowColor: AppColors.primaryStone.withOpacity(0.4), // ظل أنيق
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // حواف دائرية أكبر
        side: BorderSide(color: AppColors.accentGold.withOpacity(0.7), width: 1.5), // حدود ذهبية
      ),
      color: isPastEvent ? AppColors.backgroundBeige : AppColors.cardColor, // استخدام البيج لحالة الانتهاء
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 20, // حجم أكبر للعنوان
                      fontWeight: FontWeight.w900, // خط سميك جداً
                      color: isPastEvent ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: isPastEvent ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 🟢 أيقونة الحذف تظهر لمن لديه صلاحية التعديل
                if (canEdit && !isPastEvent)
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: AppColors.alertRed, size: 28),
                    onPressed: onDelete,
                    tooltip: 'حذف الفعالية',
                  ),
              ],
            ),
          ),
          
          _EventStatusIndicator(targetDate: event.date, isPast: isPastEvent),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
                  textAlign: TextAlign.right,
                ),
                const Divider(color: AppColors.primaryStone, thickness: 0.5, height: 30),
                _buildDetailRow(
                  Icons.access_time_filled,  
                  'الموعد',  
                  formattedDate
                ),
                _buildDetailRow(Icons.location_on, 'المكان', event.location),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// مكون حالة الحدث (عداد تنازلي أو حالة انتهاء)
// ---------------------------------------------------------

class _EventStatusIndicator extends StatelessWidget {
  final DateTime targetDate;
  final bool isPast;
  
  const _EventStatusIndicator({required this.targetDate, required this.isPast});

  @override
  Widget build(BuildContext context) {
    if (isPast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.alertRed.withOpacity(0.15), // خلفية حمراء باهتة لحالة الانتهاء
        child: const Text(
          'انتهت الفعالية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.alertRed,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return _CountdownTimer(targetDate: targetDate);
  }
}

class _CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  const _CountdownTimer({required this.targetDate});

  @override
  State<_CountdownTimer> createState() => __CountdownTimerState();
}

class __CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timeRemaining = widget.targetDate.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _timeRemaining = widget.targetDate.difference(DateTime.now());
      
      if (_timeRemaining.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          _timeRemaining = Duration.zero;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'الفعالية بدأت!';

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24)); 
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return 'متبقي: $days يوم، $hours ساعة، $minutes دقيقة، $seconds ثانية';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryStone.withOpacity(0.15), // خلفية حجرية فاتحة
      child: Text(
        _formatDuration(_timeRemaining),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900, // خط سميك جداً
          color: AppColors.primaryStone, // لون الحجر
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// =========================================================
// IV. شاشة إضافة فعالية (AddEventScreen) - تصميم فخم
// =========================================================

class AddEventScreen extends StatefulWidget {
  final CollectionReference eventsCollection;
  const AddEventScreen({super.key, required this.eventsCollection});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      // تخصيص الألوان لمنتقي التاريخ
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryStone, // لون الحجر
              onPrimary: AppColors.accentGold, // لون الذهب
              onSurface: AppColors.primaryStone,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (context.mounted) {
        _selectTime(context, picked);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, DateTime selectedDay) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      initialEntryMode: TimePickerEntryMode.input,
      // تخصيص الألوان لمنتقي الوقت
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryStone, // لون الحجر
              onPrimary: AppColors.accentGold, // لون الذهب
              onSurface: AppColors.primaryStone,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate()) {
      if (FirebaseAuth.instance.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: يجب أن تكون مصادقاً عليه لإضافة فعالية.')),
          );
        }
        return;
      }
      
      setState(() { _isLoading = true; });

      final newEvent = ChurchEvent(
        id: '', 
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        location: _locationController.text,
      );

      try {
        await widget.eventsCollection.add(newEvent.toFirestore());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إضافة الفعالية بنجاح!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Add Event Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ فشل إضافة الفعالية: قد لا تملك الأذونات اللازمة أو هناك مشكلة في الاتصال.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  // مكون مساعد لحقل الإدخال بتصميم فخم
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: AppColors.accentGold), // أيقونات ذهبية
        // تصميم حدود الإدخال (OutlinedInputBorder)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.textSecondary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryStone, width: 2.5), // حدود مبهرة عند التركيز
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDateTime = DateFormat('EEEE, d MMMM yyyy, hh:mm a', 'ar').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige, // خلفية بيج دافئة
      appBar: AppBar(
        title: const Text('إضافة فعالية جديدة', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryStone,
        centerTitle: true,
        elevation: 8,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(
                controller: _titleController,
                label: 'عنوان الفعالية',
                icon: Icons.title,
              ),
              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _descriptionController,
                label: 'الوصف التفصيلي للفعالية',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _locationController,
                label: 'مكان انعقاد الفعالية',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formattedDateTime,
                      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.edit_calendar, color: AppColors.primaryStone), // لون الحجر
                    label: const Text(
                      'تعديل التاريخ والوقت',  
                      style: TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold) // لون الحجر
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.primaryStone, thickness: 0.5, height: 30),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addEvent,
                icon: _isLoading 
                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 4))
                    : const Icon(Icons.event_note, color: AppColors.accentGold),
                label: Text(
                  _isLoading ? 'جاري الإضافة...' : 'إضافة الفعالية',
                  style: const TextStyle(fontSize: 20, color: AppColors.accentGold, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStone,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  shadowColor: AppColors.primaryStone.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}