import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/services.dart'; 

// =========================================================
// I. نموذج البيانات والثوابت
// =========================================================

// تعريف الثوابت اللونية (نظام ألوان إداري واضح)
class AppColors {
  static const Color primaryBlue = Color(0xFF004D40); // أخضر داكن/أزرق لوني إداري
  static const Color secondaryGold = Color(0xFFFFCC80); // لون ذهبي/عسلي
  static const Color backgroundColor = Color(0xFFF0F4F8); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF388E3C); 
}

// نموذج بيانات العنصر العام
class GeneralItem {
  final String id;
  final String itemName;     // اسم العنصر (كتاب، صورة، بضاعة)
  final String category;     // فئة العنصر (كتب، صور، هدايا، إلخ)
  final String location;     // الموقع المخزن في DB: 'Shelf 1' أو 'Storage Room'
  final double unitPrice;    // سعر الوحدة
  final int stockQuantity;   // الكمية المتوفرة في المخزون
  final String? imageUrl;    // صورة العنصر (اختياري)
  final Timestamp? dateAdded; // تاريخ الإضافة للفرز المحلي

  const GeneralItem({
    required this.id,
    required this.itemName,
    required this.category,
    required this.location,
    required this.unitPrice,
    required this.stockQuantity,
    this.imageUrl,
    this.dateAdded, 
  });

  // مصنع لإنشاء كائن GeneralItem من DocumentSnapshot
  factory GeneralItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return GeneralItem(
      id: doc.id,
      itemName: data?['itemName'] ?? 'عنصر غير مسمى',
      category: data?['category'] ?? 'عام',
      location: data?['location'] ?? 'Shelf 1', // يحافظ على قيمة DB
      unitPrice: (data?['unitPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: data?['stockQuantity'] ?? 0,
      imageUrl: data?['imageUrl'],
      dateAdded: data?['dateAdded'] as Timestamp?,
    );
  }

  // دالة لتحويل الكائن إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category,
      'unitPrice': unitPrice,
      'stockQuantity': stockQuantity,
      'location': location,
      'imageUrl': imageUrl,
    };
  }
  
  // دالة مساعدة لتحديد ما إذا كان العنصر متوفراً
  bool get isInStock => stockQuantity > 0;
}

// =========================================================
// II. الصفحة الرئيسية (InventoryPage)
// =========================================================

class InventoryPage extends StatefulWidget {
  static const String routeName = "/InventoryPage"; 

  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isAdmin = false; 
  
  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  // مسار المجموعة: artifacts/{appId}/public/data/general_inventory
  late final CollectionReference _itemsCollection;

  // قائمة أسماء المواقع المعروضة
  final List<String> _locations = const [
   'الرف 1 (متجر الكنيسة)', // يُقابل Shelf 1 في DB
   'غرفة التخزين', // يُقابل Storage Room في DB
  ];
  
  // حالة لتبديل عرض العناصر بين المواقع
  late String _currentLocationFilter;

  // دالة مساعدة لربط اسم الموقع المعروض (Display Name) بالقيمة المخزنة في قاعدة البيانات (DB Value)
  String _getLocationDbValue(String displayName) {
    if (displayName == 'الرف 1 (متجر الكنيسة)') return 'Shelf 1';
    if (displayName == 'غرفة التخزين') return 'Storage Room';
    return 'Shelf 1';
  }

