import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

// ***************************************************************
// ⚠️ ملاحظة هامة: يجب أن يتم توفير هذه المتغيرات بشكل صحيح 
// في بيئة التشغيل الخاصة بك (مثل Canvas) لكي يعمل Firestore.
// ***************************************************************
// متغيرات البيئة - لا يجب تغييرها إلا في إعدادات البيئة الخارجية
const String __app_id = 'default-app-id';
const String __initial_auth_token = ''; 

// متغيرات Firebase الافتراضية - يرجى التأكد من صحتها في بيئتك
const Map<String, dynamic> _firebaseConfig = {
  // استخدم القيم الفعلية من إعدادات مشروعك
  "apiKey": "YOUR_API_KEY", 
  "appId": "YOUR_APP_ID",
  "messagingSenderId": "YOUR_MESSAGING_SENDER_ID",
  "projectId": "YOUR_PROJECT_ID",
};

// ==============================================================================
// 1. نماذج البيانات (Data Models)
// ==============================================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // اللون البني الداكن
  static const Color secondaryGold = Color(0xFFFFF8E1); // لون ذهبي فاتح/بيج
  static const Color backgroundColor =  Color(0xFFFFF8F0); 
  static const Color cardColor = Colors.white;
  static const Color textSecondary = Color(0xFF757575);
  static const Color statusVisited = Colors.green; // لون رسالة النجاح
  static const Color textPrimary = Color(0xFF212121);
    static const Color backgroundBeige = Color(0xFFFFF8F0); 

}
// نموذج الفصل الدراسي
class SundaySchoolClass {
  final String id;
  String name;
  int order; 

  SundaySchoolClass({required this.id, required this.name, required this.order});

  factory SundaySchoolClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SundaySchoolClass(
      id: doc.id,
      name: data['name'] ?? 'فصل غير مسمى',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'order': order,
      };
}

// نموذج التلميذ
class Student {
  final String id;
  String classId;
  String name;
  String address;
  String phone;
  String parentPhone;
  DateTime? dob; 
  String schoolYear;
  String notes;

  Student({
    required this.id,
    required this.classId,
    required this.name,
    this.address = '',
    this.phone = '',
    this.parentPhone = '',
    this.dob,
    this.schoolYear = '',
    this.notes = '',
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      classId: data['classId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      parentPhone: data['parentPhone'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate(),
      schoolYear: data['schoolYear'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'classId': classId,
        'name': name,
        'address': address,
        'phone': phone,
        'parentPhone': parentPhone,
        'dob': dob != null ? Timestamp.fromDate(dob!) : null,
        'schoolYear': schoolYear,
        'notes': notes,
      };
}

// نموذج تسجيل الحضور
class AttendanceRecord {
  final String id; // (studentId_YYYY-MM-DD)
  final String studentId;
  final DateTime date;
  bool isClassPresent; 
  bool isLiturgyPresent; 
  bool isFather; 
  bool isTrip; // تسجيل حضور الاجتماع

  
  Map<String, bool> events; 

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    this.isClassPresent = false,
    this.isLiturgyPresent = false,
    this.isFather = false,
        this.isTrip = false,



    
    this.events = const {},
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isClassPresent: data['isClassPresent'] ?? false,
      isLiturgyPresent: data['isLiturgyPresent'] ?? false,
            isFather: data['isFather'] ?? false,
            isTrip: data['isTrip'] ?? false,


      
      events: Map<String, bool>.from(data['events'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'date': Timestamp.fromDate(date),
        'isClassPresent': isClassPresent,
        'isLiturgyPresent': isLiturgyPresent,
        'isFather': isFather,
        'isTrip': isTrip,


        'events': events,
      };
}

// ==============================================================================
// 2. خدمة Firestore (CRUD Operations)
// ==============================================================================

class SundaySchoolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // دالة مساعدة لإنشاء مرجع المجموعة بالمسار الصحيح
  CollectionReference? _getCollectionDirect(String collectionName) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    // المسار الصحيح: artifacts/{appId}/users/{userId}/sunday_school_{collectionName}
return _db.collection('artifacts/$__app_id/public/data/sunday_school_$collectionName');  }

  // المراجع للمجموعات
  CollectionReference? get _classesCollection => _getCollectionDirect('classes');
  CollectionReference? get _studentsCollection => _getCollectionDirect('students');
  CollectionReference? get _attendanceCollection => _getCollectionDirect('attendance');


  // ------------------------------------
  // أ. إدارة الفصول (Classes CRUD)
  // ------------------------------------

// ... في كلاس SundaySchoolService

// مرجع لمجموعة الصلاحيات
CollectionReference? get _userRolesCollection {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return null;
  // المسار: artifacts/{appId}/public/data/user_roles
  return _db.collection('users');
}

// دالة جلب حالة الـ high_admin
Stream<bool> getHighAdminStatus() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
    return Stream.value(false);
  }
  final userDocRef = _db.collection('users').doc(userId);

  
  return _userRolesCollection!.doc(userId).snapshots().map((doc) {
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      // افتراض أن حقل الصلاحية اسمه 'high_admin'
return (data?['highAdminSundaySchool'] is bool) ? data!['highAdminSundaySchool'] : false;
    }
    
    return false;
  });
}



  Future<void> addClass(SundaySchoolClass classItem) async {
    try {
      if (_classesCollection == null) {
        throw Exception('User not authenticated for Firestore access (Classes).');
      }
      await _classesCollection!.add(classItem.toFirestore());
    } catch (e) {
      log('خطأ في إضافة الفصل: $e');
      rethrow;
    }
  }

  Future<void> updateClass(SundaySchoolClass classItem) async {
    try {
      if (_classesCollection == null) {
        throw Exception('User not authenticated for Firestore access (Classes).');
      }
      await _classesCollection!.doc(classItem.id).update(classItem.toFirestore());
    } catch (e) {
      log('خطأ في تحديث الفصل: $e');
      rethrow;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      if (_classesCollection == null) {
        throw Exception('User not authenticated for Firestore access (Classes).');
      }
      await _classesCollection!.doc(classId).delete();
    } catch (e) {
      log('خطأ في حذف الفصل: $e');
      rethrow;
    }
  }
