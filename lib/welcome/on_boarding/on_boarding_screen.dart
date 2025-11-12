
import 'package:churchapp/aus/signup/signup_screen.dart';
import 'package:churchapp/welcome/on_boarding/pager_widget.dart';
import 'package:flutter/material.dart';
// 🌟 استيراد البكج الجديدة
import 'package:liquid_swipe/liquid_swipe.dart'; 

class OnBoardingScreen extends StatefulWidget {
  static String routeName = "/OnBoardingScreen";
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  
  // 🛑 لم نعد بحاجة إلى PageController (يمكن حذفه)
  // PageController pageController = PageController();
  
  // 🌟 نحتاج إلى LiquidController للتحكم البرمجي في الانتقال
  LiquidController liquidController = LiquidController(); 

  List pageList = [
     {
      "title":
          "فَرِحْتُ بِالْقَائِلِينَ لِي\nإِلَى بَيْتِ الرَّبِّ نَذْهَبُ",
      "lottie_asset": "assets/lottie/Church.json",
      "color": const Color.fromARGB(255, 85, 165, 231),
    },
    
    {
      "title":
          "سِرَاجٌ لِرِجْلِي كَلاَمُكَ\nوَنُورٌ لِسَبِيلِي",
      "lottie_asset": "assets/lottie/Dove.json",
      "color": const Color.fromARGB(255, 91, 128, 154),
    },
    {
      "title":
          "فَقَالَتْ مَرْيَمُ تُعَظِّمُ نَفْسِي الرَّبَّ وَتَبْتَهِجُ\nرُوحِي بِاللَّهِ مُخَلِّصِي",
      "lottie_asset": "assets/lottie/Mary.json",
      "color": const Color.fromARGB(255, 57, 158, 176),
    },
    // {
    //   "title":
    //       "لِأَنَّ كَلِمَةَ اللهِ حَيَّةٌ وَفَعَّالَةٌ، وَأَمْضَى مِنْ كُلِّ سَيْفٍ ذِي حَدَّيْنِ",
    //   "lottie_asset": "assets/lottie/bible.json",
    //   "color": const Color(0xFFD4B483),
    // },
  ];

  int selectedIndex = 0;

  // 🌟 قمنا بتعديل دالة البناء لاستخدام LiquidSwipe
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🛑 لا حاجة لـ Stack في الـ Scaffold Body، لأن LiquidSwipe يتعامل مع الـ Pages
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // 🌟 استبدال PageView.builder بـ LiquidSwipe
          LiquidSwipe(
            pages: pageList.map((temp) {
              return PagerWidget(obj: temp as Map);
            }).toList(),
            
            // 🌟 خصائص التحكم في الـ Liquid Swipe
            onPageChangeCallback: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            liquidController: liquidController, // ربط الـ Controller
            fullTransitionValue: 400, // قيمة الانتقال السائل (افتراضية جيدة)
            waveType: WaveType.liquidReveal, // اختيار نوع الموجة
            enableLoop: false, // لا نريد تكرار في الـ OnBoarding

          ),
          
          // 🌟 زر التنقل ومؤشر التقدم (يبقى كما هو)
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    color:  Colors.white,
                    value: (selectedIndex+1) / pageList.length, // تقسيم على طول القائمة
                    strokeWidth: 3,
                  ),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      color:  Colors.white),
                  child: IconButton(
                    icon: const Icon(
                      Icons.navigate_next,
                      color:  Color.fromARGB(255, 64, 64, 64), // استخدام لون متناسق
                      size: 50,
                    ),
                    onPressed: () {
                      if (selectedIndex < pageList.length - 1) {
                        // 🌟 استخدام liquidController.animateToPage بدلاً من PageController
                        liquidController.animateToPage(
                          page: selectedIndex + 1,
                          duration: 700,
                        );
                      } else {
                        // ✅ لو وصلت لآخر صفحة → روح على صفحة التسجيل (SignupScreen)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const UserSignUpScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}