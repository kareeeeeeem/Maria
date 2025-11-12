import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:intl/intl.dart'; 
import 'dart:async'; // لاستخدام Timer في مكون العداد إذا احتجنا إليه مستقبلاً

// =========================================================
// I. نموذج البيانات والثوابت
// =========================================================

// 1. تعريف AppColors
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFE53935); // للتحذيرات والحذف
}

// 2. نموذج بيانات الأخبار
class ChurchPost {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool isUrgent; 

  const ChurchPost({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isUrgent = false,
  });

  // مصنع لإنشاء كائن ChurchPost من DocumentSnapshot
  factory ChurchPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return ChurchPost(
      id: doc.id,
      title: data?['title'] ?? 'عنوان مفقود',
      body: data?['body'] ?? 'محتوى مفقود',
      // يجب التعامل مع Timestamp عند قراءة التاريخ من Firestore
      date: (data?['date'] as Timestamp? ?? Timestamp.now()).toDate(), 
      isUrgent: data?['isUrgent'] ?? false,
    );
  }

  // دالة لتحويل الكائن إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': Timestamp.fromDate(date),
      'isUrgent': isUrgent,
      // يمكن إضافة حقل 'category': 'News' إذا لزم الأمر للتمييز في قاعدة البيانات
    };
  }
}

// =========================================================
// II. الصفحة الرئيسية (NewsPage)
// =========================================================

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 🔴 الحالة الجديدة: تحديد ما إذا كان المستخدم مصادق عليه (مشرف مؤقت)
  bool _isAdmin = false; 
  bool _isLocaleInitialized = false; 

  // 🔴 استخدام المتغير العالمي __app_id 
  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  // تحديد مسار المجموعة (Collection Path)
  // المسار: artifacts/{appId}/public/data/news
  late final CollectionReference _newsCollection;

  @override
  void initState() {
    super.initState();
    
    // تهيئة مسار المجموعة
    _newsCollection = _firestore.collection('artifacts').doc(appId).collection('public').doc('data').collection('news');
    
    // 1. بدء تهيئة اللغة العربية
    _initializeLocale();

    // 2. الاستماع لحالة المصادقة
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        // أي مستخدم مصادق عليه هو "مشرف" (حسب طلب المستخدم)
        setState(() {
          _isAdmin = user != null;
        });
      }
    });
  }

  // دالة لتهيئة بيانات اللغة العربية (لتجنب LocaleDataException)
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

  // دالة حذف منشور
  Future<void> deletePost(BuildContext context, String postId) async {
    try {
      await _newsCollection.doc(postId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف الخبر بنجاح', textAlign: TextAlign.right)),
        );
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل الحذف: $e', textAlign: TextAlign.right)),
        );
      }
    }
  }

  // دالة فتح شاشة الإضافة/التعديل
  void _navigateToAddEditPost({ChurchPost? post}) {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون مشرفاً للقيام بهذه العملية.')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPostScreen(
          newsCollection: _newsCollection,
          post: post,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Center(child: Text('📰 أخبار الكنيسة'  , style: TextStyle(color: AppColors.secondaryGold))),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      
      // جسم الصفحة: جلب البيانات من Firestore
      body: StreamBuilder<QuerySnapshot>(
        // جلب البيانات وفرزها حسب التاريخ الأحدث أولاً
        stream: _newsCollection.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}', textAlign: TextAlign.center));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد أخبار حالياً.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          // تحويل البيانات إلى قائمة ChurchPost
          final List<ChurchPost> posts = snapshot.data!.docs
              .map((doc) => ChurchPost.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _PostCard(
                post: posts[index],
                isAdmin: _isAdmin,
                onDelete: () => deletePost(context, posts[index].id),
                onEdit: () => _navigateToAddEditPost(post: posts[index]),
              );
            },
          );
        },
      ),

      // زر الإضافة العائم يظهر فقط للمشرفين
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddEditPost(),
              icon: const Icon(Icons.add),
              label: const Text('إضافة خبر'),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.secondaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// =========================================================
// III. مكونات الواجهة (UI Components)
// =========================================================

// ---------------------------------------------------------
// بطاقة المنشور الواحدة (_PostCard) (تم تعديل الألوان هنا)
// ---------------------------------------------------------

