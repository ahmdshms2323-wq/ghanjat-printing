import 'package:flutter/material.dart';

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
        fontFamily: 'sans',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);
  static const Color lightBackground = Color(0xFFF8F4FA);

  void openService(
    BuildContext context,
    String title,
    String price,
    IconData icon,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => ServicePage(
          title: title,
          price: price,
          icon: icon,
        ),
      ),
    );
  }

  Widget serviceCard(
    BuildContext context,
    String title,
    String price,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: lightBackground,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            openService(context, title, price, icon);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: turquoise,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        price,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_back_ios_new,
                  size: 19,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showNewOrder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'إضافة طلب جديد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اختر الخدمة المطلوبة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                orderOption(
                  sheetContext,
                  context,
                  'بزنس كارد',
                  'اتجاه واحد: 30,000 ج\nاتجاهين: 35,000 ج',
                  Icons.badge_outlined,
                ),
                orderOption(
                  sheetContext,
                  context,
                  'استيكرات منتجات',
                  '40,000 ج / متر',
                  Icons.label_outline,
                ),
                orderOption(
                  sheetContext,
                  context,
                  'أكياس بلاستيك',
                  '25,000 ج / كيلو',
                  Icons.shopping_bag_outlined,
                ),
                orderOption(
                  sheetContext,
                  context,
                  'أكياس قماش',
                  '80,000 ج / كيلو',
                  Icons.shopping_bag,
                ),
                orderOption(
                  sheetContext,
                  context,
                  'لوحات إعلانية',
                  '35,000 ج / متر',
                  Icons.campaign_outlined,
                ),
                orderOption(
                  sheetContext,
                  context,
                  'كروت الفال',
                  '100 كرت: 70,000 ج',
                  Icons.style_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget orderOption(
    BuildContext sheetContext,
    BuildContext parentContext,
    String title,
    String price,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: turquoise,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(price),
      trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
      onTap: () {
        Navigator.pop(sheetContext);
        openService(parentContext, title, price, icon);
      },
    );
  }

  Widget statisticBox(
    IconData icon,
    String title,
    String value,
  ) {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: lightBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: turquoise,
              size: 29,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: purple,
              ),
            ),
          ],
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
          elevation: 0,
          title: const Text(
            'غنجات للطباعة',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
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
                        size: 65,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'غنجات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'لخدمات الطباعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    statisticBox(
                      Icons.receipt_long_outlined,
                      'الطلبات',
                      '0',
                    ),
                    const SizedBox(width: 12),
                    statisticBox(
                      Icons.account_balance_wallet_outlined,
                      'المتبقي',
                      '0 ج',
                    ),
                  ],
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
                serviceCard(
                  context,
                  'بزنس كارد',
                  '100 كرت\nاتجاه واحد: 30,000 ج  •  اتجاهين: 35,000 ج',
                  Icons.badge_outlined,
                ),
                serviceCard(
                  context,
                  'استيكرات منتجات',
                  '40,000 ج / متر',
                  Icons.label_outline,
                ),
                serviceCard(
                  context,
                  'أكياس بلاستيك',
                  '25,000 ج / كيلو',
                  Icons.shopping_bag_outlined,
                ),
                serviceCard(
                  context,
                  'أكياس قماش',
                  '80,000 ج / كيلو',
                  Icons.shopping_bag,
                ),
                serviceCard(
                  context,
                  'لوحات إعلانية',
                  '35,000 ج / متر',
                  Icons.campaign_outlined,
                ),
                serviceCard(
                  context,
                  'كروت الفال',
                  '100 كرت: 70,000 ج',
                  Icons.style_outlined,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          onPressed: () {
            showNewOrder(context);
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'طلب جديد',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class ServicePage extends StatelessWidget {
  final String title;
  final String price;
  final IconData icon;

  const ServicePage({
    Key? key,
    required this.title,
    required this.price,
    required this.icon,
  }) : super(key: key);

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);

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
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8F7),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Icon(
                    icon,
                    size: 70,
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
                  color: const Color(0xFFF8F4FA),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'السعر',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.6,
                        fontWeight: FontWeight.bold,
                        color: purple,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'سيتم ربط الطلب بالواتساب في الخطوة التالية',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text(
                    'اطلب عبر واتساب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