Stream<List<AttendanceRecord>> getAttendanceForMonth(
    String studentId, DateTime start, DateTime end) {
  if (_attendanceCollection == null) return Stream.value([]);
  
  return _attendanceCollection!
      .where('studentId', isEqualTo: studentId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList());
}

  // الحصول على قائمة الفصول مرتبة حسب 'order' محلياً
  Stream<List<SundaySchoolClass>> getClasses() {
    if (_classesCollection == null) {
      return Stream.value([]);
    }
    
    return _classesCollection!.snapshots().map((snapshot) {
      final classes = snapshot.docs
          .map((doc) => SundaySchoolClass.fromFirestore(doc))
          .toList();
      classes.sort((a, b) => a.order.compareTo(b.order));
      return classes;
    });
  }

  // ------------------------------------
  // ب. إدارة التلاميذ (Students CRUD)
  // ------------------------------------

  Future<void> addStudent(Student student) async {
    try {
      if (_studentsCollection == null) {
        throw Exception('User not authenticated for Firestore access (Students).');
      }
      await _studentsCollection!.add(student.toFirestore());
    } catch (e) {
      log('خطأ في إضافة التلميذ: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      if (_studentsCollection == null) {
        throw Exception('User not authenticated for Firestore access (Students).');
      }
      await _studentsCollection!.doc(student.id).update(student.toFirestore());
    } catch (e) {
      log('خطأ في تحديث التلميذ: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      if (_studentsCollection == null) {
        throw Exception('User not authenticated for Firestore access (Students).');
      }
      await _studentsCollection!.doc(studentId).delete();
    } catch (e) {
      log('خطأ في حذف التلميذ: $e');
      rethrow;
    }
  }

  // الحصول على تلاميذ فصل معين وفرزهم محلياً حسب الاسم
  Stream<List<Student>> getStudentsByClass(String classId) {
    if (_studentsCollection == null) {
      return Stream.value([]);
    }
    
    final query = _studentsCollection!
        .where('classId', isEqualTo: classId);

    return query.snapshots().map((snapshot) {
      final students = snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
      students.sort((a, b) => a.name.compareTo(b.name));
      return students;
    });
  }

  // الحصول على كل التلاميذ (لتقرير أعياد الميلاد)
  Stream<List<Student>> getAllStudents() {
    if (_studentsCollection == null) {
      return Stream.value([]);
    }
    return _studentsCollection!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    });
  }


  // ------------------------------------
  // ج. إدارة الحضور
  // ------------------------------------

  // تسجيل حضور/غياب تلميذ ليوم معين
  Future<void> recordAttendance(AttendanceRecord record) async {
    try {
      if (_attendanceCollection == null) {
        throw Exception('User not authenticated for Firestore access (Attendance).');
      }
      await _attendanceCollection!.doc(record.id).set(record.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      log('خطأ في تسجيل الحضور: $e');
      rethrow;
    }
  }
Future<AttendanceRecord?> getAttendanceForDay(String studentId, DateTime date) async {
    if (_attendanceCollection == null) {
      return null;
    }
    
    final dateString = '${date.year}-${date.month}-${date.day}';
    final recordId = '${studentId}_$dateString';
    
    try {
      final doc = await _attendanceCollection!.doc(recordId).get();
      if (doc.exists) {
        return AttendanceRecord.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('خطأ في جلب سجل الحضور: $e');
      return null;
    }
}
  // الحصول على سجل حضور تلميذ في يوم معين (للتحديث)
Stream<AttendanceRecord?> getAttendanceStreamForDay(String studentId, DateTime date) {
    if (_attendanceCollection == null) {
        return Stream.value(null);
    }
    
    final dateString = '${date.year}-${date.month}-${date.day}';
    final recordId = '${studentId}_$dateString';
    
    // 💡 استخدام snapshots().map ليتم تحديث الواجهة فوراً عند أي تغيير في هذا المستند
    return _attendanceCollection!.doc(recordId).snapshots().map((doc) {
        if (doc.exists) {
            return AttendanceRecord.fromFirestore(doc);
        }
        // إرجاع قيمة null أو Record افتراضي لتجنب الأخطاء
        return null;
    }).handleError((e) {
        log('خطأ في جلب سجل الحضور (Stream): $e');
        return null;
    });
}
}

// ==============================================================================
// 3. واجهة المستخدم (UI) - مع تحسينات التصميم والحركات
// ==============================================================================

final SundaySchoolService _service = SundaySchoolService();

class SundaySchoolHome extends StatefulWidget {
  const SundaySchoolHome({super.key});

  @override
  State<SundaySchoolHome> createState() => _SundaySchoolHomeState();
}
class _SundaySchoolHomeState extends State<SundaySchoolHome> with TickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  int _currentLength = 3; // تتبع الطول الحالي
@override
  void initState() {
    super.initState();
    // تهيئة مبدئية للطول الأقصى (3 تبويبات)
    _tabController = TabController(length: _currentLength, vsync: this);
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  // دالة مساعدة لإعادة تهيئة TabController بأمان
  void _updateTabController(int newLength) {
    if (newLength <= 0) return; // منع الأخطاء إذا كان الطول صفراً

    // ⚠️ يتم التحديث فقط إذا تغير الطول
    if (_currentLength != newLength) {
      // 1. التخلص من الكنترولر القديم
      _tabController.dispose();
      
      // 2. تحديث الطول وتعيين كنترولر جديد
      _currentLength = newLength;
      _tabController = TabController(length: _currentLength, vsync: this);
      
      // 3. إعادة رسم الواجهة بالكنترولر الجديد
      if (mounted) {
        
        // لا نحتاج لـ setState هنا لأننا استدعينا dispose
        // وaddPostFrameCallback في build سيؤدي لـ setState
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  

@override
Widget build(BuildContext context) {
    if (_user == null) {
        return const Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
        );
    }
    
    // 💡 استخدام StreamBuilder لمراقبة الصلاحية
    return StreamBuilder<bool>(
        stream: _service.getHighAdminStatus(),
        initialData: false, // قيمة مبدئية
        builder: (context, snapshot) {
            final isHighAdmin = snapshot.data ?? false; // حالة الصلاحية
            
            // تحديد قائمة علامات التبويب والشاشات
            final List<Tab> adminTabs = [ 
                const Tab(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.class_, color: AppColors.secondaryGold), Text('الفصول', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12))])),
            ];
            final List<Widget> adminScreens = [
                ClassesScreen(),
            ];
            
            final List<Tab> regularTabs = [
                const Tab(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_box_outlined, color: AppColors.secondaryGold), Text('الحضور', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12))])),
                const Tab(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cake_outlined, color: AppColors.secondaryGold), Text('أعياد الميلاد', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12))])),
            ];
            final List<Widget> regularScreens = [
                const AttendanceScreen(),
                const BirthdaysScreen(),
            ];
            
            // تجميع القوائم حسب الصلاحية
           final List<Tab> allTabs = isHighAdmin ? [...adminTabs, ...regularTabs] : regularTabs;
            final List<Widget> allScreens = isHighAdmin ? [...adminScreens, ...regularScreens] : regularScreens;
            
            // ✅ استخدام الدالة المساعدة لإعادة التهيئة بأمان خارج شجرة البناء المباشرة
            // هذا سيؤدي إلى إعادة تشغيل الـ build في الدورة التالية بالـ _currentLength المحدث
          WidgetsBinding.instance.addPostFrameCallback((_) {
                 // يجب التأكد من استدعاء setState هنا إذا لم تقم _updateTabController بذلك
                 // وبما أنها لا تستدعي setState الآن، يجب أن نفعّلها هنا لتحديث الواجهة.
                if (allTabs.length != _currentLength) {
                    _updateTabController(allTabs.length);
                    if (mounted) {
                        setState(() {}); // لإجبار الواجهة على استخدام الطول الجديد في الدورة التالية
                    }
                }
            });
            
            // 🛑 الشرط الآمن: يتم العرض فقط إذا كان طول الكنترولر متطابقاً مع عدد الـ Tabs الفعلية
            final bool isLengthMatch = allTabs.length == _currentLength;
            if (!isLengthMatch) {
              // عرض مؤشر التحميل أثناء الانتقال بين الصلاحيات/الأطوال
              return const Scaffold(
                // ... (عرض مؤشر تحميل مؤقت)
                body:  Center(child: CircularProgressIndicator()),
              );
            }
            return Scaffold(
                backgroundColor: AppColors.backgroundBeige,
                appBar: AppBar(
                    title: const Text('مدارس الاحد', style: TextStyle(color: AppColors.secondaryGold)),
                    centerTitle: true,
                    backgroundColor: AppColors.primaryBlue,
                    // 1. عرض TabBar فقط إذا كان الطول متطابقاً
                    bottom: isLengthMatch ? TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                        tabs: allTabs, 
                    ) : null, // إذا لم يتساو الطول، لا تعرض الـ TabBar مؤقتاً
                ),
                // 2. عرض TabBarView فقط إذا كان الطول متطابقاً
                body: isLengthMatch ? TabBarView(
                    controller: _tabController,
                    children: allScreens, 
                ) : const Center(child: CircularProgressIndicator()), // أثناء التحديث، نعرض مؤشر تحميل
            );
        },
    );
}

}

