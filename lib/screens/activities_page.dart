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
  static const Color primaryStone = Color(0xFF4E342E); 
  static const Color accentGold = Color(0xFFFFD700); 
  static const Color backgroundBeige = Color(0xFFFFF8F0); 
  
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFB71C1C); 
  static const Color contactGreen = Color(0xFF00C853); 
}

// 2. نموذج بيانات الحدث/الفعالية
class ChurchEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String contactPhone;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.contactPhone,
  });

  factory ChurchEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final timestamp = data?['date'] as Timestamp?;
    
    if (data == null) {
      debugPrint('Error parsing document ${doc.id}: Data is null.');
      throw const FormatException('Data is null.');
    }

    return ChurchEvent(
      id: doc.id,
      title: data['title'] as String? ?? 'حدث غير صالح',
      description: data['description'] as String? ?? 'البيانات مفقودة أو غير صالحة',
      date: timestamp?.toDate() ?? DateTime.now(), 
      location: data['location'] as String? ?? 'غير محدد',
      contactPhone: data['contactPhone'] as String? ?? '', // رقم هاتف المشرف
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date), 
      'location': location,
      'contactPhone': contactPhone,
    };
  }
}

// =========================================================
// II. الصفحة الرئيسية (ActivitiesPage)
// =========================================================

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false; 
  bool _isMeetingsManager = false;
  bool _isLoading = true; 
  bool _isLocaleInitialized = false; 
  
  bool get _canEdit => _isAdmin || _isMeetingsManager; 

  // الثابت الذي يحدد مسار Firebase (يستخدم للوصول إلى CollectionReference في كل مكان)
  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
  late final CollectionReference _eventsCollection;
  
  // دالة مساعدة للحصول على مسار مجموعة الأحداث (للتعديل من كارت الحدث)
  CollectionReference get _getEventsCollection => 
    _firestore.collection('artifacts').doc(appId).collection('public').doc('data').collection('events');


  @override
  void initState() {
    super.initState();
    
    _eventsCollection = _getEventsCollection; // تعيين مسار المجموعة
    
    _initializeLocale();
    _setupAuthListener(); 
  }
  
  Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      
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
  
  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _checkAdminStatus(user.uid);
      } else {
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
    if (!_isLocaleInitialized || _isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBeige,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryStone)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige, 
      appBar: AppBar(
        title: const Text(
          '🎉 الأنشطة والفعاليات', 
          style: TextStyle(
            color: AppColors.accentGold, 
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )
        ),
        backgroundColor: AppColors.primaryStone, 
        elevation: 8, 
        shadowColor: AppColors.primaryStone.withOpacity(0.5),
        centerTitle: true,
      ),
      
      body: _EventsList(eventsCollection: _eventsCollection, canEdit: _canEdit, appId: appId),

      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddEvent,
              label: const Text('إضافة فعالية', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              icon: const Icon(Icons.add_location_alt_rounded),
              backgroundColor: AppColors.primaryStone, 
              foregroundColor: AppColors.accentGold, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
              elevation: 10, 
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// =========================================================
// III. مكونات الأحداث والفعاليات (Events) 
// =========================================================

class _EventsList extends StatelessWidget {
  final CollectionReference eventsCollection;
  final bool canEdit; 
  final String appId; // 🆕 لتمريرها إلى كارت الحدث للوصول إلى CollectionReference في دالة التعديل
  const _EventsList({required this.eventsCollection, required this.canEdit, required this.appId}); 

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
      stream: eventsCollection.snapshots(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryStone)); 
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
        
        events.sort((a, b) => a.date.compareTo(b.date));


        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _EventCard(
              event: events[index],
              canEdit: canEdit,
              onDelete: () => _deleteEvent(context, events[index].id),
              eventsCollection: eventsCollection, // 🆕 تمرير الـ CollectionReference هنا
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final ChurchEvent event;
  final bool canEdit; 
  final VoidCallback onDelete;
  final CollectionReference eventsCollection; // 🆕 مطلوب لتمريرها لشاشة التعديل

  const _EventCard({
    required this.event, 
    required this.canEdit, 
    required this.onDelete,
    required this.eventsCollection,
  }); 

  Widget _buildDetailRow(IconData icon, String label, String value, {Color iconColor = AppColors.primaryStone, Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Icon(icon, color: iconColor, size: 20), 
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  fontSize: 14, 
                  color: onTap != null ? AppColors.contactGreen : AppColors.textSecondary,
                  decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                  fontWeight: onTap != null ? FontWeight.bold : FontWeight.normal
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // void _launchCaller(BuildContext context, String phoneNumber) async {
  //    ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('📞 محاولة الاتصال بـ: $phoneNumber')),
  //     );
  // }
  
  // 💡 دالة لفتح شاشة التعديل
  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditEventScreen(
          event: event,
          eventsCollection: eventsCollection,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd | hh:mm a', 'ar');
    final formattedDate = formatter.format(event.date);

    final bool isPastEvent = event.date.isBefore(DateTime.now());
    final bool isPhoneAvailable = event.contactPhone.isNotEmpty;
    
    // 💡 الآن يمكن النقر على الكارت إذا كان المستخدم يمتلك صلاحية التعديل والفعالية لم تنتهِ
    return InkWell( 
      onTap: canEdit && !isPastEvent ? () => _navigateToEdit(context) : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10.0), 
        elevation: 8, 
        shadowColor: AppColors.primaryStone.withOpacity(0.4), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: AppColors.accentGold.withOpacity(0.7), width: 1.5), 
        ),
        color: isPastEvent ? AppColors.backgroundBeige : AppColors.cardColor, 
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
                        fontSize: 20, 
                        fontWeight: FontWeight.w900, 
                        color: isPastEvent ? AppColors.textSecondary : AppColors.textPrimary,
                        decoration: isPastEvent ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                  
                  _buildDetailRow(Icons.access_time_filled, 'الموعد', formattedDate),
                  _buildDetailRow(Icons.location_on, 'المكان', event.location),
                  
                  // 🆕 سطر رقم التواصل الجديد
                  if (isPhoneAvailable)
                    _buildDetailRow(
                      Icons.phone, 
                      'تواصل المشرف', 
                      event.contactPhone, 
                    )
                  else
                     _buildDetailRow(
                      Icons.phone_disabled, 
                      'تواصل المشرف', 
                      'غير متاح', 
                      iconColor: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ],
        ),
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
        color: AppColors.alertRed.withOpacity(0.15), 
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
      color: AppColors.primaryStone.withOpacity(0.15), 
      child: Text(
        _formatDuration(_timeRemaining),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900, 
          color: AppColors.primaryStone, 
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// =========================================================
// IV. شاشة إضافة فعالية (AddEventScreen) - (غلاف للاستمارة)
// =========================================================
class AddEventScreen extends StatelessWidget {
  final CollectionReference eventsCollection;
  const AddEventScreen({super.key, required this.eventsCollection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('إضافة فعالية جديدة', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryStone,
        centerTitle: true,
        elevation: 8,
      ),
      body: AddEditEventForm(eventsCollection: eventsCollection),
    );
  }
}

// =========================================================
// V. شاشة تعديل فعالية (EditEventScreen) - (غلاف للاستمارة)
// =========================================================
class EditEventScreen extends StatelessWidget {
  final ChurchEvent event;
  final CollectionReference eventsCollection;
  
  const EditEventScreen({super.key, required this.event, required this.eventsCollection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('تعديل الفعالية', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryStone,
        centerTitle: true,
        elevation: 8,
      ),
      body: AddEditEventForm(
        eventsCollection: eventsCollection,
        initialEvent: event,
      ), 
    );
  }
}

// =========================================================
// VI. مكون الفورم المشترك (AddEditEventForm) 
// =========================================================

class AddEditEventForm extends StatefulWidget {
  final CollectionReference eventsCollection;
  final ChurchEvent? initialEvent; 

  const AddEditEventForm({
    super.key,
    required this.eventsCollection,
    this.initialEvent,
  });

  @override
  State<AddEditEventForm> createState() => _AddEditEventFormState();
}

class _AddEditEventFormState extends State<AddEditEventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactPhoneController;
  
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    
    _titleController = TextEditingController(text: event?.title);
    _descriptionController = TextEditingController(text: event?.description);
    _locationController = TextEditingController(text: event?.location);
    _contactPhoneController = TextEditingController(text: event?.contactPhone);
    
    _selectedDate = event?.date ?? DateTime.now().add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)), // 3 سنوات سابقة
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryStone,
              onPrimary: AppColors.accentGold,
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryStone,
              onPrimary: AppColors.accentGold,
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

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (FirebaseAuth.instance.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: يجب أن تكون مصادقاً عليه.')),
          );
        }
        return;
      }
      
      setState(() { _isLoading = true; });

      final newEventData = ChurchEvent(
        id: widget.initialEvent?.id ?? '', 
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        location: _locationController.text,
        contactPhone: _contactPhoneController.text.trim(), 
      ).toFirestore();

      try {
        if (isEditing) {
          await widget.eventsCollection.doc(widget.initialEvent!.id).update(newEventData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ تم تعديل الفعالية بنجاح!')),
            );
          }
        } else {
          await widget.eventsCollection.add(newEventData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ تم إضافة الفعالية بنجاح!')),
            );
          }
        }
        if (mounted) Navigator.pop(context);

      } catch (e) {
        debugPrint('Save Event Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ فشل الحفظ: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: AppColors.accentGold), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.textSecondary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryStone, width: 2.5), 
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'هذا الحقل مطلوب.';
        }
        if (keyboardType == TextInputType.phone && value != null && value.isNotEmpty) {
          if (!RegExp(r'^[0-9+ ]+$').hasMatch(value.trim())) {
            return 'الرجاء إدخال رقم هاتف صحيح (أرقام فقط، مع أو بدون علامة +).';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDateTime = DateFormat('EEEE, d MMMM yyyy, hh:mm a', 'ar').format(_selectedDate);
    final buttonText = isEditing ? 'حفظ التعديلات' : 'إضافة الفعالية';

    return SingleChildScrollView(
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
            const SizedBox(height: 20),

            _buildTextFormField(
              controller: _contactPhoneController,
              label: 'رقم هاتف المشرف للتواصل (اختياري)',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              isRequired: false, 
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
                  icon: const Icon(Icons.edit_calendar, color: AppColors.primaryStone),
                  label: const Text(
                    'تعديل التاريخ والوقت',  
                    style: TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold) 
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.primaryStone, thickness: 0.5, height: 30),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveEvent,
              icon: _isLoading 
                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 4))
                  : Icon(isEditing ? Icons.save : Icons.event_note, color: AppColors.accentGold),
              label: Text(
                _isLoading ? 'جاري الحفظ...' : buttonText,
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
    );
  }
}