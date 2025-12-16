// lib/services/christian_bot_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; 

class ChristianBotService {
  
  // يتم قراءة المفتاح من ملف .env
  final String apiKey = dotenv.env['GEMINI_KEY']!;
  late final GenerativeModel model;
  
  ChristianBotService() {
    
    // تهيئة النموذج gemini-2.5-flash
    // لا نستخدم config هنا للتوافق مع الإصدار ^0.4.7
    model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
    );
  }

  // 🎯 تم تعديل الدالة لتقبل سؤال المستخدم كمتغير
  Future<String> getBotResponse(String userQuestion) async {
    
    // دمج تعليمات النظام مع سؤال المستخدم الفعلي
    final systemInstructions = """
**اللغة والردود:** يجب أن تكون جميع ردودك **باللغة العربية الفصحى**.
**الدور:** أنت مساعد مسيحي متعمق ومحايد.
**مصدر المعلومات الوحيد:**
- الكتاب المقدس.
- تعاليم آباء الكنيسة الأوائل والتقليد الأرثوذكسي.
- السنكسار القبطي والطقس الكنسي.

**قواعد الرد:**
- لا تخترع عقائد جديدة.
- إذا سألك المستخدم سؤالاً خارج نطاق التعاليم المسيحية، أجب بناءً على الموارد المسيحية فقط.
- يجب أن تكون الإجابات دقيقة، بسيطة، وروحية.

**مهمتك:** الإجابة على السؤال التالي:
---
السؤال هو: $userQuestion
""";
    
    // إنشاء المحتوى كنص واحد يمثل رسالة المستخدم
    final userContent = Content.text(systemInstructions);
    
    try {
      // إرسال طلب المحتوى
      final response = await model.generateContent(
        [userContent], 
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return "خطأ: لم يقدم رداً واضحاً أو تم حظر الرد لأسباب تتعلق بالسلامة.";
      }
    } on GenerativeAIException catch (e) {
      print("Gemini API Error: $e");
      
      // 🎯 المنطق الجديد لاكتشاف خطأ "النموذج مثقل" (Overloaded Model)
      if (e.message.contains("503") || e.message.contains("overloaded")) {
        return "يوجد ضغط كبير على الخوادم حاليًا، يرجى المحاولة مرة أخرى بعد قليل.";
      }
      
      // رسالة الخطأ الافتراضية لأي خطأ GenerativeAIException آخر
      return "يوجد ضغط كبير على الخوادم حاليًا، يرجى المحاولة مرة أخرى بعد قليل."; 
    } catch (e) {
      return "خطأ غير متوقع: $e";
    }
  }
}