// ==============================================================================
// الشاشة 1: إدارة الفصول
// ==============================================================================

class ClassesScreen extends StatelessWidget {
  ClassesScreen({super.key});

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showClassDialog(BuildContext context, {SundaySchoolClass? classItem}) {
    _nameController.text = classItem?.name ?? '';
    _orderController.text = classItem?.order.toString() ?? '0';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(classItem == null ? 'إضافة فصل جديد' : 'تعديل الفصل'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الفصل (مثل: أولى ابتدائي)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ترتيب الفصل', border: OutlineInputBorder()),
                validator: (value) {
                  if (value!.isEmpty || int.tryParse(value) == null) {
                    return 'يجب إدخال رقم صحيح للترتيب';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newClass = SundaySchoolClass(
                  id: classItem?.id ?? '',
                  name: _nameController.text,
                  order: int.parse(_orderController.text),
                );

                try {
                  if (classItem == null) {
                    await _service.addClass(newClass);
                  } else {
                    await _service.updateClass(newClass);
                  }
                  Navigator.pop(ctx);
                } catch (e) {
                  // يمكن عرض رسالة خطأ
                  log('Dialog Error: $e');
                }
              }
            },
            child: Text(classItem == null ? 'إضافة' : 'حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SundaySchoolClass classItem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الفصل "${classItem.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              try {
                await _service.deleteClass(classItem.id);
              } catch (e) {
                log('Failed to delete class: $e');
              }
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
              backgroundColor: AppColors.backgroundBeige, // ✅ تم تطبيق الخلفية البيج

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addClassBtn',
        onPressed: () => _showClassDialog(context),
        label: const Text('إضافة فصل جديد', style: TextStyle(color: AppColors.secondaryGold)),
        icon: const Icon(Icons.add, color: AppColors.secondaryGold),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: StreamBuilder<List<SundaySchoolClass>>(
        stream: _service.getClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {return const Center(child: CircularProgressIndicator());}
          if (snapshot.hasError) {return Center(child: Text('خطأ في جلب الفصول: ${snapshot.error}'));}
          final classes = snapshot.data ?? [];
          if (classes.isEmpty) {
            return Center(
              child: Column(
                
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لم يتم إضافة أي فصول بعد.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showClassDialog(context),
                    icon: const Icon(Icons.add_box),
                    label: const Text('إضافة أول فصل'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classItem = classes[index];
              return Card(
                
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue, width: 2),
                    ),
                    child: Center(child: Text('${classItem.order}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 16))),
                  ),
                  title: Text(classItem.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Text('الترتيب: ${classItem.order}', style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppColors.primaryBlue),onPressed: () => _showClassDialog(context, classItem: classItem),),
                     ///////// IconButton(icon: const Icon(Icons.delete, color: Colors.red),onPressed: () => _confirmDelete(context, classItem),),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsScreen(classItem: classItem),),);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==============================================================================
// الشاشة 2: إدارة التلاميذ
// ==============================================================================

class StudentsScreen extends StatelessWidget {
  final SundaySchoolClass classItem;
  const StudentsScreen({super.key, required this.classItem});

  void _showStudentDialog(BuildContext context, {Student? student}) {
    final isNew = student == null;
    final formKey = GlobalKey<FormState>();
    
    // لتبسيط المثال، نستخدم نموذج StudentData هنا
    String name = student?.name ?? '';
    String address = student?.address ?? '';
    String phone = student?.phone ?? '';
    String parentPhone = student?.parentPhone ?? '';
    DateTime? dob = student?.dob;
    String schoolYear = student?.schoolYear ?? '';
    String notes = student?.notes ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        
        title: Text(isNew ? 'إضافة تلميذ جديد' : 'تعديل بيانات: ${student.name}'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: 'الاسم كاملاً', border: OutlineInputBorder()),
                        onChanged: (v) => name = v,
                        validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: address,
                        decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                        onChanged: (v) => address = v,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'رقم هاتف التلميذ', border: OutlineInputBorder()),
                        onChanged: (v) => phone = v,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: parentPhone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'رقم هاتف الأب/الولي', border: OutlineInputBorder()),
                        onChanged: (v) => parentPhone = v,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                        title: Text(dob == null ? 'تاريخ الميلاد' : 'تاريخ الميلاد: ${dob!.year}-${dob!.month}-${dob!.day}'),
                        trailing: const Icon(Icons.calendar_today, color: Color(0xFF00ACC1)),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime.now(),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() => dob = pickedDate);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: schoolYear,
                        decoration: const InputDecoration(labelText: 'السنة الدراسية', border: OutlineInputBorder()),
                        onChanged: (v) => schoolYear = v,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: notes,
                        decoration: const InputDecoration(labelText: 'معلومة إضافية', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => notes = v,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newStudent = Student(
                  id: student?.id ?? '',
                  classId: classItem.id,
                  name: name,
                  address: address,
                  phone: phone,
                  parentPhone: parentPhone,
                  dob: dob,
                  schoolYear: schoolYear,
                  notes: notes,
                );

                try {
                  if (isNew) {
                    await _service.addStudent(newStudent);
                  } else {
                    await _service.updateStudent(newStudent);
                  }
                  Navigator.pop(ctx);
                } catch (e) {
                  log('Student Dialog Error: $e');
                }
              }
            },
            child: Text(isNew ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف التلميذ "${student.name}" نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              try {
                await _service.deleteStudent(student.id);
              } catch (e) {
                log('Failed to delete student: $e');
              }
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
                            backgroundColor: AppColors.backgroundBeige, // ✅ تم تطبيق الخلفية البيج

      appBar: AppBar(
                backgroundColor: AppColors.primaryBlue,
                 centerTitle: true,

        title: Text(' ${classItem.name} : تلاميذ فصل', style: const TextStyle(color: AppColors.secondaryGold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addStudentBtn',
        onPressed: () => _showStudentDialog(context),
        label: const Text('إضافة تلميذ',style: TextStyle(color: AppColors.secondaryGold)),
        icon: const Icon(Icons.person_add,color: AppColors.secondaryGold),
        backgroundColor: AppColors.primaryBlue,

      ),
      body: StreamBuilder<List<Student>>(
        stream: _service.getStudentsByClass(classItem.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في جلب التلاميذ: ${snapshot.error}'));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(
              child: Text('لا يوجد تلاميذ في هذا الفصل بعد.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            
            
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('رقم الأب: ${student.parentPhone.isEmpty ? 'غير مسجل' : student.parentPhone}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info, color: Colors.blueGrey),
                        onPressed: () => _showStudentDialog(context, student: student),
                      ),
            ///////////////////////// IconButton(
                      //   icon: const Icon(Icons.delete, color: Colors.red),
                      //   onPressed: () => _confirmDelete(context, student),
                      // ),
                    ],
                  ),
                  onTap: () => _showStudentDialog(context, student: student),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==============================================================================
// 3. شاشة الحضور + التقرير الشهري
// ==============================================================================

enum AttendanceType { classPresent, liturgyPresent, father,isTrip}


class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  List<SundaySchoolClass> _classes = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchClasses() {
    _service.getClasses().listen((classes) {
      if (mounted) {
        setState(() {
          _classes = classes;
          if (_selectedClassId == null && _classes.isNotEmpty) {
            _selectedClassId = _classes.first.id;
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleAttendance(Student student, AttendanceType type, bool value) async {
    final dateString = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final recordId = '${student.id}_$dateString';

    AttendanceRecord? existingRecord =
        await _service.getAttendanceForDay(student.id, _selectedDate);

    AttendanceRecord record = existingRecord ??
        AttendanceRecord(
          id: recordId,
          studentId: student.id,
          date: _selectedDate,
        );

    switch (type) {
      case AttendanceType.classPresent:
        record.isClassPresent = value;
        break;
      case AttendanceType.liturgyPresent:
        record.isLiturgyPresent = value;
        break;
      case AttendanceType.father:
        record.isFather = value;
        break;
        case AttendanceType.isTrip:
        record.isTrip = value;
        break;
    }

    try {
      await _service.recordAttendance(record);
    } catch (e) {
      log('Failed to record attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'تسجيل الحضور'),
            Tab(text: 'التقرير الشهري'),
          ],
        ),

       Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAttendanceTab(context),
              // ✅ تمرير _selectedClassId إلى MonthlyReportScreen
              MonthlyReportScreen(classId: _selectedClassId), 
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    final formattedDate = "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";
    final selectedClass = _classes.firstWhere(
      (c) => c.id == _selectedClassId,
      orElse: () => SundaySchoolClass(id: '', name: 'حدد فصلاً', order: 0),
    );

    return Column(
      children: [
        // شريط التحكم
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            border: const Border(bottom: BorderSide(color: Color(0xFF00ACC1), width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'اختيار الفصل',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _classes.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

      Expanded(
          child: _selectedClassId == null
              ? const Center(child: Text('اختر فصلاً أولاً'))
              : StreamBuilder<List<Student>>(
                  stream: _service.getStudentsByClass(_selectedClassId!),
                  builder: (context, studentSnapshot) {
                    if (!studentSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final students = studentSnapshot.data!;
                    final dateString =
                        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];

                        // 🚀 التعديل الحاسم: استخدام StreamBuilder بدلاً من FutureBuilder
                        return StreamBuilder<AttendanceRecord?>(
                          stream: _service.getAttendanceStreamForDay(student.id, _selectedDate),
                          builder: (context, attendanceSnapshot) {
                            
                            // لا نستخدم انتظار، بل نستخدم آخر البيانات المتاحة
                            final record = attendanceSnapshot.data ??
                                AttendanceRecord(
                                    id: '${student.id}_$dateString',
                                    studentId: student.id,
                                    date: _selectedDate);

                            return AttendanceItem(
                                student: student,
                                record: record,
                                onToggle: (type, value) =>
                                    _toggleAttendance(student, type, value),
                              );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==============================================================================
// عنصر التلميذ في الحضور
// ==============================================================================
class AttendanceItem extends StatelessWidget {
  final Student student;
  final AttendanceRecord record;
  final Function(AttendanceType type, bool value) onToggle;

  const AttendanceItem({
    super.key,
    required this.student,
    required this.record,
    required this.onToggle,
  });

  Widget _buildToggleButton({
    required String label,
    required AttendanceType type,
    required bool isPresent,
    required Color activeColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: () => onToggle(type, !isPresent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isPresent ? activeColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPresent ? activeColor.withOpacity(0.5) : Colors.grey.shade400,
                width: isPresent ? 2 : 1,
              ),
              boxShadow: isPresent
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]
                  : null,
            ),
            child: Text(
              isPresent ? 'done' : label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPresent ? Colors.white : Colors.grey[700],
                fontWeight: isPresent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(student.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            _buildToggleButton(
              label: 'رحله',
              type: AttendanceType.isTrip,
              isPresent: record.isTrip,
              activeColor: const Color.fromARGB(255, 222, 209, 28),
            ),
            _buildToggleButton(
              label: 'اعتراف',
              type: AttendanceType.father,
              isPresent: record.isFather,
              activeColor: const Color.fromARGB(255, 28, 222, 96),
            ),
            _buildToggleButton(
              label: 'فصل',
              type: AttendanceType.classPresent,
              isPresent: record.isClassPresent,
              activeColor: Colors.blue.shade600,
            ),
            _buildToggleButton(
              label: 'قداس',
              type: AttendanceType.liturgyPresent,
              isPresent: record.isLiturgyPresent,
              activeColor: Colors.purple.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
// ==============================================================================
// 4. التقرير الشهري (تعديل: استلام classId)
// ==============================================================================
class MonthlyReportScreen extends StatefulWidget {
  // ✅ إضافة classId كمتطلب
  final String? classId; 
  const MonthlyReportScreen({super.key, required this.classId});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    // ⚠️ لا يمكن عرض التقرير بدون تحديد فصل
    if (widget.classId == null || widget.classId!.isEmpty) {
        return const Center(child: Text('الرجاء اختيار فصل لعرض تقريره الشهري.', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // الحصول على آخر يوم في الشهر
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0); 

    return Column(
      children: [
        // شريط اختيار الشهر
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
              ),
              Text(
                '${_currentMonth.year} - ${_currentMonth.month.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  // منع التنقل للمستقبل
                  if (_currentMonth.month < DateTime.now().month || _currentMonth.year < DateTime.now().year) {
                    setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  }
                },
              ),
            ],
          ),
        ),

       Expanded(
          // ✅ يجب أن يحتوي Expanded على وسيط child واحد
          child: StreamBuilder<List<Student>>( // ✅ StreamBuilder هو الـ child
            // ✅ وسيط 'stream' خاص بـ StreamBuilder
            stream: _service.getStudentsByClass(widget.classId!), 
            // ✅ وسيط 'builder' خاص بـ StreamBuilder
            builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ في جلب بيانات التلاميذ: ${snapshot.error}'));
            }

            final students = snapshot.data ?? [];

            if (students.isEmpty) {
              return const Center(
                  child: Text('لا يوجد تلاميذ في هذا الفصل لعرض التقرير.', style: TextStyle(fontSize: 16)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];

                return StreamBuilder<List<AttendanceRecord>>(
                  // جلب الحضور لهذا التلميذ في الشهر المحدد
                  stream: _service.getAttendanceForMonth(student.id, startOfMonth, endOfMonth),
                  builder: (context, attSnapshot) {
                    if (!attSnapshot.hasData) {
                      return const SizedBox();
                    }

                    final records = attSnapshot.data!;

                    // حساب الغياب لكل نوع
                    int classAbsent = records.where((r) => !r.isClassPresent).length;
                    int liturgyAbsent = records.where((r) => !r.isLiturgyPresent).length;
                    int fatherAbsent = records.where((r) => !r.isFather).length;

                     // تم حذف دالة print هنا لتجنب ظهورها في الكونسول
                    
                    // إظهار فقط إذا غاب 3 مرات أو أكثر في أي نوع
                    if (classAbsent < 3 && liturgyAbsent < 3 && fatherAbsent < 3) {
                      // ✅ تم تغييرها إلى SizedBox.shrink() لأداء أفضل
                      return const SizedBox.shrink(); 
                    }

                    return Card(
                      // ... (تصميم البطاقة لم يتغير)
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 6),
                            if (classAbsent >= 3)
                              Text('- الغياب عن الفصل: $classAbsent مرات',
                                  style: const TextStyle(color: Colors.red)),
                            if (liturgyAbsent >= 3)
                              Text('- الغياب عن القداس: $liturgyAbsent مرات',
                                  style: const TextStyle(color: Colors.red)),
                            if (fatherAbsent >= 3)
                              const Text('- الغياب عن الاعتراف: 1 مره',
                                  style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        )
      ],
    );
  }
}

// ==============================================================================
// الشاشة 4: أعياد الميلاد
// ==============================================================================
// ==============================================================================

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> {
  // ✅ ID للفصل المحدد، القيمة الافتراضية 'ALL' لجميع الفصول
  String? _selectedClassId = 'ALL'; 
  List<SundaySchoolClass> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  void _fetchClasses() {
    _service.getClasses().listen((classes) {
      if (mounted) {
        setState(() {
          _classes = classes;
        });
      }
    });
  }
  
  // دالة مساعدة لحساب كم يوماً متبقياً على عيد الميلاد (كما هي)
  int _daysUntilBirthday(DateTime? dob) {
    // ... (نفس المنطق السابق) ...
    if (dob == null) return -1;
    final now = DateTime.now();
    
    var nextBirthday = DateTime(now.year, dob.month, dob.day);

    if (nextBirthday.isBefore(now) && nextBirthday.day != now.day) {
      nextBirthday = DateTime(now.year + 1, dob.month, dob.day);
    }
    
    final difference = nextBirthday.difference(now);
    if (nextBirthday.day == now.day && nextBirthday.month == now.month) return 0;

    return difference.inDays;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ شريط اختيار الفصل
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedClassId,
            decoration: InputDecoration(
              labelText: 'فلترة حسب الفصل',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.cardColor,
            ),
            // ✅ إضافة خيار "كل الفصول"
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('كل الفصول')),
              ..._classes.map((c) {
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
              });
            },
          ),
        ),

        Expanded( // ✅ Expanded لملء المساحة
          child: StreamBuilder<List<Student>>(
            // ✅ نستخدم getAllStudents لجلب كل التلاميذ
            stream: _service.getAllStudents(), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في جلب البيانات: ${snapshot.error}'));
              }

              var allStudents = snapshot.data ?? [];
              
              // 1. تطبيق الفلترة حسب الفصل المختار
              if (_selectedClassId != 'ALL') {
                allStudents = allStudents.where((s) => s.classId == _selectedClassId).toList();
              }
              
              // 2. تصفية وحساب وفرز أعياد الميلاد القادمة خلال 60 يوماً
              var upcomingBirthdays = allStudents
                  .where((s) => s.dob != null)
                  .map((s) {
                    final days = _daysUntilBirthday(s.dob);
                    return {'student': s, 'daysLeft': days};
                  })
                  .where((item) => item['daysLeft'] as int >= 0 && item['daysLeft'] as int <= 60)
                  .toList();

              // 3. فرز حسب الأيام المتبقية (الأقرب أولاً)
              upcomingBirthdays.sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));

              if (upcomingBirthdays.isEmpty) {
                return Center(
                  child: Text(
                    _selectedClassId == 'ALL' 
                      ? 'لا توجد أعياد ميلاد قادمة في الـ 60 يوماً القادمة.'
                      : 'لا توجد أعياد ميلاد قادمة في هذا الفصل.', 
                    style: const TextStyle(fontSize: 16, color: Colors.grey)
                  ),
                );
              }

              // ... (بناء ListView.builder لعرض البطاقات) ...
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: upcomingBirthdays.length,
                itemBuilder: (context, index) {
                  final item = upcomingBirthdays[index];
                  final student = item['student'] as Student;
                  final daysLeft = item['daysLeft'] as int;

                  String subtitle;
                  IconData icon;
                  Color color;

                  if (daysLeft == 0) {
                    subtitle = 'يحتفل اليوم!';
                    icon = Icons.star;
                    color = Colors.red.shade600;
                  } else if (daysLeft <= 7) {
                    subtitle = 'متبقي $daysLeft أيام (قريباً جداً)';
                    icon = Icons.celebration;
                    color = Colors.orange.shade600;
                  } else {
                    subtitle = 'متبقي $daysLeft أيام';
                    icon = Icons.cake;
                    color = Colors.green.shade600;
                  }

                  // 💡 تصميم بطاقة عيد ميلاد مبهرة (بدون تغيير)
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: color.withOpacity(0.5), width: 2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      leading: Icon(icon, color: color, size: 35),
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: TextStyle(fontStyle: FontStyle.italic, color: color, fontWeight: FontWeight.w600),
                      ),
                      trailing: Chip(
                        label: Text(
                          '${student.dob!.day}/${student.dob!.month}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}