import 'package:flutter/material.dart';
import '../services/christian_bot_service.dart';

class ChristianBotPage extends StatefulWidget {
    static const String routeName = '/ChristianBotPage';

  @override
  _ChristianBotPageState createState() => _ChristianBotPageState();
}

class _ChristianBotPageState extends State<ChristianBotPage> {
  String result = "مرحباً! أنا مساعدك المسيحي. تفضل بطرح سؤالك ";
  bool loading = false;
  
  // 🆕 تم تصحيح اسم المتحكم هنا
  final TextEditingController _questionController = TextEditingController(); 
  final botService = ChristianBotService();

  void getBotResponse() async {
    // 1. تحقق من عدم وجود نص فارغ
    if (_questionController.text.trim().isEmpty) {
      setState(() {
        result = "الرجاء إدخال سؤالك أولاً.";
      });
      return;
    }
    
    final userQuestion = _questionController.text;
    
    // 2. مسح حقل الإدخال
    _questionController.clear(); 
    
    setState(() {
      loading = true;
      // عرض سؤال المستخدم قبل جلب الرد
      result = "أنت تسأل: ${userQuestion}\n\nجاري البحث عن الإجابة...";
    });

    // 3. استدعاء الدالة الصحيحة وتمرير السؤال
    final res = await botService.getBotResponse(userQuestion);

    setState(() {
      result = res;
      loading = false;
    });
  }
  
  // 🆕 يجب التخلص من المتحكم عند إغلاق الـ Widget لتجنب تسريب الذاكرة
  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text(
          "Christian chatbot", // 1. النص أولاً
          style: TextStyle(
            // 2. تعريف اللون الصحيح مباشرة
            color: Colors.white, 
          ),
        ),       
         backgroundColor: const Color(0xFF4E342E),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          // 1. منطقة عرض الرد
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        result,
                        style: const TextStyle(fontSize: 18, height: 1.5), 
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
          ),
          
          // 2. منطقة الإدخال وزر الإرسال
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                // حقل الإدخال
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: "اكتب سؤالك هنا...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => getBotResponse(), // يمكن الإرسال عبر Enter
                  ),
                ),
                const SizedBox(width: 8),
                // زر الإرسال
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF4E342E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: loading ? null : getBotResponse,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}