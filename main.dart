import 'package:flutter/material.dart';

void main() {
  runApp(const GhanjatApp());
}

class GhanjatApp extends StatelessWidget {
  const GhanjatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'غنجات للطباعة',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF432B70),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);

  void showService(BuildContext context, String service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            service,
            textAlign: TextAlign.right,
          ),
          content: const Text(
            'لطلب هذه الخدمة تواصل معنا عبر واتساب.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  Widget serviceButton(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton(
          onPressed: () {
            showService(context, title);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 30,
                color: turquoise,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
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
        children: [
          const Icon(
            Icons.chat,
            color: Colors.green,
            size: 28,
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
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    children: [
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
                ),

                serviceButton(
                  context,
                  'استيكرات منتجات',
                  Icons.sell_outlined,
                ),

                serviceButton(
                  context,
                  'أكياس بلاستيك وقماش',
                  Icons.shopping_bag_outlined,
                ),

                serviceButton(
                  context,
                  'لوحات إعلانية',
                  Icons.campaign_outlined,
                ),

                serviceButton(
                  context,
                  'حروف بارزة',
                  Icons.text_fields,
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
                    children: [
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
