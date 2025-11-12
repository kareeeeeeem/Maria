// File: lib/view/welcome/on_boarding/widgets/pager_widget.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// 🌟 استيراد البكج الجديدة للرسوم المتحركة
// يجب التأكد من مسار AppColors الصحيح في تطبيقك
// ...

// تعريف AppColors لضمان عمل PagerWidget بشكل منفصل
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color primaryColor1 = Color(0xFF92A3FD); 
}

class PagerWidget extends StatelessWidget {
  final Map obj;
  const PagerWidget({Key? key, required this.obj}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🌟 استخراج لون الخلفية من الـ Map
    Color backgroundColor = obj["color"] as Color? ?? AppColors.primaryColor1; 

    return Column(
      children: [
        // 🌟 الجزء العلوي للرسوم المتحركة (Lottie)
        Expanded(
          flex: 1, // زيادة Flex لإعطاء مساحة كافية للرسوم
          child: Container(
             color: backgroundColor, // استخدام لون الصفحة كخلفية
             width: double.infinity, 
             child: 
             // 🛑 استبدال Image.asset بـ Lottie.asset
             Lottie.asset(
               obj["lottie_asset"].toString(), // استخدام lottie_asset
               fit: BoxFit.contain, // تأكد من ملاءمة الرسوم
               repeat: true, // تكرار الرسوم
               alignment: Alignment.bottomCenter, // وضع الرسوم في الأسفل
             ),
          ),
        ),
        // 🌟 الجزء السفلي للنص
        Expanded(
          flex: 1, // تقليل Flex لتركيز النص في جزء أصغر
          child: Container(
            color: backgroundColor, // استخدام لون الصفحة أيضاً هنا
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, 
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  obj["title"].toString(),
                  style: const TextStyle(
                    color: AppColors.whiteColor, 
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // توسيط النص
                ),
                const SizedBox(height: 15),
                // Text(
                //   obj["subtitle"].toString(),
                //   style: TextStyle(
                //     color: AppColors.whiteColor.withOpacity(0.8), 
                //     fontSize: 16,
                //   ),
                //   textAlign: TextAlign.center, // توسيط النص
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}