  @override
  void initState() {
    super.initState();
    
    _currentLocationFilter = _locations[0];

    // تهيئة مسار المجموعة للمخزون العام
    _itemsCollection = _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('general_inventory');
    
    // الاستماع لحالة المصادقة
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        // أي مستخدم مصادق عليه هو "مشرف" (لإدارة المخزون)
        setState(() {
          _isAdmin = user != null;
        });
        print('User signed in: ${_isAdmin ? user!.uid : 'No'}');
      }
    });
    // إعدادات Firestore
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }

  // دالة حذف عنصر
  Future<void> deleteItem(BuildContext context, String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف العنصر بنجاح', textAlign: TextAlign.right)),
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
  void _navigateToAddEditItem({GeneralItem? item}) {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون مشرفاً للقيام بهذه العملية.')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditItemScreen(
          itemsCollection: _itemsCollection,
          item: item,
          locations: _locations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على القيمة المخزنة في DB للموقع المحدد
    final String locationQueryValue = _getLocationDbValue(_currentLocationFilter);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Center(child: Text('📦 إدارة المخزون العام', style: TextStyle(color: AppColors.secondaryGold))),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      
      // جسم الصفحة: جلب البيانات من Firestore
      body: Column(
        children: [
          // شريط التبديل بين المواقع
          _buildLocationToggleBar(),

          // قائمة العناصر
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _itemsCollection
                  .where('location', isEqualTo: locationQueryValue) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}', textAlign: TextAlign.center));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد عناصر مخزون حالياً في $_currentLocationFilter.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // تحويل البيانات إلى قائمة GeneralItem
                List<GeneralItem> items = snapshot.data!.docs
                    .map((doc) => GeneralItem.fromFirestore(doc))
                    .toList();
                
                // الترتيب المحلي في الذاكرة (الأحدث أولاً)
                items.sort((a, b) {
                  final dateA = a.dateAdded?.toDate().millisecondsSinceEpoch ?? 0;
                  final dateB = b.dateAdded?.toDate().millisecondsSinceEpoch ?? 0;
                  return dateB.compareTo(dateA); // تنازلياً
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _ItemCard(
                      item: items[index],
                      isAdmin: _isAdmin,
                      onDelete: () => deleteItem(context, items[index].id),
                      onEdit: () => _navigateToAddEditItem(item: items[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // زر الإضافة العائم يظهر فقط للمشرفين
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddEditItem(),
              icon: const Icon(Icons.add),
              label: const Text('إضافة عنصر جديد'),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.secondaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  // مكون شريط التبديل بين المواقع
  Widget _buildLocationToggleBar() {
    return Container(
      color: AppColors.cardColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Center(
        child: ToggleButtons(
          isSelected: _locations.map((location) => location == _currentLocationFilter).toList(),
          onPressed: (index) {
            setState(() {
              _currentLocationFilter = _locations[index];
            });
          },
          borderRadius: BorderRadius.circular(12),
          selectedColor: AppColors.secondaryGold, 
          color: AppColors.primaryBlue, 
          fillColor: AppColors.primaryBlue.withOpacity(0.9), 
          borderColor: AppColors.primaryBlue.withOpacity(0.6),
          selectedBorderColor: AppColors.primaryBlue,
          children: _locations.map((location) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              location,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// =========================================================
// III. مكونات الواجهة (UI Components)
// =========================================================

// ---------------------------------------------------------
// بطاقة العنصر الواحد (_ItemCard)
// ---------------------------------------------------------

class _ItemCard extends StatelessWidget {
  final GeneralItem item;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ItemCard({
    required this.item,
    required this.isAdmin,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  // دالة مساعدة لربط القيمة المخزنة في قاعدة البيانات (DB Value) باسم الموقع المعروض
  String _getLocationDisplayName(String dbValue) {
    if (dbValue == 'Shelf 1') return 'الرف 1 (متجر الكنيسة)';
    if (dbValue == 'Storage Room') return 'غرفة التخزين';
    return dbValue;
  }

  // عرض مربع حوار التأكيد
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العنصر "${item.itemName}"؟'),
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
    // تحديد لون خلفية البطاقة بناءً على التوفر
    final Color availabilityColor = item.isInStock 
        ? AppColors.successGreen.withOpacity(0.1) 
        : AppColors.alertRed.withOpacity(0.1);
        
    final String availabilityText = item.isInStock 
        ? '✅ متوفر بالمخزون' 
        : '❌ نفد المخزون';
        
    final String locationDisplayName = _getLocationDisplayName(item.location);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: item.isInStock ? AppColors.successGreen : AppColors.alertRed, width: 2),
      ),
      color: AppColors.cardColor,
      child: Container(
        decoration: BoxDecoration(
          color: availabilityColor, 
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // الأيقونة والعنوان والسعر
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة العنصر الافتراضية 
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 15),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // اسم العنصر
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 5),

                      // السعر
                      Text(
                        '${NumberFormat.currency(locale: 'ar', symbol: 'ج.م').format(item.unitPrice)}', 
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.alertRed, // تمييز السعر باللون الأحمر
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ].reversed.toList(),
            ),

            const SizedBox(height: 10),
            
            // الفئة
            Text(
              'الفئة: ${item.category}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Divider(color: AppColors.secondaryGold, thickness: 1, height: 20),

            // التوفر والكمية والموقع
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // حالة التوفر
                Text(
                  availabilityText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: item.isInStock ? AppColors.successGreen : AppColors.alertRed,
                  ),
                ),
                
                // الكمية المتاحة
                Text(
                  'المخزون: ${item.stockQuantity} وحدة',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ].reversed.toList(),
            ),
             Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'الموقع: $locationDisplayName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
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
// شاشة إضافة/تعديل العنصر (AddEditItemScreen)
// ---------------------------------------------------------

class AddEditItemScreen extends StatefulWidget {
  final CollectionReference itemsCollection;
  final GeneralItem? item; 
  final List<String> locations; // قائمة بأسماء المواقع المعروضة
  
  // قائمة ثابتة بالفئات التي يمكن اختيارها
  static const List<String> itemCategories = [
    'كتب ومطبوعات', 
    'صور وأيقونات', 
    'هدايا وتذكارات', 
    'مواد روحية/كنيسية',
    'عام',
  ];

  const AddEditItemScreen({
    super.key, 
    required this.itemsCollection, 
    this.item,
    required this.locations,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  
  late String _selectedLocation; 
  late String _selectedCategory; // الفئة المحددة
  bool _isLoading = false;

  // دالة مساعدة لربط اسم الموقع المعروض (Display Name) بالقيمة المخزنة في قاعدة البيانات (DB Value)
  String _getLocationDbValue(String displayName) {
    if (displayName == 'الرف 1 (متجر الكنيسة)') return 'Shelf 1';
    if (displayName == 'غرفة التخزين') return 'Storage Room';
    return 'Shelf 1';
  }
  
  // دالة مساعدة لربط القيمة المخزنة في قاعدة البيانات (DB Value) باسم الموقع المعروض
  String _getLocationDisplayName(String dbValue) {
    if (dbValue == 'Shelf 1') return 'الرف 1 (متجر الكنيسة)';
    if (dbValue == 'Storage Room') return 'غرفة التخزين';
    return widget.locations[0];
  }


  @override
  void initState() {
    super.initState();
    
    // تعيين القيمة الافتراضية
    _selectedLocation = widget.locations[0];
    _selectedCategory = AddEditItemScreen.itemCategories[0];

    // لملء الحقول عند التعديل
    if (widget.item != null) {
      _itemNameController.text = widget.item!.itemName;
      _unitPriceController.text = widget.item!.unitPrice.toString();
      _stockQuantityController.text = widget.item!.stockQuantity.toString();
      
      // تعيين الموقع الصحيح
      final String storedDbValue = widget.item!.location;
      final String locationDisplayName = _getLocationDisplayName(storedDbValue);
      _selectedLocation = widget.locations.firstWhere(
        (loc) => loc == locationDisplayName,
        orElse: () => widget.locations[0], 
      );
      
      // تعيين الفئة الصحيحة
      _selectedCategory = AddEditItemScreen.itemCategories.firstWhere(
        (cat) => cat == widget.item!.category,
        orElse: () => AddEditItemScreen.itemCategories[0], 
      );
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _unitPriceController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  // دالة الإرسال (إضافة/تعديل)
  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      final String locationValue = _getLocationDbValue(_selectedLocation);
      
      final Map<String, dynamic> itemData = {
        'itemName': _itemNameController.text,
        'category': _selectedCategory,
        'unitPrice': double.parse(_unitPriceController.text),
        'stockQuantity': int.parse(_stockQuantityController.text),
        'location': locationValue, 
      };


      if (widget.item == null) {
        // إضافة عنصر جديد
        itemData['dateAdded'] = FieldValue.serverTimestamp();
        await widget.itemsCollection.add(itemData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إضافة العنصر بنجاح', textAlign: TextAlign.right)),
          );
        }
      } else {
        // تعديل عنصر موجود
        await widget.itemsCollection.doc(widget.item!.id).update(itemData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم تعديل العنصر بنجاح', textAlign: TextAlign.right)),
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
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
        if (keyboardType == TextInputType.number || keyboardType == TextInputType.phone) {
          if (double.tryParse(value) == null && keyboardType != TextInputType.number) {
             return 'يجب أن تكون القيمة رقماً صحيحاً أو عشرياً.';
          }
          if (int.tryParse(value) == null && keyboardType == TextInputType.number) {
             return 'يجب أن تكون القيمة عدداً صحيحاً.';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل بيانات العنصر' : 'إضافة عنصر مخزون جديد'),
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
              // حقل اسم العنصر
              _buildTextFormField(
                controller: _itemNameController,
                label: 'اسم العنصر (مثال: كتاب الصلاة)',
                icon: Icons.inventory,
              ),
              const SizedBox(height: 20),
              
              // اختيار الفئة
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'اختر فئة العنصر',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.category, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                value: _selectedCategory,
                items: AddEditItemScreen.itemCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, textAlign: TextAlign.right),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // حقل السعر والكمية في صف واحد
              Row(
                children: [
                  // حقل السعر
                  Expanded(
                    child: _buildTextFormField(
                      controller: _unitPriceController,
                      label: 'سعر الوحدة (ج.م)',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                  ),
                  const SizedBox(width: 15),
                  // حقل الكمية
                  Expanded(
                    child: _buildTextFormField(
                      controller: _stockQuantityController,
                      label: 'الكمية في المخزون',
                      icon: Icons.production_quantity_limits,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // اختيار الموقع
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'اختر موقع التخزين',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                value: _selectedLocation,
                items: widget.locations.map((String location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location, textAlign: TextAlign.right),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLocation = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 30),

              // زر الإرسال
              ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
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
                        isEditing ? 'حفظ التعديلات' : 'إضافة العنصر',
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