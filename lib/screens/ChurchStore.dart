// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// =========================================================
// I. نموذج البيانات والثوابت (AppColors & StoreProduct)
// =========================================================

class AppColors {
  static const Color primaryStone = Color(0xFF4E342E);
  static const Color SecodaryStone = Color.fromARGB(255, 105, 64, 54);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color backgroundBeige = Color(0xFFFFF8F0);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFB71C1C);
  static const Color successGreen = Color(0xFF2E7D32);
}

// قائمة التصنيفات الثابتة
const List<String> kProductCategories = [
   'جبن والبان',
   'فراخ-لحوم-اسماك',
   'صيامي',

   'منظفات',
   'أخرى',
];

const Map<String, Map<String, String>> _storeMapping = {
   'كانتين كنيسه القديس': { 
     'dbValue': 'Stall 1',
     'phone': '+201012345678',
   },
   'كانتين كنيسه العذراء': {
     'dbValue': 'Stall 2',
     'phone': '+201198765432', 
   },
};

// نموذج بيانات المنتج
class StoreProduct {
  final String id;
  final String name;
  final String description;
  final String storeName; 
  final double price;
  final int quantity; 
  final String? imageUrl;
  final Timestamp? dateAdded; 
  final String category; // 🆕 حقل التصنيف

  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.storeName,
    required this.price,
    required this.quantity,
    required this.category,
    this.imageUrl,
    this.dateAdded, 
  });

  factory StoreProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return StoreProduct(
      id: doc.id,
      name: data?['name'] ?? 'منتج غير مسمى',
      description: data?['description'] ?? 'لا يوجد وصف.',
      storeName: data?['storeName'] ?? 'Stall 1', 
      price: (data?['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data?['quantity'] ?? 0,
      imageUrl: data?['imageUrl'], 
      dateAdded: data?['dateAdded'] as Timestamp?,
      category: data?['category'] ?? kProductCategories[0], // 🆕 جلب التصنيف
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'storeName': storeName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl, 
      'category': category, // 🆕 إرسال التصنيف
    };
  }
  
  bool get isAvailable => quantity > 0;
}

// =========================================================
// II. الصفحة الرئيسية (StorePage) - منطق الفلترة المحدث
// =========================================================

class StorePage extends StatefulWidget {
  static const String routeName = "/StorePage"; 
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _canManageStore = false; 
  bool _isLoading = true; 
  
  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
  late final CollectionReference _productsCollection;

  final List<String> _stores = _storeMapping.keys.toList();
    
  late String _currentStoreFilter;
  // 🆕 متغير حالة جديد للفلترة حسب التصنيف
  late String _currentCategoryFilter; 

  // دالة مساعدة لربط اسم المتجر المعروض (Display Name) بالقيمة المخزنة في قاعدة البيانات (DB Value)
  String _getStoreDbValue(String displayName) {
    return _storeMapping[displayName]?['dbValue'] ?? 'Stall 1';
  }

  // دالة مساعدة لربط القيمة المخزنة في قاعدة البيانات (DB Value) باسم المتجر المعروض
  String _getStoreDisplayName(String dbValue) {
    final entry = _storeMapping.entries.firstWhere(
      (e) => e.value['dbValue'] == dbValue,
      orElse: () => MapEntry(_stores[0], const {'dbValue': 'Stall 1', 'phone': ''}),
    );
    return entry.key;
  }
  
  // دالة مساعدة جديدة لجلب رقم الهاتف
  String _getStorePhoneNumber(String displayName) {
    return _storeMapping[displayName]?['phone'] ?? '';
  }
  
  // 🆕 قائمة التصنيفات الخاصة بالفلتر (بإضافة خيار "الكل")
  List<String> get _filterCategories {
    return ['الكل', ...kProductCategories];
  }


  @override
  void initState() {
    super.initState();
    
    _currentStoreFilter = _stores[0];
    _currentCategoryFilter = 'الكل'; // الفلتر الافتراضي: عرض كل التصنيفات

    _productsCollection = _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('store_products');
    
    _initializeAuthAndAdminCheck();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }

  // دالة فحص حقل isAdmin و isStoreManager في Firestore
  Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final bool isAdmin = data?['isAdmin'] ?? false;
      final bool isStoreManager = data?['isStoreManager'] ?? false; 
      
