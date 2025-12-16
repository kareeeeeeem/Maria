import 'dart:ui';
import 'package:flutter/material.dart';

//========================================================================
// 1. App Colors & Data Structure
//========================================================================

class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // البني الداكن
  static const Color secondaryGold = Color(0xFFFFF8E1); // الذهبي الفاتح
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  static const Color primaryDark = primaryBlue;       
  static const Color accentColor = secondaryGold;     
  static const Color primaryColor1 = primaryBlue;     
  static const Color whiteColor = cardColor;         
  static const Color fieldFillColor = Color(0xFF5D4037); 
}

class ChurchData {
  final String name;
  final String address;
  final String description;
  final IconData icon;
  final Color color;
  
  ChurchData({
    required this.name,
    required this.address,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// الترتيب: العذراء مريم أولاً
final List<ChurchData> churches = [
    ChurchData(
    name: 'كنيسة السيدة العذراء مريم ببنها',
    address: 'سعد زغلول، قسم بنها، بنها',
    description:
        'هي الكنيسة الأم والأقدم في بنها، وهي مركز روحي له تاريخ طويل يمتد لعدة قرون. تقع في قلب المدينة وتعتبر مزاراً مهماً لكل الأقباط. سُميت باسم القديسة العذراء، والدة الإله، وتحتوي على أيقونات تاريخية نادرة. بالإضافة إلى القداسات المنتظمة، تشتهر الكنيسة بخدمة افتقاد متكاملة، ودورها الحيوي في رعاية الشباب والأنشطة الكشفية. تقام بها صلوات التمجيد الخاصة بالعذراء كل شهر في كيهك، مما يجعلها مركزاً حقيقياً للإيمان والخدمة في بنها.',
    icon: Icons.church, // تم تصحيح الأيقونة
    color: AppColors.secondaryGold.withOpacity(0.8),
  ),
  ChurchData(
    name: 'كنيسة القديس نيقولاوس ببنها',
    address: 'الشهيد عادل إبراهيم أبو سينا، قسم بنها، بنها',
    description:
        'تُعد كنيسة القديس نيقولاوس (مارنيقولا) في بنها منارة روحية وتاريخية في الإيبارشية. تأسست كمركز عبادة لخدمة الأسر القبطية في المنطقة، وتحمل اسم شفيع البحارة والمسافرين. تتميز الكنيسة بقداساتها الدورية، بالإضافة إلى اجتماعات دراسة الكتاب المقدس والخدمات الاجتماعية النشطة التي تخدم شريحة واسعة من المجتمع. تشتهر الكنيسة بتصميمها المعماري الذي يمزج بين العمارة القبطية التقليدية والعناصر الحديثة، مما يجعلها مكاناً مثالياً للصلاة والتأمل. كما تقام فيها احتفالات سنوية كبرى بعيد القديس نيقولاوس في ديسمبر.',
    icon: Icons.church,
    color: AppColors.secondaryGold,
  ),
  
];

//========================================================================
// 2. شاشة معلومات الكنائس (ChurchInfoScreen)
//========================================================================

class ChurchInfoScreen extends StatelessWidget {
  static const String routeName = '/church_info';
  const ChurchInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('عن كنائسنا وآبائنا', style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. بطاقات الكنائس
            ...churches.map((church) => _buildChurchCard(context, church)).toList(),
            
            const SizedBox(height: 30),
            
            // 2. سيرة السيدة العذراء (نص كامل ومنسق)
            _buildVirginMarySection(),
            
            const SizedBox(height: 20),

            // 3. آباء كنيسة العذراء المتنيحين
            _buildDepartedSection(
              title: '🕊️ بركة آباء كنيسة العذراء 🕊️',
              fathers: [
                _FatherInfo('المتنيح الأنبا مكسيموس القديس', 'مطران بنها وقويسنا (1963-1992). رجل الصلاة والزهد والوداعة الذي أحبه الجميع.'),
                _FatherInfo('القمص المتنيح قزمان', 'من  آباء الكنيسة الأجلاء، تميز بالحكمة والوقار والخدمة الباذلة.'),
                _FatherInfo('القمص المتنيح دميان', 'أب الاعتراف الحنون وخادم الهيكل الأمين الذي تتلمذ على يديه الكثيرون.'),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(color: AppColors.accentColor, thickness: 1),
            const SizedBox(height: 20),

            // 4. سيرة القديس نيقولاوس
            _buildSaintNicholasSection(),

            const SizedBox(height: 20),

            // 5. آباء كنيسة القديس نيقولاوس (أبونا صلبامون المالح)
           // 5. آباء كنيسة القديس نيقولاوس (القمص صرابامون سيدهم)
_buildDepartedSection(
  title: '🕊️ بركة آباء كنيسة القديس نيقولاوس 🕊️',
  fathers: [
    _FatherInfo(
      'أبونا المتنيح طيب الذكر القمص صرابامون سيدهم', 
      '''• ملاك كنيسة القديس نيقولاوس ببنها.
• وُلد في يوم السبت الموافق ٢٦ / ٤ / ١٩٥٢م.
• تربى وخدم بكنيسة السيدة العذراء مريم - ش. أحمد عصمت بالقاهرة، وكان مسئولاً عن خدمة اجتماع الشباب بالكنيسة.
• حصل على بكالوريوس هندسة تكنولوجيا بجامعة بنها عام ١٩٧٧م.
• نال نعمة الكهنوت بيد المتنيح الأنبا مكسيموس مطران القليوبية ومركز قويسنا، يوم الجمعة الموافق ٦ / ٣ / ١٩٨٧م.
• نال نعمة القمصية بيد الأنبا مكسيموس أسقف بنها وقويسنا (آنذاك)، يوم الجمعة الموافق ٥ / ٣ / ٢٠٠٤م.
• اتصف بالبساطة، وحفظه للترانيم الروحية، وصوته الشجي المريح في إلقائه للترانيم، وشرحه المبسط للكتاب المقدس.
• تنيح بسلام يوم الأحد الموافق ٢ / ١١ / ٢٠٢٥م عن عمر يناهز ٧٣ عاماً بعد خدمة كهنوتية امتدت حوالي ٣٩ عاماً، لينطفئ عمود منير على الأرض ويذهب ليضيء في سماء الأبرار ويشفع فينا أمام عرش النعمة.''',
    ),
  ],
),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  //========================================================================
  // 3. مكونات الواجهة (Widgets)
  //========================================================================

  Widget _buildChurchCard(BuildContext context, ChurchData church) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.fieldFillColor.withOpacity(0.9), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: church.color, width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(church.name, style: TextStyle(color: church.color, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Icon(church.icon, color: church.color),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Text(church.description, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildVirginMarySection() {
    return _buildBaseStorySection(
      title: '👑 سيرة السيدة العذراء مريم 👑',
      content: '''
١. الميلاد: ولدت في الناصرة من يواقيم وحنة بعد صلاة وإيمان.
٢. الهيكل: تكرست للخدمة في الهيكل وهي ابنة ثلاث سنوات.
٣. البشارة: بشرها الملاك جبرائيل بحملها بمخلص العالم.
٤. الصمت والعمق: كانت تحفظ كل الأمور متفكرة بها في قلبها.
٥. عند الصليب: صمدت تحت آلام ابنها وصارت أماً لكل المؤمنين.
٦. الصعود: تنيحت في ٢١ طوبة وأعلن الرب عن صعود جسدها في ١٦ مسرى.
      ''',
      details: [
        {'icon': Icons.face, 'label': 'اللقب:', 'value': 'ثيؤطوكوس (والدة الإله)'},
        {'icon': Icons.star, 'label': 'الرمز:', 'value': 'العليقة وتابوت العهد'},
      ],
    );
  }

  Widget _buildSaintNicholasSection() {
    return _buildBaseStorySection(
      title: '🌟 سيرة القديس نيقولاوس 🌟',
      content: 'أسقف ميرة صانع العجائب من القرن الرابع. اشتهر بعطائه السري وحبه للفقراء وهو الأصل التاريخي لشخصية بابا نويل. كان مدافعاً غيوراً عن الإيمان المستقيم في مجمع نيقية.',
      details: [
        {'icon': Icons.calendar_today, 'label': 'التذكار:', 'value': '٦ ديسمبر (كيهك)'},
        {'icon': Icons.anchor, 'label': 'شفيع:', 'value': 'البحارة والمسافرين'},
      ],
    );
  }

  Widget _buildBaseStorySection({required String title, required String content, required List<Map<String, dynamic>> details}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryColor1.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accentColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(title, style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold, fontSize: 17))),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
            const Divider(color: Colors.white24),
            ...details.map((d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(d['icon'], color: AppColors.accentColor, size: 16),
                  const SizedBox(width: 8),
                  Text('${d['label']} ${d['value']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartedSection({required String title, required List<_FatherInfo> fathers}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...fathers.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: const TextStyle(color: AppColors.accentColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(f.bio, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

class _FatherInfo {
  final String name;
  final String bio;
  _FatherInfo(this.name, this.bio);
}