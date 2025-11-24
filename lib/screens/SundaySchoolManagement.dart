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
final String __initial_auth_token = ''; 

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
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textSecondary = Color(0xFF757575);
  static const Color statusVisited = Colors.green; // لون رسالة النجاح
  static const Color textPrimary = Color(0xFF212121);
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
  Map<String, bool> events; 

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    this.isClassPresent = false,
    this.isLiturgyPresent = false,
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
      events: Map<String, bool>.from(data['events'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'date': Timestamp.fromDate(date),
        'isClassPresent': isClassPresent,
        'isLiturgyPresent': isLiturgyPresent,
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
    return _db.collection('artifacts/${__app_id}/users/$userId/sunday_school_$collectionName');
  }

  // المراجع للمجموعات
  CollectionReference? get _classesCollection => _getCollectionDirect('classes');
  CollectionReference? get _studentsCollection => _getCollectionDirect('students');
  CollectionReference? get _attendanceCollection => _getCollectionDirect('attendance');


  // ------------------------------------
  // أ. إدارة الفصول (Classes CRUD)
  // ------------------------------------

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

  // الحصول على سجل حضور تلميذ في يوم معين (للتحديث)
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
}

// ==============================================================================
// 3. واجهة المستخدم (UI) - مع تحسينات التصميم والحركات
// ==============================================================================

final SundaySchoolService _service = SundaySchoolService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // تهيئة Firebase
    await Firebase.initializeApp(options: FirebaseOptions(
        apiKey: _firebaseConfig['apiKey']!,
        appId: _firebaseConfig['appId']!,
        messagingSenderId: _firebaseConfig['messagingSenderId']!,
        projectId: _firebaseConfig['projectId']!,
    ));
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    FirebaseFirestore.setLoggingEnabled(true);
    
    // محاولة تسجيل الدخول باستخدام الرمز المخصص أو كمجهول
    final auth = FirebaseAuth.instance;
    if (__initial_auth_token.isNotEmpty) {
      await auth.signInWithCustomToken(__initial_auth_token);
    } else {
      await auth.signInAnonymously();
    }
  } catch (e) {
    log('Firebase Initialization/Auth Error. Check your Firebase config: $e');
  }


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدارس الأحد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // لون أساسي مبهج (أزرق سماوي/أخضر)
        primarySwatch: Colors.cyan, 
        primaryColor: const Color(0xFF00BCD4), 
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00ACC1), // أزرق سماوي أغمق
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.cyan.shade600,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
        fontFamily: 'Inter', // افتراضياً
      ),
      home: const SundaySchoolHome(),
    );
  }
}

class SundaySchoolHome extends StatefulWidget {
  const SundaySchoolHome({super.key});

  @override
  State<SundaySchoolHome> createState() => _SundaySchoolHomeState();
}

