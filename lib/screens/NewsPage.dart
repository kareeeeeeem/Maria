// lib/screens/news/news_page.dart (أو news_page.dart إذا لم تستخدم مجلدات)

import 'package:churchapp/sub/models/church_post.dart';
import 'package:churchapp/sub/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:intl/intl.dart'; 
import 'dart:async'; 
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // 🆕 لـ AddEditPostScreen


// =========================================================
// I. نموذج البيانات والثوابت (AppColors فقط)
// =========================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // بني داكن
  static const Color secondaryGold = Color(0xFFFFF8E1); // ذهبي فاتح
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFE53935); 
}

// ⚠️ تمت إزالة تعريف ChurchPost من هنا واستبداله بالاستيراد أعلاه


// =========================================================
// II. الصفحة الرئيسية (NewsPage)
// =========================================================
// ... (NewsPage و _NewsPageState تبقى كما هي)
// ... (setupAuthListener و deletePost تبقى كما هي)

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isAdmin = false; 
  bool _isLoading = true; 
  bool _isLocaleInitialized = false; 

  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  late final CollectionReference _newsCollection;

  @override
  void initState() {
    super.initState();
    
    _newsCollection = _firestore.collection('artifacts').doc(appId).collection('public').doc('data').collection('news');
    
    _initializeLocale();
    _setupAuthListener();
  }
  
  Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final bool isAdmin = data?['isAdmin'] ?? false;
      final bool isNewer = data?['IsNewer'] ?? false; 
      final bool canEdit = isAdmin || isNewer; 

      if (mounted) {
        setState(() {
          _isAdmin = canEdit; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin Status Check Error: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (!mounted) return;

      if (user != null) {
        _checkAdminStatus(user.uid);
        
        // ❌ تم حذف جميع محاولات ربط Supabase Auth هنا.
        // نعتمد الآن على سياسة Storage الجديدة (anon: true) 

      } else {
        setState(() {
          _isAdmin = false;
          _isLoading = false; 
        });
        
        if (_auth.currentUser == null) {
            _auth.signInAnonymously().catchError((e) {
                debugPrint('Anonymous Auth Failed: $e');
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

  Future<void> deletePost(BuildContext context, String postId) async {
    if (!_isAdmin) { 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب أن تكون مشرفاً للقيام بهذه العملية.')),
        );
        return;
    }
    
    try {
      // ⚠️ ملاحظة: يجب إضافة منطق حذف الملفات من Supabase Storage هنا لاحقاً!
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
    if (!_isLocaleInitialized || _isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('📰 أخبار الكنيسة'  , style: TextStyle(color: AppColors.secondaryGold)),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _newsCollection.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}', textAlign: TextAlign.center));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); 
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
// بطاقة المنشور الواحدة (_PostCard) 
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd | hh:mm a', 'ar').format(date);
  }

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
              backgroundColor: AppColors.alertRed, 
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
      color: AppColors.cardColor,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
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
                Text(
                  _formatDate(post.date),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                
                if (post.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed, 
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🚨 عاجل',
                      style: TextStyle(
                        color: AppColors.secondaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ].reversed.toList(),
            ),

            const SizedBox(height: 8),

            // العنوان الرئيسي
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
            const Divider(color: AppColors.secondaryGold, thickness: 1, height: 15),

            // محتوى الخبر
            Text(
              post.body,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.right,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            
            // 🆕 عرض الوسائط المرفقة
            if (post.mediaUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: SizedBox(
                  height: 150, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.mediaUrls.length,
                    reverse: true, // لعرض العناصر من اليمين إلى اليسار
                    itemBuilder: (context, index) {
                      final url = post.mediaUrls[index];
                      // افتراض بسيط لتحديد نوع الوسائط
                      final isImage = url.toLowerCase().contains('.jpg') || 
                                      url.toLowerCase().contains('.png') || 
                                      url.toLowerCase().contains('.jpeg');
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: isImage
                              ? Image.network(
                                  url,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                                  },
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.error_outline, size: 50, color: AppColors.alertRed),
                                )
                              : Container(
                                  width: 150,
                                  color: Colors.black54,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.video_camera_back, color: Colors.white, size: 40),
                                      Text('فيديو', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // أزرار المشرف (تعديل وحذف)
            if (isAdmin) 
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 20, color: AppColors.primaryBlue),
                      label: const Text('تعديل', style: TextStyle(color: AppColors.primaryBlue)),
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: AppColors.alertRed, size: 20),
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
  final ChurchPost? post; 

  const AddEditPostScreen({
    super.key, 
    required this.newsCollection, 
    this.post,
  });

  @override
  State<AddEditPostScreen> createState() => _AddEditPostScreenState();
}

class _AddEditPostScreenState extends State<AddEditPostScreen> {
  // 🆕 متغيرات ومكونات الوسائط
  final SupabaseService _supabaseService = SupabaseService(); 
  final ImagePicker _picker = ImagePicker(); 
  List<XFile> _selectedFiles = []; // الملفات المختارة حديثاً
  List<String> _currentMediaUrls = []; // الروابط القديمة (للتعديل)
  int _uploadingCount = 0; 
  double _uploadProgress = 0.0; 

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // لملء الحقول والروابط عند التعديل
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _bodyController.text = widget.post!.body;
      _isUrgent = widget.post!.isUrgent;
      _currentMediaUrls = List.from(widget.post!.mediaUrls); // نسخ الروابط الموجودة
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
  
  // 🆕 دالة اختيار الصور والفيديوهات
  Future<void> _pickMedia() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    // 🔴 ملاحظة: يمكنك استخدام دالة _picker.pickVideo() لإضافة خيار الفيديو إذا أردت
    // يمكنك أيضاً استخدام مكتبات متقدمة مثل file_picker لدمج الاختيار.

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedFiles = [..._selectedFiles, ...pickedFiles];
      });
    }
  }
  
  // 🆕 دالة إزالة الملف المحلي (الذي لم يتم رفعه بعد)
  void _removeFile(XFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }
  
  // 🆕 دالة إزالة الرابط القديم (من Firestore)
  void _removeUrl(String url) {
    setState(() {
      _currentMediaUrls.remove(url);
    });
    // ⚠️ ملاحظة: لتبسيط الكود، لم يتم إضافة منطق حذف الملف من Supabase هنا.
    // يجب إضافة _supabaseService.deleteFile(url) هنا للحذف الفعلي.
  }
  
  // 🆕 دالة رفع الملفات إلى Supabase Storage
  Future<List<String>> _handleFileUploads() async {
    if (_selectedFiles.isEmpty) {
        // لا يوجد ملفات جديدة للرفع، نرجع فقط الروابط القديمة المتبقية بعد الحذف
        return _currentMediaUrls;
    }

    setState(() {
      _uploadingCount = _selectedFiles.length;
      _uploadProgress = 0.0;
    });
    
    try {
        // استخدام دالة الخدمة الموحدة لرفع الملفات
        final newUrls = await _supabaseService.uploadFiles(
            _selectedFiles, 
            (progress) { // تحديث التقدم عبر الـ Callback
                if (mounted) {
                    setState(() {
                        _uploadProgress = progress;
                    });
                }
            }
        );
        
        // دمج الروابط الجديدة مع الروابط القديمة التي لم يتم حذفها
        return [..._currentMediaUrls, ...newUrls]; 

    } catch (e) {
        rethrow;
    } finally {
        if (mounted) {
            setState(() {
                _uploadingCount = 0;
                _uploadProgress = 0.0;
            });
        }
    }
  }


  // دالة الإرسال (إضافة/تعديل) - تم تحديثها لدمج رفع الملفات
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: يجب أن تكون مشرفاً ومصادقاً عليه للنشر.')),
          );
        }
        return;
    }
      
    setState(() { _isLoading = true; });

    try {
      // 1. رفع الملفات والحصول على قائمة عناوين URL المدمجة
      final List<String> finalMediaUrls = await _handleFileUploads(); 
      
      final newPost = ChurchPost(
        id: widget.post?.id ?? '', 
        title: _titleController.text,
        body: _bodyController.text,
        date: DateTime.now(), 
        isUrgent: _isUrgent,
        mediaUrls: finalMediaUrls, // 🆕 تمرير قائمة الـ URLs النهائية
      );

      if (widget.post == null) {
        await widget.newsCollection.add(newPost.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إضافة الخبر بنجاح', textAlign: TextAlign.right)),
          );
        }
      } else {
        // تعديل منشور موجود (نحن نحدث المنشور نفسه ولكن نستخدم الروابط الجديدة)
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
   } catch (e, stacktrace) { // 🆕 هنا تم إضافة 'stacktrace'
      // 🆕 اطبع الخطأ كاملاً بالإضافة إلى الـ Stack Trace لمزيد من التفاصيل
      debugPrint('🚨🚨🚨 Submission Error DETAILS: $e'); 
      debugPrint('🚨🚨🚨 Stack Trace: $stacktrace'); // 🆕 طباعة تتبع الخطأ كاملاً
      
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
  
  // ---------------------------------------------------------
  // مكون عرض الملفات المحلية المختارة (_MediaPreviewList)
  // ---------------------------------------------------------
  Widget _MediaPreviewList() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _selectedFiles.map((file) {
        return Chip(
          backgroundColor: AppColors.secondaryGold,
          // 🆕 عرض اسم الملف فقط
          label: Text(file.name.length > 20 ? '${file.name.substring(0, 17)}...' : file.name), 
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeFile(file),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------
  // مكون عرض الروابط الموجودة مسبقاً (_ExistingMediaUrls)
  // ---------------------------------------------------------
  Widget _ExistingMediaUrls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الوسائط المرفوعة سابقاً (اضغط للحذف):',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 5),
        ..._currentMediaUrls.map((url) {
          final isImage = url.toLowerCase().contains('.jpg') || url.toLowerCase().contains('.png');
          final icon = isImage ? Icons.image : Icons.videocam;
          // 🆕 استخراج اسم الملف من الـ URL للعرض
          final fileName = Uri.parse(url).pathSegments.last; 

          return ListTile(
            title: Text(
              fileName,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: Icon(icon, color: AppColors.primaryBlue),
            leading: IconButton(
              icon: const Icon(Icons.delete_forever, color: AppColors.alertRed),
              onPressed: () => _removeUrl(url),
            ),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
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
              
              const SizedBox(height: 20),

              // 🆕 زر اختيار الصور والفيديوهات
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.photo_library),
                label: const Text('اختيار صور/فيديوهات'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              
              const SizedBox(height: 15),

              // 🆕 عرض الملفات المختارة حالياً (المحلية)
              if (_selectedFiles.isNotEmpty)
                _MediaPreviewList(),
              
              // 🆕 عرض الروابط الموجودة مسبقاً (للتعديل)
              if (_currentMediaUrls.isNotEmpty && _selectedFiles.isEmpty)
                _ExistingMediaUrls(),

              // 🆕 عرض شريط التقدم عند الرفع
              if (_uploadingCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: AppColors.secondaryGold,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'جاري رفع الملفات (${(_uploadProgress * 100).toStringAsFixed(0)}%)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
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