class _PostCard extends StatelessWidget {
  final ChurchPost post;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _PostCard({
    required this.post,
    required this.isAdmin,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  // دالة تحويل الوقت إلى نص مناسب
  String _formatDate(DateTime date) {
    // تنسيق التاريخ ليكون سهل القراءة باستخدام اللغة العربية
    // مثال: 2025/11/10 | 02:41 PM
    return DateFormat('yyyy/MM/dd | hh:mm a', 'ar').format(date);
  }

  // عرض مربع حوار التأكيد
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الخبر "${post.title}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.primaryBlue)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed, // خلفية حمراء
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      // 💡 يمكنك تعديل لون خلفية البطاقة هنا إذا أردت
      color: AppColors.cardColor, // الافتراضي هو الأبيض
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // حدود حمراء للأخبار العاجلة
        side: post.isUrgent 
          ? const BorderSide(color: AppColors.alertRed, width: 2.5) 
          : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // عنوان وتصنيف عاجل + التاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // التاريخ
                Text(
                  _formatDate(post.date),
                  // 💡 لون التاريخ (AppColors.textSecondary هو لون رمادي فاتح)
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                
                if (post.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed, // خلفية عاجل حمراء
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🚨 عاجل',
                      // 💡 لون نص "عاجل" (AppColors.secondaryGold هو لون ذهبي فاتح)
                      style: TextStyle(
                        color: AppColors.secondaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ].reversed.toList(), // لعرض العناصر بالترتيب الصحيح (يمين -> يسار)
            ),

            const SizedBox(height: 8),

            // العنوان الرئيسي
            Text(
              post.title,
              // 💡 لون العنوان الرئيسي (AppColors.textPrimary هو لون داكن)
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
            // 💡 لون الخط الفاصل (AppColors.secondaryGold هو لون ذهبي فاتح)
            const Divider(color: AppColors.secondaryGold, thickness: 1, height: 15),

            // محتوى الخبر
            Text(
              post.body,
              // 💡 لون محتوى الخبر (AppColors.textSecondary هو لون رمادي فاتح)
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.right,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // أزرار المشرف (تعديل وحذف)
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      // 💡 لون أيقونة التعديل (AppColors.primaryBlue هو لون أزرق داكن/بني)
                      icon: const Icon(Icons.edit, size: 20, color: AppColors.primaryBlue),
                      // 💡 لون نص التعديل
                      label: const Text('تعديل', style: TextStyle(color: AppColors.primaryBlue)),
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      // 💡 لون أيقونة الحذف (AppColors.alertRed هو لون أحمر)
                      icon: const Icon(Icons.delete, color: AppColors.alertRed, size: 20),
                      // 💡 لون نص الحذف
                      label: const Text('حذف', style: TextStyle(color: AppColors.alertRed)),
                      onPressed: () => _showDeleteConfirmation(context),
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
// شاشة إضافة/تعديل المنشور (AddEditPostScreen)
// ---------------------------------------------------------

class AddEditPostScreen extends StatefulWidget {
  final CollectionReference newsCollection;
  final ChurchPost? post; // إذا كان موجوداً: تعديل. إذا كان null: إضافة.

  const AddEditPostScreen({
    super.key, 
    required this.newsCollection, 
    this.post,
  });

  @override
  State<AddEditPostScreen> createState() => _AddEditPostScreenState();
}

class _AddEditPostScreenState extends State<AddEditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // لملء الحقول عند التعديل
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _bodyController.text = widget.post!.body;
      _isUrgent = widget.post!.isUrgent;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // دالة الإرسال (إضافة/تعديل)
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 🔴 التحقق من المصادقة مرة أخرى (إجراء أمان إضافي)
    if (FirebaseAuth.instance.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: يجب أن تكون مصادقاً عليه للنشر.')),
          );
        }
        return;
      }
      
    setState(() { _isLoading = true; });

    try {
      final newPost = ChurchPost(
        id: widget.post?.id ?? '', 
        title: _titleController.text,
        body: _bodyController.text,
        date: DateTime.now(), // تحديث التاريخ عند الإرسال/التعديل
        isUrgent: _isUrgent,
      );

      if (widget.post == null) {
        // إضافة منشور جديد
        await widget.newsCollection.add(newPost.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إضافة الخبر بنجاح', textAlign: TextAlign.right)),
          );
        }
      } else {
        // تعديل منشور موجود
        await widget.newsCollection.doc(widget.post!.id).update(newPost.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم تعديل الخبر بنجاح', textAlign: TextAlign.right)),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Submission Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل الإرسال: $e', textAlign: TextAlign.right)),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // مكون مساعد لحقل الإدخال
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryBlue) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
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
    final isEditing = widget.post != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل الخبر' : 'إضافة خبر جديد'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.secondaryGold,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // حقل العنوان
              _buildTextFormField(
                controller: _titleController,
                label: 'عنوان الخبر الموجز',
                icon: Icons.title,
              ),
              const SizedBox(height: 20),

              // حقل المحتوى
              _buildTextFormField(
                controller: _bodyController,
                label: 'المحتوى التفصيلي',
                icon: Icons.description,
                maxLines: 8,
              ),
              const SizedBox(height: 20),

              // خيار عاجل
              SwitchListTile(
                title: const Text('تصنيف الخبر كـ "عاجل"', textAlign: TextAlign.right),
                subtitle: const Text('سيتم تمييزه بحدود حمراء', textAlign: TextAlign.right),
                value: _isUrgent,
                onChanged: (bool value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
                activeColor: AppColors.alertRed,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 30),

              // زر الإرسال
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.secondaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: AppColors.secondaryGold, strokeWidth: 3),
                      )
                    : Text(
                        isEditing ? 'حفظ التعديلات' : 'نشر الخبر',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}