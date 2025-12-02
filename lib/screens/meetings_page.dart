// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
// Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// I. نموذج البيانات والثوابت
// =========================================================

// إعادة تعريف AppColors للاستخدام السريع في هذا الملف (للتكامل)
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundBeige = Color(0xFFFFF8F0); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

// نموذج بيانات الاجتماع
class Meeting {
  final String id;
  final String title;
  final String day;
  final String time;
  final String location;
  final String responsiblePerson;
  final Timestamp? timestamp;

  Meeting({
    required this.id,
    required this.title,
    required this.day,
    required this.time,
    required this.location,
    required this.responsiblePerson,
    this.timestamp,
  });

  // قائمة ترتيب الأيام للفرز
  static const Map<String, int> _dayOrder = {
    'الأحد': 1, 'الإثنين': 2, 'الثلاثاء': 3, 'الأربعاء': 4,
    'الخميس': 5, 'الجمعة': 6, 'السبت': 7, 'غير محدد': 8,
  };

  // من Firebase: تحويل DocumentSnapshot إلى نموذج
  factory Meeting.fromMap(Map<String, dynamic> data, String id) {
    return Meeting(
      id: id,
      title: data['title'] ?? 'اجتماع غير محدد',
      day: data['day'] ?? 'غير محدد',
      time: data['time'] ?? 'غير محدد',
      location: data['location'] ?? 'غير محدد',
      responsiblePerson: data['responsiblePerson'] ?? 'غير محدد',
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  // للتحويل إلى Map لحفظه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'day': day,
      'time': time,
      'location': location,
      'responsiblePerson': responsiblePerson,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // دالة فرز مخصصة (الفرز حسب اليوم ثم الوقت كنص)
  int compareTo(Meeting other) {
    final dayA = _dayOrder[day] ?? 9;
    final dayB = _dayOrder[other.day] ?? 9;
    
    if (dayA != dayB) {
      return dayA.compareTo(dayB);
    }
    
    return time.compareTo(other.time);
  }
}

// =========================================================
// WIDGET DUMMY: AppDrawer (تم إنشاؤه لضمان تشغيل الكود)
// =========================================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: Center(
        child: Text('قائمة التطبيق'),
      ),
    );
  }
}

// =========================================================
// II. صفحة الاجتماعات الرئيسية (MeetingsPage)
// =========================================================

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  // حالة Firebase و Auth
  late FirebaseFirestore _db;
  late FirebaseAuth _auth;
  String? _userId;
  bool _isLoading = true;
  
  // المتغير لتخزين حالة isAdmin من Firestore
  bool _isAdminStatus = false; 

  // القائمة الرئيسية للاجتماعات التي يتم سحبها من Firestore
  List<Meeting> _meetings = [];

  // ✅ المنطق: تحقق مما إذا كان المستخدم مسؤولاً (بناءً على UID وحالة Firestore)
  bool get _isAdmin => _userId != null && _isAdminStatus;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndListen();
  }

  // =========================================================
  // وظائف Firebase
  // =========================================================
