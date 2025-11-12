import 'dart:ui';
import 'package:churchapp/welcome/on_boarding/on_boarding_screen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  static String routeName = "/StartScreen";

  const StartScreen({Key? key}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _scaleLogo;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.5)),
    );

    _scaleLogo = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeText = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8)),
    );

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🕊️ الخلفية (صورة العذراء)
          Positioned.fill(
            child: Image.asset(
              "assets/images/eladra.png",
              fit: BoxFit.cover,
            ),
          ),

          // ✨ تدرّج شفاف لإضافة عمق ودفء
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // 💫 تأثير ضبابي خفيف يعطي لمسة احترافية
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Container(color: Colors.black.withOpacity(0)),
          ),

          // ✝️ المحتوى المتحرك
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // ✝️ العنوان الرئيسي (اسم الكنيسة)
                FadeTransition(
                  opacity: _fadeLogo,
                  child: ScaleTransition(
                    scale: _scaleLogo,
                    child: const Text(
                      "كنيسة السيده العذراء مريم\nوالقديس نيقولاوس",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.6,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black45,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 🕊️ النص الفرعي
                FadeTransition(
                  opacity: _fadeText,
                  child: const Text(
                    "❤️ الله محبة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Cairo",
                    ),
                  ),
                ),

                const Spacer(),

                // 🌈 زر البدء الجميل
                SlideTransition(
                  position: _buttonSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40.0, vertical: 30),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const OnBoardingScreen()),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFB3E5FC),
                              Color(0xFF81D4FA),
                              Color(0xFF4FC3F7),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "ابدأ",
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "Cairo",
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
