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
  static const Color accentGold = Color(0xFFFFD700); 
  static const Color backgroundBeige = Color(0xFFFFF8F0); 
  
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color alertRed = Color(0xFFB71C1C);
  static const Color successGreen = Color(0xFF2E7D32);
}

// الخريطة الثابتة لربط الاسم المعروض بقيمة قاعدة البيانات
const Map<String, String> _storeMapping = {
   'كانتين كنيسه القديس': 'Stall 1',
   'كانتين كنيسه العذراء': 'Stall 2',
};

// نموذج بيانات المنتج (لم يتم تعديله)
class StoreProduct {
  final String id;
  final String name;
  final String description;
  final String storeName; 
  final double price;
  final int quantity; 
  final String? imageUrl;
  final Timestamp? dateAdded; 

  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.storeName,
    required this.price,
    required this.quantity,
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
    };
  }
  
  bool get isAvailable => quantity > 0;
}

// =========================================================
// II. الصفحة الرئيسية (StorePage) - منطق Store Mapping محسن
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
  
  bool _isAdmin = false; 
  
  final String appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
  late final CollectionReference _productsCollection;

  // استخدام الخريطة الثابتة
  final List<String> _stores = _storeMapping.keys.toList();
  
  late String _currentStoreFilter;

  // دالة مساعدة لربط اسم المتجر المعروض (Display Name) بالقيمة المخزنة في قاعدة البيانات (DB Value)
  String _getStoreDbValue(String displayName) {
    return _storeMapping[displayName] ?? 'Stall 1';
  }

  // دالة مساعدة لربط القيمة المخزنة في قاعدة البيانات (DB Value) باسم المتجر المعروض
  String _getStoreDisplayName(String dbValue) {
    final entry = _storeMapping.entries.firstWhere(
      (e) => e.value == dbValue,
      orElse: () => MapEntry(_stores[0], 'Stall 1'),
    );
    return entry.key;
  }


  @override
  void initState() {
    super.initState();
    
    _currentStoreFilter = _stores[0];

    _productsCollection = _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('store_products');
    
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _isAdmin = user != null;
        });
      }
    });
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }

  Future<void> deleteProduct(BuildContext context, String productId) async {
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
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون مشرفاً للقيام بهذه العملية.')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          productsCollection: _productsCollection,
          product: product,
          stores: _stores,
          getStoreDbValue: _getStoreDbValue, // تمرير الدالة
          getStoreDisplayName: _getStoreDisplayName, // تمرير الدالة
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String storeQueryValue = _getStoreDbValue(_currentStoreFilter);
    
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

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsCollection
                  .where('storeName', isEqualTo: storeQueryValue) 
                  .snapshots(),
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
                        'لا توجد منتجات حالياً في $_currentStoreFilter.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 18, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                List<StoreProduct> products = snapshot.data!.docs
                    .map((doc) => StoreProduct.fromFirestore(doc))
                    .toList();
                
                products.sort((a, b) {
                  final dateA = a.dateAdded?.toDate().millisecondsSinceEpoch ?? 0;
                  final dateB = b.dateAdded?.toDate().millisecondsSinceEpoch ?? 0;
                  return dateB.compareTo(dateA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(
                      product: products[index],
                      isAdmin: _isAdmin,
                      onDelete: () => deleteProduct(context, products[index].id),
                      onEdit: () => _navigateToAddEditProduct(product: products[index]),
                      getStoreDisplayName: _getStoreDisplayName, // تمرير الدالة
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: _isAdmin
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
      color: AppColors.backgroundBeige, // خلفية بيج
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Center(
        child: ToggleButtons(
          isSelected: _stores.map((store) => store == _currentStoreFilter).toList(),
          onPressed: (index) {
            setState(() {
              _currentStoreFilter = _stores[index];
            });
          },
          borderRadius: BorderRadius.circular(25), // حواف دائرية فخمة
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
}

// =========================================================
// III. مكونات الواجهة (UI Components) - السعر المتدرج
// =========================================================

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String Function(String) getStoreDisplayName; // دالة جلب الاسم المعروض

  const _ProductCard({
    required this.product,
    required this.isAdmin,
    required this.onDelete,
    required this.onEdit,
    required this.getStoreDisplayName,
    super.key,
  });

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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStone.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.accentGold, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.shopping_bag_outlined, size: 45, color: AppColors.primaryStone),
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

                      // السعر (المبهر) - تطبيق الـ Gradient
                      Text(
                        '${NumberFormat.currency(locale: 'ar', symbol: 'ج.م').format(product.price)}', 
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          // تطبيق الـ Gradient الذهبي على النص
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: <Color>[
                                Color.fromARGB(255, 138, 115, 0),
                                Color.fromARGB(255, 138, 115, 0),
                                Color.fromARGB(255, 136, 114, 2),
                              ],
                            ).createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0), // يجب تحديد حجم تقريبي
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ].reversed.toList(),
            ),

            const SizedBox(height: 15),
            
            Text(
              product.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Divider(color: AppColors.primaryStone, thickness: 0.5, height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  availabilityText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: product.isAvailable ? AppColors.successGreen : AppColors.alertRed,
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStone.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    'متجر: $storeDisplayName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryStone,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ].reversed.toList(),
            ),

            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
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
// شاشة إضافة/تعديل المنتج (AddEditProductScreen) - منطق Store Mapping محسن
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  
  late String _selectedStore;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _selectedStore = widget.stores[0];

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.quantity.toString();
      
      // تحديد المتجر الصحيح باستخدام الدالة الممررة
      final String storedDbValue = widget.product!.storeName;
      final String displayName = widget.getStoreDisplayName(storedDbValue);
      
      _selectedStore = widget.stores.firstWhere(
        (store) => store == displayName,
        orElse: () => widget.stores[0],
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
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
      // استخدام الدالة الممررة
      final String storeValue = widget.getStoreDbValue(_selectedStore);
      
      final Map<String, dynamic> productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'storeName': storeValue, 
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
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب.';
        }
        if (keyboardType == TextInputType.number || keyboardType == TextInputType.phone) {
          if (double.tryParse(value) == null) {
             return 'يجب أن تكون القيمة رقماً صحيحاً أو عشرياً.';
          }
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