// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firebase Firestore
import 'dart:async';


// =========================================================================
// 0. تعريفات افتراضية (AppColors و RoundButton)
// =========================================================================

// تعريف افتراضي للألوان (بافتراض نفس الألوان التي استخدمتها سابقاً)
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color darkGrayColor = Color(0xFFC0C0C0);
  static const Color primaryColor = const Color.fromARGB(255, 0, 93, 139); // Dark Maroon/Deep Red
  static const Color accentColor = Color.fromARGB(255, 242, 241, 240); // Electric Gold/Amber
  static const Color lightGrayColor = Color(0xFF555555);
  static const Color skeletonColor = Color(0xFF333333); // لون الهيكل

  static List<Color> primaryG = [const Color.fromARGB(255, 0, 93, 139), const Color.fromARGB(255, 0, 102, 204)]; // تدرج أساسي
  static List<Color> secondaryG = [const Color.fromARGB(255, 248, 247, 246), const Color.fromARGB(255, 248, 248, 246)]; // تدرج ثانوي (ذهبي)
}

// تعريف افتراضي لزر دائري (RoundButton)
enum RoundButtonType { primaryBG, secondaryBG }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback? onPressed;

  const RoundButton({super.key, required this.title, required this.type, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: type == RoundButtonType.primaryBG ? AppColors.primaryG : AppColors.secondaryG,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: MaterialButton(
        onPressed: onPressed,
        minWidth: double.maxFinite,
        height: 50,
        child: Text(
          title,
          style: const TextStyle(color: AppColors.whiteColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =========================================================================
// 1. نموذج البيانات (DeveloperProfile)
// =========================================================================

class DeveloperProfile {
  final String name;
  final String title;
  final String imageUrl;
  final String email;
  final String phone;
  final String github;
  final String linkedin;
  final String facebook;
  final String instagram;

  DeveloperProfile({
    required this.name,
    required this.title,
    required this.imageUrl,
    required this.email,
    required this.phone,
    required this.github,
    required this.linkedin,
    required this.facebook,
    required this.instagram,
  });

  // دالة تحويل من Firestore Map
  factory DeveloperProfile.fromFirestore(Map<String, dynamic> data) {
    return DeveloperProfile(
      name: data['name'] ?? 'N/A',
      title: data['title'] ?? 'Developer',
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/120x120/555555/FFFFFF?text=KE',
      email: data['email'] ?? 'N/A',
      phone: data['phone'] ?? 'N/A',
      github: data['github'] ?? 'N/A',
      linkedin: data['linkedin'] ?? 'N/A',
      facebook: data['facebook'] ?? 'N/A',
      instagram: data['instagram'] ?? 'N/A',
    );
  }
}


// =========================================================================
// 2. الهيكل الهيكلي للتحميل (Skeleton Loader) - لجعل التحميل مبهراً
// =========================================================================
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    
    // 💡 استخدام Shimmer Effect بسيط لخلفية الألوان
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس وهمي (صورة واسم)
          Center(
            child: Column(
              children: [
                Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.skeletonColor, shape: BoxShape.circle)),
                const SizedBox(height: 10),
                Container(width: 180, height: 25, color: AppColors.skeletonColor),
                const SizedBox(height: 5),
                Container(width: 150, height: 18, color: AppColors.skeletonColor),
              ],
            ),
          ),
          
          const Divider(color: AppColors.lightGrayColor, height: 40),

          // عنوان وهمي
          Container(width: 150, height: 20, color: AppColors.skeletonColor),
          const SizedBox(height: 15),

          // صفوف الاتصال الوهمية
          ...List.generate(6, (index) => 
            Container(
              height: 70,
              width: mediaSize.width,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.skeletonColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15)
              ),
            )
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. HowUsView - التصميم الجديد المبهر + Firebase
// =========================================================================
class HowUsView extends StatefulWidget {
  const HowUsView({super.key});

  @override
  State<HowUsView> createState() => _HowUsViewState();
}

class _HowUsViewState extends State<HowUsView> with SingleTickerProviderStateMixin {
  
  // 🔥 جلب البيانات من Firestore
  Future<DeveloperProfile?> _fetchProfile() async {
    try {
      // ⚠️ يجب التأكد من أن المسار صحيح (المجموعة هي 'developer_info' ويحتوي على مستند واحد فقط)
      final snapshot = await FirebaseFirestore.instance.collection('developer_info').limit(1).get();
      
      if (snapshot.docs.isNotEmpty) {
        return DeveloperProfile.fromFirestore(snapshot.docs.first.data());
      }
      // في حالة عدم وجود بيانات، ارجع بقيمة وهمية
      return DeveloperProfile(
        name: 'Default User', 
        title: 'No Data Found', 
        imageUrl: 'https://placehold.co/120x120/555555/FFFFFF?text=KE',
        email: 'default@example.com', 
        phone: '1234567890', 
        github: '', 
        linkedin: '', 
        facebook: '', 
        instagram: ''
      );
      
    } catch (e) {
      print("Firebase Fetch Error: $e");
      // في حالة الخطأ، ارجع بقيمة وهمية
      return null;
    }
  }

  // متحكم الأنيميشن
  late AnimationController _animationController;
  // قائمة أنيميشن الانزلاق
  List<Animation<Offset>> _slideAnimations = [];

  // بيانات الاتصال الديناميكية (ستُملأ من Firebase)
  List<Map<String, String>> _contactItems = [];


  @override
  void initState() {
    super.initState();
    // تهيئة الـ Controller
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    
    // لا نبدأ الأنيميشن هنا، بل بعد تحميل البيانات.
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // دالة مساعدة لملء بيانات الاتصال وتشغيل الأنيميشن
  void _setupAnimations(DeveloperProfile profile) {
      _contactItems = [
          {"label": "Instagram", "icon": "📸", "value": "@${profile.instagram.split('/').last}", "link": profile.instagram},
          {"label": "Facebook", "icon": "💙", "value": "Open Profile", "link": profile.facebook},
       
          {"label": "Phone", "icon": "📱", "value": profile.phone, "link": "tel:${profile.phone}"},
  
          {"label": "Email", "icon": "✉️", "value": profile.email, "link": "mailto:${profile.email}"},
          {"label": "LinkedIn", "icon": "🔗", "value": "Open Profile", "link": profile.linkedin},
          {"label": "GitHub", "icon": "⚙️", "value": "View Repos", "link": profile.github},
      ];
      
      _slideAnimations = List.generate(
        _contactItems.length,
        (index) => Tween<Offset>(
          begin: const Offset(0, 0.5), 
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index) / _contactItems.length, 
              1.0, 
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
      
      // بدء الأنيميشن بعد ملء البيانات
      _animationController.forward(from: 0.0);
  }
  
  // =========================================================================
  // الدوال المساعدة - للروابط وصف الاتصال
  // =========================================================================
  
  void _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // 💡 ويدجت صف الاتصال (مُعدَّل ليتوافق مع الأنيميشن الجديد)
  Widget _buildContactRow(int index, Map<String, String> item) {
    // 💡 منع إنشاء الـ SlideTransition إذا لم يتم تهيئة الـ Animations بعد
    if (index >= _slideAnimations.length) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _animationController,
        child: InkWell(
          onTap: () => _launchURL(item['link']!, context),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              // خلفية شفافة لجعلها تندمج مع الخلفية السوداء
              color: AppColors.lightGrayColor.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.lightGrayColor.withOpacity(0.5), width: 0.5),
            ),
            child: Row(
              children: [
                Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w600, 
                          color: AppColors.darkGrayColor
                        ),
                      ),
                      Text(
                        item['value']!,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.accentColor // اللون الذهبي مبهر
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 💡 إضافة IconData لتمييز الأيقونة
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  
  // =========================================================================
  // 🔨 البناء الرئيسي (CustomScrollView + FutureBuilder)
  // =========================================================================
  
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final mediaSize = mediaQueryData.size;
    
    // 🔥 استخدام FutureBuilder لجلب البيانات مرة واحدة من Firestore
    return FutureBuilder<DeveloperProfile?>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        
        // 1. حالة الخطأ
        if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && snapshot.data == null)) {
            return const Scaffold(
                backgroundColor: AppColors.blackColor,
                body: Center(child: Text('❌ Failed to load profile data.', style: TextStyle(color: AppColors.whiteColor))));
        }

        // 2. حالة التحميل (عرض الهيكل الوهمي)
        if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(
              backgroundColor: AppColors.blackColor,
              body: CustomScrollView(
                slivers: [
                   // Header Placeholder
                   SliverAppBar(
                      expandedHeight: mediaSize.height * 0.4, 
                      floating: false, pinned: true, 
                      backgroundColor: AppColors.primaryColor, 
                      flexibleSpace: Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.primaryG)),
                          alignment: Alignment.center,
                          child: const ProfileSkeleton()
                      ),
                   ),
                   // Body Placeholder
                   SliverList(delegate: SliverChildListDelegate([const ProfileSkeleton()])),
                ]
              ),
            );
        }
        
        // 3. حالة النجاح (عرض البيانات الحقيقية)
        final profile = snapshot.data!;
        
        // 💡 إعداد الأنيميشن عند التحميل لأول مرة
        if (_slideAnimations.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                _setupAnimations(profile);
            });
        }


        return Scaffold(
          backgroundColor: AppColors.blackColor,
          body: CustomScrollView(
            slivers: [
              // ------------------------------------------------------------------
              // 1. Sliver AppBar (الـ Header المبهر مع الصورة الديناميكية)
              // ------------------------------------------------------------------
              SliverAppBar(
                expandedHeight: mediaSize.height * 0.4,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryColor, 
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryG, // تدرج أحمر قوي
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                        padding: EdgeInsets.only(top: mediaQueryData.padding.top + 20),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                // 🔥 صورة المطور (من URL)
                                CircleAvatar(
                                    radius: 80,
                                    backgroundColor: AppColors.accentColor, // خلفية ذهبية
                                    child: ClipOval(
                                        child: Image.network(
                                            profile.imageUrl,
                                            width: 160,
                                            height: 160,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(child: CircularProgressIndicator(color: AppColors.whiteColor));
                                            },
                                            errorBuilder: (context, error, stackTrace) => 
                                                Text(
                                                    '${profile.name.substring(0,1)}${profile.name.split(' ').last.substring(0,1)}', 
                                                    style: const TextStyle(fontSize: 40, color: AppColors.blackColor, fontWeight: FontWeight.bold)
                                                ),
                                        ),
                                    ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                    profile.name,
                                    style: const TextStyle(
                                        fontSize: 28, 
                                        fontWeight: FontWeight.w900, 
                                        color: AppColors.whiteColor
                                    ),
                                ),
                                Text(
                                    profile.title,
                                    style: TextStyle(
                                        fontSize: 18, 
                                        color: AppColors.accentColor.withOpacity(0.9) 
                                    ),
                                ),
                            ],
                        ),
                    ),
                  ),
                ),
              ),
              
              // ------------------------------------------------------------------
              // 2. Sliver List (المحتوى والتفاصيل)
              // ------------------------------------------------------------------
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          const Divider(color: AppColors.lightGrayColor, height: 40),

                        //  قسم التواصل (مع أنيميشن الظهور)
                          const Text(
                            'Contact & Portfolio:', 
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.w700, 
                              color: AppColors.accentColor
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // 💡 عرض صفوف التواصل مع الأنيميشن (ديناميكي من _contactItems)
                          // نستخدم AnimatedBuilder لضمان إعادة بناء الصفوف عند تشغيل الأنيميشن
                          AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                  if (_contactItems.isEmpty) {
                                      // إذا لم تكتمل تهيئة الأنيميشن بعد (نادراً ما تحدث بعد الإعداد)
                                      return const ProfileSkeleton();
                                  }
                                  return Column(
                                      children: List.generate(_contactItems.length, (index) {
                                          return _buildContactRow(index, _contactItems[index]);
                                      }),
                                  );
                              },
                          ),


                          const SizedBox(height: 40),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}