      final bool canEdit = isAdmin || isStoreManager; 

      if (mounted) {
        setState(() {
          _canManageStore = canEdit; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      print('Failed to check permissions for $uid: $e');
      if (mounted) {
        setState(() { 
          _canManageStore = false;
          _isLoading = false; 
        });
      }
    }
  }

  void _initializeAuthAndAdminCheck() {
    _auth.authStateChanges().listen((User? user) async {
      if (mounted) {
        if (user != null) {
          await _checkAdminStatus(user.uid);
        } else {
          setState(() {
            _canManageStore = false;
            _isLoading = false;
          });
          try {
             await _auth.signInAnonymously(); 
          } catch (e) {
             print('Anonymous Auth Failed: $e');
          }
        }
      }
    });
  }

  Future<void> deleteProduct(BuildContext context, String productId) async {
    if (!_canManageStore) return; 
    try {
      await _productsCollection.doc(productId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف المنتج بنجاح', textAlign: TextAlign.right)),
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

  void _navigateToAddEditProduct({StoreProduct? product}) {
    if (!_canManageStore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون مشرفاً مسئولاً عن المتجر للقيام بهذه العملية.')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          productsCollection: _productsCollection,
          product: product,
          stores: _stores,
          getStoreDbValue: _getStoreDbValue, 
          getStoreDisplayName: _getStoreDisplayName, 
        ),
      ),
    );
  }
  
  // 🆕 دالة جلب StreamQuery المحدثة للتعامل مع فلترة التصنيف
  Stream<QuerySnapshot> get _productStream {
    final String storeQueryValue = _getStoreDbValue(_currentStoreFilter);
    Query query = _productsCollection
        .where('storeName', isEqualTo: storeQueryValue)
        .orderBy('dateAdded', descending: true); // الترتيب حسب التاريخ

    // طبق فلترة التصنيف فقط إذا لم يكن الخيار هو 'الكل'
    if (_currentCategoryFilter != 'الكل') {
      query = query.where('category', isEqualTo: _currentCategoryFilter);
    }
    
    return query.snapshots();
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBeige,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryStone),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title:  const Text(
          '🛒 كانتين الكنيسة', 
          style: TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          )
        ),
        backgroundColor: AppColors.primaryStone,
        elevation: 8,
        shadowColor: AppColors.primaryStone.withOpacity(0.5),
        centerTitle: true,
      ),
      
