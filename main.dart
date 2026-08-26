import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const GhanjatApp());
}

class GhanjatApp extends StatelessWidget {
  const GhanjatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'غنجات للطباعة',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);

  void openService(
    BuildContext context,
    String title,
    IconData icon,
    String description,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicePage(
          title: title,
          icon: icon,
          description: description,
        ),
      ),
    );
  }

  Widget serviceButton(
    BuildContext context,
    String title,
    IconData icon,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton(
          onPressed: () {
            openService(context, title, icon, description);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2F8F7),
            foregroundColor: Colors.black87,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 30,
                color: turquoise,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget whatsappNumber(String number) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.greenAccent,
            size: 27,
          ),
          const SizedBox(width: 10),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'غنجات للطباعة',
            style: TextStyle(fontSize: 24),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 35,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: turquoise,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: const Column(
                    children: <Widget>[
                      Icon(
                        Icons.print,
                        color: Colors.white,
                        size: 70,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'غنجات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'لخدمات الطباعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'خدماتنا',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                serviceButton(
                  context,
                  'بزنس كارد',
                  Icons.badge_outlined,
                  'تصميم وطباعة بزنس كارد احترافي بمقاسات وخيارات مختلفة.',
                ),

                serviceButton(
                  context,
                  'استيكرات منتجات',
                  Icons.label_outline,
                  'تصميم وطباعة استيكرات للمنتجات والعبوات والمشاريع التجارية.',
                ),

                serviceButton(
                  context,
                  'أكياس بلاستيك وقماش',
                  Icons.shopping_bag_outlined,
                  'طباعة أكياس للمحلات والمشاريع مع إمكانية إضافة الاسم والشعار.',
                ),

                serviceButton(
                  context,
                  'لوحات إعلانية',
                  Icons.campaign_outlined,
                  'تصميم وتنفيذ اللوحات الإعلانية للمحلات والشركات والمناسبات.',
                ),

                serviceButton(
                  context,
                  'حروف بارزة',
                  Icons.text_fields,
                  'تنفيذ الحروف البارزة والواجهات بأشكال ومقاسات مختلفة.',
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 25,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'تواصل معنا',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      whatsappNumber('0115494130'),

                      const SizedBox(height: 12),

                      whatsappNumber('0994482612'),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServicePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const ServicePage({
    Key? key,
    required this.title,
    required this.icon,
    required this.description,
  }) : super(key: key);

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);

  Future<void> openWhatsApp(
    BuildContext context,
    String localNumber,
  ) async {
    String internationalNumber;

    if (localNumber == '0115494130') {
      internationalNumber = '249115494130';
    } else {
      internationalNumber = '249994482612';
    }

    final String message =
        'السلام عليكم، أريد طلب خدمة $title من غنجات للطباعة.';

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$internationalNumber?text=${Uri.encodeComponent(message)}',
    );

    final bool opened = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح واتساب',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  void chooseWhatsAppNumber(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                  size: 45,
                ),
                const SizedBox(height: 12),
                const Text(
                  'اختر رقم الواتساب',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                whatsappButton(
                  sheetContext,
                  context,
                  '0115494130',
                ),

                const SizedBox(height: 12),

                whatsappButton(
                  sheetContext,
                  context,
                  '0994482612',
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget whatsappButton(
    BuildContext sheetContext,
    BuildContext pageContext,
    String number,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();
          openWhatsApp(pageContext, number);
        },
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 25,
        ),
        label: Text(
          number,
          style: const TextStyle(
            fontSize: 21,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(title),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 15),

                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F7),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Icon(
                      icon,
                      size: 65,
                      color: turquoise,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    description,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.7,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.photo_library_outlined,
                        size: 55,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'نماذج الأعمال ستظهر هنا',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 65,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      chooseWhatsAppNumber(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 28,
                    ),
                    label: const Text(
                      'اطلب عبر واتساب',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