class _SundaySchoolHomeState extends State<SundaySchoolHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1))),
      );
    }
    
    final uid = _user!.uid;

    return Scaffold(
      appBar: AppBar(
                title: const Text('مدارس الاحد'  , style: TextStyle(color: AppColors.secondaryGold)),                 centerTitle: true,


        backgroundColor: AppColors.primaryBlue,

        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 15),
            child: Center(
              child: Tooltip(
                message: 'معرّف المستخدم (UID) الحالي',
                child: Text(
                  'UID: ${uid.substring(0, 8)}...', 
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  
                ),
              ),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
      Tab(
        // ✅ استخدم خاصية child لدمج الأيقونة والنص وتخصيص الأنماط
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة (لونها AppColors.secondaryGold)
            Icon(Icons.class_, color: AppColors.secondaryGold), 
            // النص (لونه أبيض)
            const Text(
              'الفصول', 
              style: TextStyle(
                // يمكنك استخدام Colors.white بدلاً من الـ Hex
                color: Color(0xFFFFFFFF), 
                fontSize: 12, // حجم خط مناسب للـ Tab
              ),
            ),
          ],
        ),
      ),  

      Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة (لونها AppColors.secondaryGold)
              Icon(Icons.check_box_outlined, color: AppColors.secondaryGold),
              // النص (لونه أبيض)
              const Text(
                'الحضور', 
                style: TextStyle(
                  color: Color(0xFFFFFFFF), 
                  fontSize: 12, 
                ),
              ),
            ],
          ),
        ),    
          
      Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة (لونها AppColors.secondaryGold)
              Icon(Icons.cake_outlined, color: AppColors.secondaryGold),
              // النص (لونه أبيض)
              const Text(
                'أعياد الميلاد', 
                style: TextStyle(
                  color: Color(0xFFFFFFFF), 
                  fontSize: 12, 
                ),
              ),
            ],
          ),
        ),      
      ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClassesScreen(),
          AttendanceScreen(),
          BirthdaysScreen(),
        ],
      ),
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
                    child: Center(child: Text('${classItem.order}', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 16))),
                  ),
                  title: Text(classItem.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Text('الترتيب: ${classItem.order}', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppColors.primaryBlue),onPressed: () => _showClassDialog(context, classItem: classItem),),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red),onPressed: () => _confirmDelete(context, classItem),),
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
        
        title: Text(isNew ? 'إضافة تلميذ جديد' : 'تعديل بيانات: ${student!.name}'),
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
      appBar: AppBar(
                backgroundColor: AppColors.primaryBlue,
                 centerTitle: true,

        title: Text('تلاميذ فصل: ${classItem.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, student),
                      ),
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
// الشاشة 3: تسجيل الحضور
// ==============================================================================

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
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
          // تعيين الفصل الأول كفصل افتراضي
          if (_selectedClassId == null && _classes.isNotEmpty) {
            _selectedClassId = _classes.first.id;
          }
        });
      }
    });
  }

  // دالة لتغيير تاريخ الحضور
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // تصميم منتقي التاريخ
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor, // لون الثيم
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // دالة لتسجيل الحضور
  void _toggleAttendance(Student student, bool isClass, bool value) async {
    final dateString = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final recordId = '${student.id}_$dateString';

    AttendanceRecord? existingRecord = await _service.getAttendanceForDay(student.id, _selectedDate);

    AttendanceRecord record;
    if (existingRecord != null) {
      record = existingRecord;
    } else {
      record = AttendanceRecord(
        id: recordId,
        studentId: student.id,
        date: _selectedDate,
      );
    }

    if (isClass) {
      record.isClassPresent = value;
    } else {
      record.isLiturgyPresent = value;
    }

    try {
      await _service.recordAttendance(record);
      // لا تحتاج لـ setState هنا، لأن StreamBuilder سيتولى التحديث
    } catch (e) {
      log('Failed to record attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // تنسيق التاريخ ليكون سهل القراءة
    final formattedDate = "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";
    final selectedClass = _classes.firstWhere(
      (c) => c.id == _selectedClassId,
      orElse: () => SundaySchoolClass(id: '', name: 'حدد فصلاً', order: 0),
    );

    return Column(
      children: [
        // شريط التحكم في التاريخ والفصل
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05), 
            border: const Border(bottom: BorderSide(color: Color(0xFF00ACC1), width: 2)),
          ),
          child: Row(
            children: [
              // اختيار التاريخ
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, color: Theme.of(context).primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // اختيار الفصل
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'اختيار الفصل',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  items: _classes.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
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

        // قائمة التلاميذ وسجلات الحضور
        Expanded(
          child: _selectedClassId == null || _classes.isEmpty
              ? const Center(child: Text('الرجاء اختيار فصل لبدء تسجيل الحضور.'))
              : StreamBuilder<List<Student>>(
                  stream: _service.getStudentsByClass(_selectedClassId!),
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (studentSnapshot.hasError) {
                      return Center(child: Text('خطأ في جلب التلاميذ: ${studentSnapshot.error}'));
                    }
                    final students = studentSnapshot.data ?? [];
                    if (students.isEmpty) {
                      return Center(
                        child: Text('لا يوجد تلاميذ في فصل ${selectedClass.name}.', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      );
                    }

                    // يتم هنا بناء كل عنصر في القائمة
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final dateString = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
                        
                        return FutureBuilder<AttendanceRecord?>(
                          future: _service.getAttendanceForDay(student.id, _selectedDate),
                          builder: (context, attendanceSnapshot) {
                            final record = attendanceSnapshot.data ?? 
                                AttendanceRecord(id: '${student.id}_$dateString', studentId: student.id, date: _selectedDate);
                            
                            // 💡 حركة الدخول التدريجي للعنصر بمجرد تحميل بيانات الحضور الخاصة به
                            return AnimatedOpacity(
                              opacity: attendanceSnapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: AttendanceItem(
                                student: student,
                                record: record,
                                onToggle: (isClass, value) => _toggleAttendance(student, isClass, value),
                              ),
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

// عنصر قائمة الحضور مع الحركة
class AttendanceItem extends StatelessWidget {
  final Student student;
  final AttendanceRecord record;
  final Function(bool isClass, bool value) onToggle;

  const AttendanceItem({
    super.key,
    required this.student,
    required this.record,
    required this.onToggle,
  });

  // دالة مساعدة لبناء زر الحضور المتحرك
  Widget _buildToggleButton({
    required String label,
    required bool isClass,
    required bool isPresent,
    required Color activeColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: () => onToggle(isClass, !isPresent),
          // 💡 استخدام AnimatedContainer لإضافة حركة عند تغيير الحالة
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isPresent ? activeColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPresent ? activeColor.withOpacity(0.5) : Colors.grey[400]!,
                width: isPresent ? 2 : 1,
              ),
              boxShadow: isPresent ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ] : null,
            ),
            child: Text(
              isPresent ? 'حاضر' : label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPresent ? Colors.white : Colors.grey[700],
                fontWeight: isPresent ? FontWeight.w900 : FontWeight.normal,
                fontSize: 14,
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
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // اسم التلميذ
            Expanded(
              flex: 2,
              child: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(width: 10),

            // زر حضور الفصل (أزرق)
            _buildToggleButton(
              label: 'الفصل',
              isClass: true,
              isPresent: record.isClassPresent,
              activeColor: Colors.blue.shade600,
            ),

            // زر حضور القداس (بنفسجي)
            _buildToggleButton(
              label: 'القداس',
              isClass: false,
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
// الشاشة 4: أعياد الميلاد
// ==============================================================================

class BirthdaysScreen extends StatelessWidget {
  const BirthdaysScreen({super.key});

  // دالة مساعدة لحساب كم يوماً متبقياً على عيد الميلاد
  int _daysUntilBirthday(DateTime? dob) {
    if (dob == null) return -1;
    final now = DateTime.now();
    
    // إنشاء تاريخ ميلاد هذه السنة
    var nextBirthday = DateTime(now.year, dob.month, dob.day);

    // إذا كان تاريخ الميلاد قد مر في هذه السنة، اضف سنة
    if (nextBirthday.isBefore(now) && nextBirthday.day != now.day) {
      nextBirthday = DateTime(now.year + 1, dob.month, dob.day);
    }
    
    final difference = nextBirthday.difference(now);
    // إذا كان عيد الميلاد اليوم، تكون النتيجة 0
    if (nextBirthday.day == now.day && nextBirthday.month == now.month) return 0;

    return difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Student>>(
      stream: _service.getAllStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في جلب البيانات: ${snapshot.error}'));
        }

        final allStudents = snapshot.data ?? [];
        
        // تصفية وحساب وفرز أعياد الميلاد القادمة خلال 90 يوماً
        var upcomingBirthdays = allStudents
            .where((s) => s.dob != null)
            .map((s) {
              final days = _daysUntilBirthday(s.dob);
              return {'student': s, 'daysLeft': days};
            })
            .where((item) => item['daysLeft'] as int >= 0 && item['daysLeft'] as int <= 90)
            .toList();

        // فرز حسب الأيام المتبقية (الأقرب أولاً)
        upcomingBirthdays.sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));

        if (upcomingBirthdays.isEmpty) {
          return const Center(
            child: Text('لا توجد أعياد ميلاد قادمة في الـ 90 يوماً القادمة.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

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
              subtitle = 'متبقي ${daysLeft} أيام (قريباً جداً)';
              icon = Icons.celebration;
              color = Colors.orange.shade600;
            } else {
              subtitle = 'متبقي ${daysLeft} أيام';
              icon = Icons.cake;
              color = Colors.green.shade600;
            }

            // 💡 تصميم بطاقة عيد ميلاد مبهرة
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
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blueGrey.shade800),
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
    );
  }
}