      body: Column(
        children: [
          _buildStoreToggleBar(),
          // 🆕 شريط فلترة التصنيفات
          _buildCategoryFilterBar(), 

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productStream, // استخدام الدالة المحدثة
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.alertRed)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryStone));
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _currentCategoryFilter == 'الكل' 
                          ? 'لا توجد منتجات حالياً في $_currentStoreFilter.'
                          : 'لا توجد منتجات من تصنيف "($_currentCategoryFilter)" في $_currentStoreFilter.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 18, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                List<StoreProduct> products = snapshot.data!.docs
                    .map((doc) => StoreProduct.fromFirestore(doc))
                    .toList();
                
                // الترتيب حسب التاريخ (تم نقل الترتيب إلى _productStream لتحسين الأداء)
                // products.sort((a, b) {
                //   final dateA = a.dateAdded?.toDate().millisecondsSinceEpoch ?? 0;
                //   final dateB = b.dateAdded?.toDate().millisecondsSinceEpoch ?? 0;
                //   return dateB.compareTo(dateA);
                // });

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(
                      product: products[index],
                      canManageStore: _canManageStore, 
                      onDelete: () => deleteProduct(context, products[index].id),
                      onEdit: () => _navigateToAddEditProduct(product: products[index]),
                      getStoreDisplayName: _getStoreDisplayName, 
                      getStorePhoneNumber: _getStorePhoneNumber, 
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: _canManageStore
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddEditProduct(),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('إضافة منتج جديد'),
              backgroundColor: AppColors.primaryStone,
              foregroundColor: AppColors.accentGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildStoreToggleBar() {
    return Container(
      color: AppColors.backgroundBeige, 
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Center(
        child: ToggleButtons(
          isSelected: _stores.map((store) => store == _currentStoreFilter).toList(),
          onPressed: (index) {
            setState(() {
              _currentStoreFilter = _stores[index];
            });
          },
          borderRadius: BorderRadius.circular(25), 
          selectedColor: AppColors.accentGold,
          color: AppColors.textPrimary,
          fillColor: AppColors.primaryStone,
          borderColor: AppColors.primaryStone.withOpacity(0.5),
          selectedBorderColor: AppColors.primaryStone,
          borderWidth: 1.5,
          children: _stores.map((store) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              store,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          )).toList(),
        ),
      ),
    );
  }
  
  // 🆕 دالة بناء شريط فلترة التصنيفات
  Widget _buildCategoryFilterBar() {
    return Container(
      color: AppColors.backgroundBeige,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // للبدء من اليمين
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: _filterCategories.map((category) {
            final isSelected = category == _currentCategoryFilter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                selectedColor: AppColors.primaryStone,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accentGold : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.backgroundBeige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryStone : AppColors.textSecondary.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentCategoryFilter = category;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =========================================================
// III. مكونات الواجهة (UI Components) 
// =========================================================

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final bool canManageStore;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String Function(String) getStoreDisplayName; 
  final String Function(String) getStorePhoneNumber; 

  const _ProductCard({
    required this.product,
    required this.canManageStore,
    required this.onDelete,
    required this.onEdit,
    required this.getStoreDisplayName,
    required this.getStorePhoneNumber, 
    super.key,
  });
  
  void _callStore(BuildContext context, String phoneNumber) {
    if (phoneNumber.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جارٍ الاتصال بـ $phoneNumber... (يتطلب حزمة url_launcher في Flutter)'),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ لا يوجد رقم هاتف متاح لهذا المتجر.')),
      );
    }
  }


  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟', textAlign: TextAlign.right),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color availabilityFillColor = product.isAvailable 
        ? AppColors.successGreen.withOpacity(0.08) 
        : AppColors.alertRed.withOpacity(0.08);
        
    final String availabilityText = product.isAvailable 
        ? '✅ متوفر' 
        : '❌ نفد المخزون';
        
    final String storeDisplayName = getStoreDisplayName(product.storeName);
    final String storePhoneNumber = getStorePhoneNumber(storeDisplayName); 

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 10,
      shadowColor: AppColors.primaryStone.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.accentGold.withOpacity(0.7), width: 1.5), 
      ),
      color: AppColors.cardColor,
      child: Container(
        decoration: BoxDecoration(
          color: availabilityFillColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // منطقة عرض الصورة أو الأيقونة
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStone.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.accentGold, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            product.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.broken_image, size: 45, color: AppColors.alertRed), 
                          ),
                        )
                      : const Icon(Icons.shopping_bag_outlined, size: 45, color: AppColors.primaryStone),
                ),
                const SizedBox(width: 15),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // اسم المنتج
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),

                      // السعر
                      Text(
                        '${NumberFormat.currency(locale: 'ar', symbol: 'ج.م').format(product.price)}', 
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: <Color>[
                                Color.fromARGB(255, 138, 115, 0),
                                Color.fromARGB(255, 138, 115, 0),
                                Color.fromARGB(255, 136, 114, 2),
                              ],
                            ).createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0), 
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ].reversed.toList(),
            ),

            const SizedBox(height: 15),
            
            // 🆕 عرض التصنيف
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: AppColors.accentGold.withOpacity(0.2),
            //       borderRadius: BorderRadius.circular(8)
            //     ),
            //     child: Text(
            //       'التصنيف: ${product.category}',
            //       style: const TextStyle(
            //         fontSize: 13,
            //         color: AppColors.primaryStone,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 10),

            Text(
              product.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Divider(color: AppColors.primaryStone, thickness: 0.5, height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  availabilityText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: product.isAvailable ? AppColors.successGreen : AppColors.alertRed,
                  ),
                ),
              ].reversed.toList(),
            ),
            
            if (canManageStore)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 20, color: AppColors.primaryStone),
                      label: const Text('تعديل', style: TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold)),
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: AppColors.alertRed, size: 20),
                      label: const Text('حذف', style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.bold)),
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
// شاشة إضافة/تعديل المنتج (AddEditProductScreen)
// ---------------------------------------------------------

