import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GhanjatApp());
}

class GhanjatApp extends StatelessWidget {
  const GhanjatApp({Key? key}) : super(key: key);

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);
  static const Color light = Color(0xFFF8F4FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'غنجات للطباعة',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainPage(),
      ),
    );
  }
}

// ==============================
// قاعدة البيانات
// ==============================

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final String path = p.join(
      await getDatabasesPath(),
      'ghanjat_orders.db',
    );

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer TEXT NOT NULL,
            phone TEXT NOT NULL,
            service TEXT NOT NULL,
            quantity TEXT NOT NULL,
            details TEXT,
            total REAL NOT NULL,
            paid REAL NOT NULL,
            remaining REAL NOT NULL,
            status TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<int> addOrder(
    Map<String, dynamic> data,
  ) async {
    final Database db = await database;
    return db.insert('orders', data);
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final Database db = await database;

    return db.query(
      'orders',
      orderBy: 'id DESC',
    );
  }

  static Future<void> updateStatus(
    int id,
    String status,
  ) async {
    final Database db = await database;

    await db.update(
      'orders',
      <String, dynamic>{
        'status': status,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  static Future<void> deleteOrder(int id) async {
    final Database db = await database;

    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }
}

// ==============================
// بيانات الخدمات
// ==============================

class ServiceData {
  final String name;
  final IconData icon;
  final String unit;
  final double price;
  final bool businessCard;
  final bool pack100;

  const ServiceData({
    required this.name,
    required this.icon,
    required this.unit,
    required this.price,
    this.businessCard = false,
    this.pack100 = false,
  });
}

const List<ServiceData> services = <ServiceData>[
  ServiceData(
    name: 'بزنس كارد',
    icon: Icons.badge_outlined,
    unit: '100 كرت',
    price: 30000,
    businessCard: true,
    pack100: true,
  ),
  ServiceData(
    name: 'استيكرات منتجات',
    icon: Icons.label_outline,
    unit: 'متر',
    price: 40000,
  ),
  ServiceData(
    name: 'أكياس بلاستيك',
    icon: Icons.shopping_bag_outlined,
    unit: 'كيلو',
    price: 25000,
  ),
  ServiceData(
    name: 'أكياس قماش',
    icon: Icons.shopping_bag,
    unit: 'كيلو',
    price: 80000,
  ),
  ServiceData(
    name: 'لوحات إعلانية',
    icon: Icons.campaign_outlined,
    unit: 'متر',
    price: 35000,
  ),
  ServiceData(
    name: 'كروت الفال',
    icon: Icons.style_outlined,
    unit: '100 كرت',
    price: 70000,
    pack100: true,
  ),
];

// ==============================
// الصفحة الرئيسية للتطبيق
// ==============================

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  bool loading = true;

  List<Map<String, dynamic>> orders =
      <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final List<Map<String, dynamic>> data =
        await AppDatabase.getOrders();

    if (!mounted) return;

    setState(() {
      orders = data;
      loading = false;
    });
  }

  void openService(ServiceData service) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (BuildContext pageContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: OrderFormPage(
              service: service,
              onSaved: loadOrders,
            ),
          );
        },
      ),
    )
        .then((_) {
      loadOrders();
    });
  }

  void showServicePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'إضافة طلب جديد',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: GhanjatApp.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر الخدمة',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...services.map(
                    (ServiceData service) {
                      return ListTile(
                        leading: Icon(
                          service.icon,
                          color: GhanjatApp.turquoise,
                        ),
                        title: Text(
                          service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_left,
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          openService(service);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeContent(
        orders: orders,
        onServiceTap: openService,
      ),
      OrdersPage(
        orders: orders,
        onRefresh: loadOrders,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : pages[currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: GhanjatApp.purple,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 1) {
            loadOrders();
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'الطلبات',
          ),
        ],
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: GhanjatApp.purple,
              foregroundColor: Colors.white,
              onPressed: showServicePicker,
              icon: const Icon(Icons.add),
              label: const Text(
                'طلب جديد',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ==============================
// واجهة الرئيسية
// ==============================

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ValueChanged<ServiceData> onServiceTap;

  const HomeContent({
    Key? key,
    required this.orders,
    required this.onServiceTap,
  }) : super(key: key);

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  Future<void> openLink(
    BuildContext context,
    String url,
  ) async {
    final Uri uri = Uri.parse(url);

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح الرابط',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalRemaining = 0;

    for (final Map<String, dynamic> order in orders) {
      totalRemaining +=
          (order['remaining'] as num? ?? 0).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'غنجات للطباعة',
          style: TextStyle(fontSize: 23),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          105,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: GhanjatApp.turquoise,
                borderRadius: BorderRadius.circular(35),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.print,
                    color: Colors.white,
                    size: 64,
                  ),
                  SizedBox(height: 9),
                  Text(
                    'غنجات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                Expanded(
                  child: summaryCard(
                    Icons.receipt_long_outlined,
                    'الطلبات',
                    '${orders.length}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: summaryCard(
                    Icons.account_balance_wallet_outlined,
                    'المتبقي',
                    '${money(totalRemaining)} ج',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'خدماتنا',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            ...services.map(
              (ServiceData service) {
                return serviceCard(
                  service,
                );
              },
            ),

            const SizedBox(height: 18),

            // واتساب
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GhanjatApp.purple,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                children: <Widget>[
                  Text(
                    'تواصل معنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  ContactNumber(
                    number: '0115494130',
                  ),
                  SizedBox(height: 10),
                  ContactNumber(
                    number: '0994482612',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // تابعونا
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GhanjatApp.light,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'تابعونا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GhanjatApp.purple,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () {
                      openLink(
                        context,
                        'https://www.facebook.com/profile.php?id=61586164834127',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.facebook,
                      size: 28,
                    ),
                    label: const Text(
                      'Facebook',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: () {
                      openLink(
                        context,
                        'https://www.tiktok.com/@ahmd01154?_r=1&_t=ZS-99CqrUgTisC',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.music_note,
                      size: 27,
                    ),
                    label: const Text(
                      'TikTok',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget summaryCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 125,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GhanjatApp.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            color: GhanjatApp.turquoise,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(title),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GhanjatApp.purple,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget serviceCard(ServiceData service) {
    String subtitle;

    if (service.businessCard) {
      subtitle =
          '100 كرت\nاتجاه واحد: 30,000 ج\nاتجاهين: 35,000 ج';
    } else {
      subtitle =
          '${money(service.price)} جنيه / ${service.unit}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Card(
        elevation: 1,
        color: GhanjatApp.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF0FAF8),
            child: Icon(
              service.icon,
              color: GhanjatApp.turquoise,
            ),
          ),
          title: Text(
            service.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              height: 1.45,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_left,
          ),
          onTap: () {
            onServiceTap(service);
          },
        ),
      ),
    );
  }
}

class ContactNumber extends StatelessWidget {
  final String number;

  const ContactNumber({
    Key? key,
    required this.number,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.greenAccent,
            size: 25,
          ),
          const SizedBox(width: 10),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// إنشاء الطلب
// ==============================

class OrderFormPage extends StatefulWidget {
  final ServiceData service;
  final Future<void> Function() onSaved;

  const OrderFormPage({
    Key? key,
    required this.service,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<OrderFormPage> createState() =>
      _OrderFormPageState();
}

class _OrderFormPageState
    extends State<OrderFormPage> {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController customerController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController(text: '1');

  final TextEditingController detailsController =
      TextEditingController();

  final TextEditingController paidController =
      TextEditingController(text: '0');

  final TextEditingController notesController =
      TextEditingController();

  String businessSide = 'اتجاه واحد';

  double get quantity =>
      double.tryParse(quantityController.text) ?? 0;

  double get paid =>
      double.tryParse(paidController.text) ?? 0;

  double get unitPrice {
    if (widget.service.businessCard) {
      return businessSide == 'اتجاهين'
          ? 35000
          : 30000;
    }

    return widget.service.price;
  }

  double get total => quantity * unitPrice;

  double get remaining {
    final double amount = total - paid;
    return amount < 0 ? 0 : amount;
  }

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  String get quantityText {
    if (widget.service.pack100) {
      return '${(quantity * 100).round()} كرت';
    }

    return '$quantity ${widget.service.unit}';
  }

  Future<int?> saveOrder() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return null;
    }

    final int id = await AppDatabase.addOrder(
      <String, dynamic>{
        'customer': customerController.text.trim(),
        'phone': phoneController.text.trim(),
        'service': widget.service.name,
        'quantity': quantityText,
        'details': detailsController.text.trim(),
        'total': total,
        'paid': paid,
        'remaining': remaining,
        'status': 'جديد',
        'notes': notesController.text.trim(),
        'created_at':
            DateTime.now().toIso8601String(),
      },
    );

    await widget.onSaved();

    return id;
  }

  Future<void> sendOrder() async {
    final int? orderId = await saveOrder();

    if (orderId == null || !mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                  size: 42,
                ),
                const SizedBox(height: 12),
                const Text(
                  'إرسال الطلب إلى',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                whatsappButton(
                  sheetContext,
                  orderId,
                  '0115494130',
                ),
                const SizedBox(height: 10),
                whatsappButton(
                  sheetContext,
                  orderId,
                  '0994482612',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget whatsappButton(
    BuildContext sheetContext,
    int orderId,
    String number,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();
          openWhatsApp(orderId, number);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(14),
        ),
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
        ),
        label: Text(
          number,
          style: const TextStyle(fontSize: 19),
        ),
      ),
    );
  }

  Future<void> openWhatsApp(
    int orderId,
    String localNumber,
  ) async {
    final String international =
        localNumber == '0115494130'
            ? '249115494130'
            : '249994482612';

    final String message =
        'طلب جديد - غنجات للطباعة\n\n'
        'رقم الطلب: #$orderId\n'
        'الخدمة: ${widget.service.name}\n'
        '${widget.service.businessCard ? 'نوع الطباعة: $businessSide\n' : ''}'
        'اسم العميل: ${customerController.text.trim()}\n'
        'الهاتف: ${phoneController.text.trim()}\n'
        'الكمية: $quantityText\n'
        'التفاصيل: ${detailsController.text.trim()}\n'
        'الإجمالي: ${money(total)} جنيه\n'
        'المدفوع: ${money(paid)} جنيه\n'
        'المتبقي: ${money(remaining)} جنيه\n'
        'الملاحظات: ${notesController.text.trim()}';

    final Uri uri = Uri.parse(
      'https://wa.me/$international?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(widget.service.name),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.service.businessCard)
                Column(
                  children: <Widget>[
                    RadioListTile<String>(
                      value: 'اتجاه واحد',
                      groupValue: businessSide,
                      title: const Text(
                        'اتجاه واحد - 30,000 جنيه / 100 كرت',
                      ),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            businessSide = value;
                          });
                        }
                      },
                    ),
                    RadioListTile<String>(
                      value: 'اتجاهين',
                      groupValue: businessSide,
                      title: const Text(
                        'اتجاهين - 35,000 جنيه / 100 كرت',
                      ),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            businessSide = value;
                          });
                        }
                      },
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GhanjatApp.light,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'السعر: ${money(unitPrice)} جنيه / ${widget.service.unit}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GhanjatApp.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              appField(
                customerController,
                'اسم العميل',
                Icons.person_outline,
                requiredField: true,
              ),

              const SizedBox(height: 12),

              appField(
                phoneController,
                'رقم الهاتف',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                requiredField: true,
              ),

              const SizedBox(height: 12),

              appField(
                quantityController,
                widget.service.pack100
                    ? 'عدد الحزم - كل حزمة 100 كرت'
                    : 'الكمية بـ ${widget.service.unit}',
                Icons.numbers,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                requiredField: true,
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              appField(
                detailsController,
                'المقاس / التفاصيل',
                Icons.straighten,
              ),

              const SizedBox(height: 12),

              appField(
                paidController,
                'المدفوع',
                Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: GhanjatApp.light,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: <Widget>[
                    amountRow(
                      'الإجمالي',
                      '${money(total)} جنيه',
                    ),
                    const Divider(),
                    amountRow(
                      'المدفوع',
                      '${money(paid)} جنيه',
                    ),
                    const Divider(),
                    amountRow(
                      'المتبقي',
                      '${money(remaining)} جنيه',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton.icon(
                onPressed: sendOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                ),
                label: const Text(
                  'حفظ وإرسال عبر واتساب',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget appField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool requiredField = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: requiredField
          ? (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'أدخل $label';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget amountRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(title),
        Text(
          value,
          style: const TextStyle(
            color: GhanjatApp.purple,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

// ==============================
// صفحة الطلبات
// ==============================

class OrdersPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Future<void> Function() onRefresh;

  const OrdersPage({
    Key? key,
    required this.orders,
    required this.onRefresh,
  }) : super(key: key);

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  Future<void> changeStatus(
    BuildContext pageContext,
    Map<String, dynamic> order,
  ) async {
    final String? status =
        await showModalBottomSheet<String>(
      context: pageContext,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              statusItem(sheetContext, 'جديد'),
              statusItem(sheetContext, 'تحت التنفيذ'),
              statusItem(sheetContext, 'جاهز'),
              statusItem(sheetContext, 'تم التسليم'),
            ],
          ),
        );
      },
    );

    if (status != null) {
      await AppDatabase.updateStatus(
        order['id'] as int,
        status,
      );

      await onRefresh();
    }
  }

  Widget statusItem(
    BuildContext context,
    String status,
  ) {
    return ListTile(
      title: Text(status),
      onTap: () {
        Navigator.of(context).pop(status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'الطلبات (${orders.length})',
        ),
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'ما في طلبات محفوظة لسه',
                style: TextStyle(fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (
                  BuildContext pageContext,
                  int index,
                ) {
                  final Map<String, dynamic> order =
                      orders[index];

                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            GhanjatApp.turquoise,
                        foregroundColor: Colors.white,
                        child: Text('${order['id']}'),
                      ),
                      title: Text(
                        order['customer'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${order['service']} • ${order['status']}',
                      ),
                      children: <Widget>[
                        ListTile(
                          leading:
                              const Icon(Icons.phone_outlined),
                          title: Text(
                            order['phone'].toString(),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.numbers),
                          title: Text(
                            'الكمية: ${order['quantity']}',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.payments_outlined,
                          ),
                          title: Text(
                            'الإجمالي: ${money((order['total'] as num).toDouble())} جنيه',
                          ),
                          subtitle: Text(
                            'المدفوع: ${money((order['paid'] as num).toDouble())} • المتبقي: ${money((order['remaining'] as num).toDouble())}',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                changeStatus(
                                  pageContext,
                                  order,
                                );
                              },
                              icon: const Icon(Icons.sync),
                              label: const Text(
                                'تغيير حالة الطلب',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
