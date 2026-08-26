
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GhanjatApp());
}

class GhanjatApp extends StatelessWidget {
  const GhanjatApp({Key? key}) : super(key: key);

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);

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
        child: HomePage(),
      ),
    );
  }
}

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String dbPath = join(
      await getDatabasesPath(),
      'ghanjat_orders.db',
    );

    _database = await openDatabase(
      dbPath,
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
            notes TEXT,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  static Future<int> addOrder(
    Map<String, dynamic> order,
  ) async {
    final Database db = await database;

    return db.insert(
      'orders',
      order,
    );
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

  static Future<void> deleteOrder(
    int id,
  ) async {
    final Database db = await database;

    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }
}

class ServiceData {
  final String name;
  final IconData icon;
  final String description;
  final String unit;
  final double price;
  final bool isBusinessCard;
  final bool isCardPack;

  const ServiceData({
    required this.name,
    required this.icon,
    required this.description,
    required this.unit,
    required this.price,
    this.isBusinessCard = false,
    this.isCardPack = false,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;

  List<Map<String, dynamic>> orders =
      <Map<String, dynamic>>[];

  bool loading = true;

  static const List<ServiceData> services =
      <ServiceData>[
    ServiceData(
      name: 'بزنس كارد',
      icon: Icons.badge_outlined,
      description:
          'تصميم وطباعة بزنس كارد احترافي.',
      unit: 'حزمة 100 كرت',
      price: 30000,
      isBusinessCard: true,
      isCardPack: true,
    ),
    ServiceData(
      name: 'استيكرات منتجات',
      icon: Icons.label_outline,
      description:
          'تصميم وطباعة استيكرات المنتجات والعبوات.',
      unit: 'متر',
      price: 40000,
    ),
    ServiceData(
      name: 'أكياس بلاستيك',
      icon: Icons.shopping_bag_outlined,
      description:
          'طباعة أكياس بلاستيك للمحلات والمشاريع.',
      unit: 'كيلو',
      price: 25000,
    ),
    ServiceData(
      name: 'أكياس قماش',
      icon: Icons.shopping_bag,
      description:
          'طباعة أكياس قماش مع الاسم والشعار.',
      unit: 'كيلو',
      price: 80000,
    ),
    ServiceData(
      name: 'لوحات إعلانية',
      icon: Icons.campaign_outlined,
      description:
          'تصميم وتنفيذ اللوحات الإعلانية.',
      unit: 'متر',
      price: 35000,
    ),
    ServiceData(
      name: 'كروت الفال',
      icon: Icons.card_giftcard_outlined,
      description:
          'طباعة كروت الفال للمناسبات.',
      unit: 'حزمة 100 كرت',
      price: 70000,
      isCardPack: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final List<Map<String, dynamic>> data =
        await AppDatabase.getOrders();

    if (!mounted) {
      return;
    }

    setState(() {
      orders = data;
      loading = false;
    });
  }

  void openService(
    ServiceData service,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: ServicePage(
              service: service,
              onOrderSaved: loadOrders,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      DashboardPage(
        services: services,
        orders: orders,
        onServicePressed: openService,
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
            : pages[selectedPage],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedPage,
        selectedItemColor: GhanjatApp.purple,
        onTap: (int value) {
          setState(() {
            selectedPage = value;
          });

          if (value == 1) {
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
    );
  }
}

class DashboardPage extends StatelessWidget {
  final List<ServiceData> services;
  final List<Map<String, dynamic>> orders;
  final ValueChanged<ServiceData> onServicePressed;

  const DashboardPage({
    Key? key,
    required this.services,
    required this.orders,
    required this.onServicePressed,
  }) : super(key: key);

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    double remaining = 0;

    for (final Map<String, dynamic> order
        in orders) {
      remaining +=
          (order['remaining'] as num? ?? 0)
              .toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('غنجات للطباعة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: GhanjatApp.turquoise,
                borderRadius:
                    BorderRadius.circular(32),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.print,
                    size: 65,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'غنجات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight:
                          FontWeight.bold,
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
                    'الطلبات',
                    '${orders.length}',
                    Icons.receipt_long_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: summaryCard(
                    'المتبقي',
                    '${money(remaining)} ج',
                    Icons
                        .account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'خدماتنا',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...services.map(
              (ServiceData service) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFFF2F8F7),
                      child: Icon(
                        service.icon,
                        color:
                            GhanjatApp.turquoise,
                      ),
                    ),
                    title: Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_left,
                    ),
                    onTap: () {
                      onServicePressed(service);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GhanjatApp.purple,
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: const Column(
                children: <Widget>[
                  Text(
                    'تواصل معنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '💬 0115494130',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '💬 0994482612',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: GhanjatApp.turquoise,
              size: 28,
            ),
            const SizedBox(height: 7),
            Text(title),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicePage extends StatefulWidget {
  final ServiceData service;
  final Future<void> Function() onOrderSaved;

  const ServicePage({
    Key? key,
    required this.service,
    required this.onOrderSaved,
  }) : super(key: key);

  @override
  State<ServicePage> createState() {
    return _ServicePageState();
  }
}

class _ServicePageState
    extends State<ServicePage> {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController customer =
      TextEditingController();

  final TextEditingController phone =
      TextEditingController();

  final TextEditingController quantity =
      TextEditingController(text: '1');

  final TextEditingController details =
      TextEditingController();

  final TextEditingController paid =
      TextEditingController(text: '0');

  final TextEditingController notes =
      TextEditingController();

  String businessSide = 'اتجاه واحد';

  double get quantityValue {
    return double.tryParse(quantity.text) ?? 0;
  }

  double get paidValue {
    return double.tryParse(paid.text) ?? 0;
  }

  double get unitPrice {
    if (widget.service.isBusinessCard) {
      if (businessSide == 'اتجاهين') {
        return 35000;
      }

      return 30000;
    }

    return widget.service.price;
  }

  double get total {
    return quantityValue * unitPrice;
  }

  double get remaining {
    if (paidValue >= total) {
      return 0;
    }

    return total - paidValue;
  }

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  String quantityDescription() {
    if (widget.service.isCardPack) {
      final int cards =
          (quantityValue * 100).round();

      return '$cards كرت';
    }

    return '${quantityValue.toString()} ${widget.service.unit}';
  }

  Future<int?> saveOrder() async {
    if (!(formKey.currentState?.validate() ??
        false)) {
      return null;
    }

    final int id =
        await AppDatabase.addOrder(
      <String, dynamic>{
        'customer': customer.text.trim(),
        'phone': phone.text.trim(),
        'service': widget.service.name,
        'quantity': quantityDescription(),
        'details': widget.service.isBusinessCard
            ? '$businessSide - ${details.text.trim()}'
            : details.text.trim(),
        'total': total,
        'paid': paidValue,
        'remaining': remaining,
        'notes': notes.text.trim(),
        'status': 'جديد',
        'created_at':
            DateTime.now().toIso8601String(),
      },
    );

    await widget.onOrderSaved();

    return id;
  }

  Future<void> saveOnly() async {
    final int? id = await saveOrder();

    if (id == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ الطلب رقم #$id',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> saveAndWhatsApp() async {
    final int? id = await saveOrder();

    if (id == null) {
      return;
    }

    chooseWhatsApp(id);
  }

  void chooseWhatsApp(int orderId) {
    showModalBottomSheet(
      context: context,
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
                const SizedBox(height: 15),
                Text(
                  'إرسال الطلب #$orderId إلى',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
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
          Navigator.pop(sheetContext);

          openWhatsApp(
            orderId,
            number,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.all(14),
        ),
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
        ),
        label: Text(
          number,
          style:
              const TextStyle(fontSize: 19),
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
        'العميل: ${customer.text.trim()}\n'
        'الهاتف: ${phone.text.trim()}\n'
        'الكمية: ${quantityDescription()}\n'
        '${widget.service.isBusinessCard ? 'نوع الطباعة: $businessSide\n' : ''}'
        'التفاصيل: ${details.text.trim()}\n'
        'الإجمالي: ${money(total)} جنيه\n'
        'المدفوع: ${money(paidValue)} جنيه\n'
        'المتبقي: ${money(remaining)} جنيه\n'
        'الحالة: جديد\n'
        'الملاحظات: ${notes.text.trim()}';

    final Uri uri = Uri.parse(
      'https://wa.me/$international?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool requiredField = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: onChanged,
      validator: requiredField
          ? (String? value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'أدخل $label';
              }

              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: GhanjatApp.turquoise,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        title: Text(widget.service.name),
        centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Icon(
                widget.service.icon,
                size: 70,
                color: GhanjatApp.turquoise,
              ),

              const SizedBox(height: 20),

              if (widget.service.isBusinessCard)
                Column(
                  children: <Widget>[
                    RadioListTile<String>(
                      title: const Text(
                        'اتجاه واحد - 30,000 / 100',
                      ),
                      value: 'اتجاه واحد',
                      groupValue: businessSide,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            businessSide = value;
                          });
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'اتجاهين - 35,000 / 100',
                      ),
                      value: 'اتجاهين',
                      groupValue: businessSide,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            businessSide = value;
                          });
                        }
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 10