class AddEditProductScreen extends StatefulWidget {
  final CollectionReference productsCollection;
  final StoreProduct? product; 
  final List<String> stores;
  final String Function(String) getStoreDbValue;
  final String Function(String) getStoreDisplayName;


  const AddEditProductScreen({
    super.key, 
    required this.productsCollection, 
    this.product,
    required this.stores,
    required this.getStoreDbValue,
    required this.getStoreDisplayName,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController(); 
  
  late String _selectedStore;
  // 🆕 متغير حالة جديد للتصنيف
  late String _selectedCategory; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _selectedStore = widget.stores[0];
    _selectedCategory = kProductCategories[0]; // تعيين قيمة افتراضية

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _imageUrlController.text = widget.product!.imageUrl ?? ''; 
      
      final String storedDbValue = widget.product!.storeName;
      final String displayName = widget.getStoreDisplayName(storedDbValue);
      
      _selectedStore = widget.stores.firstWhere(
        (store) => store == displayName,
        orElse: () => widget.stores[0],
      );
      
      // 🆕 تهيئة التصنيف بناءً على المنتج الحالي
      _selectedCategory = widget.product!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose(); 
    super.dispose();
  }

  Future<void> _submitProduct() async {
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
      final String storeValue = widget.getStoreDbValue(_selectedStore);
      
      final String? imageUrl = _imageUrlController.text.trim().isEmpty 
          ? null 
          : _imageUrlController.text.trim();
          
      final Map<String, dynamic> productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'storeName': storeValue, 
        'imageUrl': imageUrl, 
        'category': _selectedCategory, // 🆕 تضمين التصنيف
      };


      if (widget.product == null) {
        productData['dateAdded'] = FieldValue.serverTimestamp();
        await widget.productsCollection.add(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إضافة المنتج بنجاح', textAlign: TextAlign.right)),
          );
        }
      } else {
        await widget.productsCollection.doc(widget.product!.id).update(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم تعديل المنتج بنجاح', textAlign: TextAlign.right)),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isRequired = true, 
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.accentGold) : null,
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
        if ((keyboardType == TextInputType.number || keyboardType == TextInputType.phone) && value != null && value.isNotEmpty) {
          // التحقق من أن القيمة رقمية إذا كان نوع لوحة المفاتيح رقماً
          if (double.tryParse(value) == null) {
             return 'يجب أن تكون القيمة رقماً صحيحاً أو عشرياً.';
          }
        }
        return null;
      },
    );
  }

  // 🆕 دالة بناء قائمة اختيار التصنيف المنسدلة
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'اختر التصنيف',
        labelStyle: const TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold),
        prefixIcon: const Icon(Icons.category, color: AppColors.accentGold),
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
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryStone, size: 30),
      items: kProductCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category, textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يجب اختيار تصنيف للمنتج.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
        backgroundColor: AppColors.primaryStone,
        foregroundColor: AppColors.accentGold,
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
                controller: _nameController,
                label: 'اسم المنتج',
                icon: Icons.label,
              ),
              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _descriptionController,
                label: 'الوصف التفصيلي',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _priceController,
                      label: 'السعر (ج.م)',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _quantityController,
                      label: 'الكمية المتوفرة',
                      icon: Icons.production_quantity_limits,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextFormField( 
                controller: _imageUrlController,
                label: 'رابط صورة المنتج (URL) - اختياري',
                icon: Icons.image,
                keyboardType: TextInputType.url,
                maxLines: 2,
                isRequired: false, 
              ),
              
              const SizedBox(height: 20),

              // 🆕 حقل اختيار التصنيف
              _buildCategoryDropdown(), 
              
              const SizedBox(height: 20),

              // حقل اختيار المتجر
              DropdownButtonFormField<String>(
                value: _selectedStore,
                decoration: InputDecoration(
                  labelText: 'اختر المتجر',
                  labelStyle: const TextStyle(color: AppColors.primaryStone, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.store, color: AppColors.accentGold),
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
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryStone, size: 30),
                items: widget.stores.map((String store) {
                  return DropdownMenuItem<String>(
                    value: store,
                    child: Text(store, textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStore = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStone,
                  foregroundColor: AppColors.accentGold,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  shadowColor: AppColors.primaryStone.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 4),
                      )
                    : Text(
                        isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}