// دالة فحص صلاحيات المستخدم في Firestore
Future<void> _checkAdminStatus(String uid) async {
  try {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();

    // 💡 التعديل هنا: نقرأ حالة الأدمن وحالة "الراعي"
    final bool isAdmin = data?['isAdmin'] ?? false;
    final bool isRector = data?['IsRectorofMeetings'] ?? false; 
    
    // نحدد ما إذا كان يمتلك أي صلاحية تعديل
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

      // 1. الاستماع لتغييرات حالة المصادقة (Auth State Changes)
      _auth.authStateChanges().listen((User? user) async {
        if (mounted) {
          setState(() {
            _userId = user?.uid;
          });
          
          if (user != null) {
            await _checkAdminStatus(user.uid);
          } else {
            setState(() {
              _isAdminStatus = false;
            });
             try {
               await _auth.signInAnonymously(); 
             } catch (e) {
                print('Anonymous Auth Failed: $e');
             }
          }
          
          print('Current Auth State User ID: $_userId (Is Admin: $_isAdmin)');
        }
      });
      
      // 2. بدء الاستماع للبيانات
      _startListeningToMeetings(); 

    } catch (e) {
      print('Firebase Initialization/Auth Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // دالة تُنشئ مسار مجموعة البيانات العامة
  CollectionReference get _meetingsCollection {
     // نفترض أن المجموعة تُسمى 'weekly_meetings'
     return _db.collection('weekly_meetings');
  }

  void _startListeningToMeetings() {
    _meetingsCollection.snapshots().listen((snapshot) {
      final updatedMeetings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>; 
        return Meeting.fromMap(data, doc.id);
      }).toList();
      
      // الفرز باستخدام دالة الفرز المخصصة
      updatedMeetings.sort((a, b) => a.compareTo(b));

      if (mounted) {
        setState(() {
          _meetings = updatedMeetings;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      print('Firestore Listen Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحميل الاجتماعات من قاعدة البيانات.')),
        );
      }
    });
  }

  // دالة الحذف
  void _deleteMeeting(String id) async {
    if (!_isAdmin) return;
    try {
      await _meetingsCollection.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الاجتماع بنجاح!')),
      );
    } catch (e) {
      print('Delete Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل حذف الاجتماع.')),
      );
    }
  }

  // دالة الإضافة/التعديل
  void _showMeetingForm({Meeting? meeting}) {
    if (!_isAdmin) return; // تأمين إضافي

    // القيم الأولية للنموذج
    String currentTitle = meeting?.title ?? '';
    String currentDay = meeting?.day ?? 'الأحد';
    String currentTime = meeting?.time ?? '7:00 مساءً';
    String currentLocation = meeting?.location ?? '';
    String currentResponsiblePerson = meeting?.responsiblePerson ?? '';

    // قائمة بالأيام المقترحة
    final List<String> days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    meeting == null ? '➕ إضافة اجتماع جديد' : '✏️ تعديل اجتماع',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: AppColors.secondaryGold),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView(
                      children: [
                        // حقل العنوان
                        TextFormField(
                          initialValue: currentTitle,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الاجتماع',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          onChanged: (value) => currentTitle = value,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 15),

                        // اختيار اليوم
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'اليوم',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          value: currentDay,
                          items: days.map((String day) {
                            return DropdownMenuItem<String>(
                              value: day,
                              child: Text(day),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setModalState(() {
                                currentDay = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 15),

                        // حقل الوقت 
                        TextFormField(
                          initialValue: currentTime,
                          decoration: const InputDecoration(
                            labelText: 'الوقت (مثال: 7:00 مساءً)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          onChanged: (value) => currentTime = value,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 15),

                        // حقل الموقع
                        TextFormField(
                          initialValue: currentLocation,
                          decoration: const InputDecoration(
                            labelText: 'الموقع (مثال: قاعة مارمرقس)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          onChanged: (value) => currentLocation = value,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 15),

                        // حقل المسؤول
                        TextFormField(
                          initialValue: currentResponsiblePerson,
                          decoration: const InputDecoration(
                            labelText: 'الشخص المسؤل',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          onChanged: (value) => currentResponsiblePerson = value,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () => _saveMeeting(
                      isUpdate: meeting != null,
                      id: meeting?.id,
                      title: currentTitle,
                      day: currentDay,
                      time: currentTime,
                      location: currentLocation,
                      responsiblePerson: currentResponsiblePerson,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 8,
                    ),
                    child: Text(
                      meeting == null ? 'إضافة الاجتماع' : 'حفظ التعديلات',
                      style: const TextStyle(color: AppColors.secondaryGold, fontSize: 16),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // حفظ/تحديث الاجتماع في Firestore
  void _saveMeeting({
    required bool isUpdate,
    String? id,
    required String title,
    required String day,
    required String time,
    required String location,
    required String responsiblePerson,
  }) async {
    if (title.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال عنوان الاجتماع.')));
       return;
    }
    
    final newMeeting = Meeting(
      id: id ?? '',
      title: title,
      day: day,
      time: time,
      location: location,
      responsiblePerson: responsiblePerson,
    );

    try {
      if (isUpdate && id != null) {
        // تحديث
        await _meetingsCollection.doc(id).update(newMeeting.toMap());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح.')));
      } else {
        // إضافة جديدة
        await _meetingsCollection.add(newMeeting.toMap());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الاجتماع الجديد بنجاح.')));
      }
    } catch (e) {
      print('Save Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل حفظ/تحديث الاجتماع.')));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBeige,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title:  Center(child: Text('🗓️ الاجتماعات الأسبوعية       ', style: TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold))),
        backgroundColor: AppColors.primaryBlue,
        elevation: 8, // زيادة الـ Elevation للأناقة
      ),

      // ✅ زر الإضافة العائم يظهر فقط للمسؤولين
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showMeetingForm(),
              label: const Text('إضافة اجتماع', style: TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_rounded, color: AppColors.secondaryGold),
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
            )
          : null, // لا يوجد زر للمستخدم العادي

      body: _MeetingList(
        meetings: _meetings,
        isAdmin: _isAdmin,
        onEdit: _showMeetingForm,
        onDelete: _deleteMeeting,
        userId: _userId,
        emptyMessage: _isAdmin
                ? '🎉 لا توجد اجتماعات مُجدولة. استخدم زر الإضافة لتبدأ.'
                : '🎉 لا توجد اجتماعات مُجدولة حالياً.',
      ),
    );
  }
}

// =========================================================
// III. ويدجت عرض القائمة (_MeetingList)
// =========================================================

class _MeetingList extends StatelessWidget {
  final List<Meeting> meetings;
  final bool isAdmin;
  final String emptyMessage;
  final String? userId; 

  final void Function({Meeting? meeting}) onEdit;
  final void Function(String) onDelete;

  const _MeetingList({
    required this.meetings,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.emptyMessage,
    this.userId,
  });

  // لعرض نافذة تأكيد الحذف
  void _showDeleteConfirmation(BuildContext context, Meeting meeting) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل أنت متأكد أنك تريد حذف اجتماع "${meeting.title}"؟', textAlign: TextAlign.right),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
            onPressed: () {
              onDelete(meeting.id);
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
    if (meetings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_alt_outlined, size: 60, color: AppColors.primaryBlue.withOpacity(0.5)),
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
      padding: const EdgeInsets.all(10.0),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return _MeetingCard(
          meeting: meeting, 
          isAdmin: isAdmin,
          onEdit: onEdit,
          onDeleteConfirmation: _showDeleteConfirmation,
        );
      },
    );
  }
}

// =========================================================
// IV. مكون البطاقة الواحدة للاجتماع (_MeetingCard) - التصميم المبهر
// =========================================================

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final bool isAdmin;
  final void Function({Meeting? meeting}) onEdit;
  final void Function(BuildContext, Meeting) onDeleteConfirmation;
  
  const _MeetingCard({
    required this.meeting,
    required this.isAdmin,
    required this.onEdit,
    required this.onDeleteConfirmation,
  });

  // دالة مساعدة لعرض تفاصيل الاجتماع بتصميم محسن
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // الأيقونة داخل دائرة ملونة لتمييزها
          Container( 
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.1),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 15),
          // العنوان الأساسي
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w800, // وزن خط أثقل
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          Expanded(
            // قيمة التفصيل
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ].reversed.toList(), // لضمان تدفق العناصر من اليمين لليسار
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      // Box Decoration لعمل الظل العميق والحواف الحديثة
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: isAdmin ? () => onEdit(meeting: meeting) : null,
        borderRadius: BorderRadius.circular(20),
        
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // الرأس الملون (القسم الأكثر تميزاً)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Text(
                meeting.title,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, // خط سميك جداً
                  color: AppColors.secondaryGold, // نص ذهبي على أزرق
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // قسم التفاصيل
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اليوم والوقت
                  _buildDetailRow(Icons.access_time_filled, 'اليوم والوقت', '${meeting.day}، ${meeting.time}'),
                  const Divider(color: AppColors.secondaryGold, thickness: 1, height: 25), 
                  // المكان
                  _buildDetailRow(Icons.location_on, 'المكان', meeting.location),
                  const Divider(color: AppColors.secondaryGold, thickness: 1, height: 25),
                  // المسؤول
                  _buildDetailRow(Icons.person_pin, 'المسئول', meeting.responsiblePerson),

                  // أزرار الإدارة
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // زر التعديل
                        ElevatedButton.icon(
                          onPressed: () => onEdit(meeting: meeting),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('تعديل', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: AppColors.secondaryGold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // زر الحذف
                        OutlinedButton.icon(
                          onPressed: () => onDeleteConfirmation(context, meeting),
                          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                          label: const Text('حذف', style: TextStyle(fontSize: 14, color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}