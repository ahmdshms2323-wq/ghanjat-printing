import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GhanjatApp());
}

class GhanjatApp extends StatelessWidget {
  const GhanjatApp({super.key});

  static const Color purple = Color(0xFF432B70);
  static const Color turquoise = Color(0xFF74B5AE);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'غنجات للطباعة',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainPage(),
      ),
    );
  }
}

String money(num value) {
  final String text = value.round().toString();

  return text.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

String quantityNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toString();
}

// ==========================================
// قاعدة البيانات
// ==========================================

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
      version: 2,
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
            payment_method TEXT,
            transfer_last6 TEXT,
            receipt_image TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (
        Database db,
        int oldVersion,
        int newVersion,
      ) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE orders ADD COLUMN payment_method TEXT',
          );

          await db.execute(
            'ALTER TABLE orders ADD COLUMN transfer_last6 TEXT',
          );

          await db.execute(
            'ALTER TABLE orders ADD COLUMN receipt_image TEXT',
          );
        }
      },
    );

    return _db!;
  }

  static Future<int> addOrder(
    Map<String, dynamic> data,
  ) async {
    final Database db = await database;

    return db.insert(
      'orders',
      data,
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
}

// ==========================================
// الخدمات والأسعار
// ==========================================

class ServiceData {
  final String name;
  final IconData icon;
  final String unit;
  final double price;

  final bool per100;
  final bool businessCard;
  final bool bagsCategory;

  const ServiceData({
    required this.name,
    required this.icon,
    required this.unit,
    required this.price,
    this.per100 = false,
    this.businessCard = false,
    this.bagsCategory = false,
  });
}

const ServiceData plasticBagService = ServiceData(
  name: 'أكياس بلاستيك',
  icon: Icons.shopping_bag_outlined,
  unit: 'كيلو',
  price: 25000,
);

const ServiceData clothBagService = ServiceData(
  name: 'أكياس قماش',
  icon: Icons.shopping_bag,
  unit: 'كيلو',
  price: 80000,
);

const List<ServiceData> services = <ServiceData>[
  ServiceData(
    name: 'بزنس كارد',
    icon: Icons.badge_outlined,
    unit: 'كرت',
    price: 30000,
    per100: true,
    businessCard: true,
  ),
  ServiceData(
    name: 'استيكرات منتجات',
    icon: Icons.label_outline,
    unit: 'متر',
    price: 40000,
  ),
  ServiceData(
    name: 'قسم الأكياس',
    icon: Icons.shopping_bag_outlined,
    unit: '',
    price: 0,
    bagsCategory: true,
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
    unit: 'كرت',
    price: 70000,
    per100: true,
  ),
];

// ==========================================
// الصفحة الأساسية
// ==========================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  bool loading = true;
  bool drawerOpen = false;

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

  void goHome() {
    setState(() {
      currentIndex = 0;
    });
  }

  void goOrders() {
    setState(() {
      currentIndex = 1;
    });

    loadOrders();
  }

  void openOrderForm(ServiceData service) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) {
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

  void openService(ServiceData service) {
    if (service.bagsCategory) {
      showBagsPicker();
      return;
    }

    openOrderForm(service);
  }

  void showBagsPicker() {
    showModalBottomSheet<void>(
      context: context,
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
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'قسم الأكياس',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GhanjatApp.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر نوع الأكياس',
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: GhanjatApp.turquoise,
                    ),
                    title: const Text(
                      'أكياس بلاستيك',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      '25,000 جنيه / كيلو',
                    ),
                    trailing: const Icon(
                      Icons.chevron_left,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      openOrderForm(
                        plasticBagService,
                      );
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(
                      Icons.shopping_bag,
                      color: GhanjatApp.turquoise,
                    ),
                    title: const Text(
                      'أكياس قماش',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      '80,000 جنيه / كيلو',
                    ),
                    trailing: const Icon(
                      Icons.chevron_left,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      openOrderForm(
                        clothBagService,
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(22),
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
                            Navigator.pop(
                              sheetContext,
                            );

                            openService(service);
                          },
                        );
                      },
                    ),
                  ],
                ),
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
        onOrdersTap: goOrders,
        onDrawerChanged: (bool open) {
          setState(() {
            drawerOpen = open;
          });
        },
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
          if (index == 0) {
            goHome();
          } else {
            goOrders();
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(
              Icons.home,
            ),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            activeIcon: Icon(
              Icons.receipt_long,
            ),
            label: 'الطلبات',
          ),
        ],
      ),

      floatingActionButton:
          currentIndex == 0 && !drawerOpen
              ? FloatingActionButton.extended(
                  backgroundColor: GhanjatApp.purple,
                  foregroundColor: Colors.white,
                  onPressed: showServicePicker,
                  icon: const Icon(
                    Icons.add,
                  ),
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

// ==========================================
// الرئيسية والقائمة الجانبية
// ==========================================

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  final ValueChanged<ServiceData> onServiceTap;

  final VoidCallback onOrdersTap;

  final ValueChanged<bool> onDrawerChanged;

  const HomeContent({
    super.key,
    required this.orders,
    required this.onServiceTap,
    required this.onOrdersTap,
    required this.onDrawerChanged,
  });

  Future<void> openWhatsApp(String phone) async {
    final Uri uri = Uri.parse(
      'https://wa.me/249$phone',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    double remainingTotal = 0;

    for (final Map<String, dynamic> order in orders) {
      remainingTotal +=
          (order['remaining'] as num? ?? 0).toDouble();
    }

    return Scaffold(
      onDrawerChanged: onDrawerChanged,

      drawer: Drawer(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  color: GhanjatApp.purple,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 18,
                  ),
                  child: const Column(
                    children: <Widget>[
                      Icon(
                        Icons.print,
                        color: Colors.white,
                        size: 58,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'غنجات للطباعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  leading: const Icon(
                    Icons.home_outlined,
                  ),
                  title: const Text(
                    'الرئيسية',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  title: Text(
                    'الطلبات (${orders.length})',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Future<void>.delayed(
                      const Duration(
                        milliseconds: 150,
                      ),
                      () async {
                        onOrdersTap();
                      },
                    );
                  },
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Text(
                    'الخدمات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: GhanjatApp.purple,
                    ),
                  ),
                ),

                ...services.map(
                  (ServiceData service) {
                    return ListTile(
                      leading: Icon(
                        service.icon,
                        color: GhanjatApp.turquoise,
                      ),
                      title: Text(
                        service.name,
                      ),
                      onTap: () {
                        Navigator.pop(context);

                        Future<void>.delayed(
                          const Duration(
                            milliseconds: 150,
                          ),
                          () async {
                            onServiceTap(service);
                          },
                        );
                      },
                    );
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                  ),
                  title: const Text(
                    '0115494130',
                  ),
                  onTap: () {
                    openWhatsApp(
                      '115494130',
                    );
                  },
                ),

                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                  ),
                  title: const Text(
                    '0994482612',
                  ),
                  onTap: () {
                    openWhatsApp(
                      '994482612',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'غنجات للطباعة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GhanjatApp.turquoise,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.print,
                    size: 58,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'غنجات',
                    style: TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'لخدمات الطباعة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: <Widget>[
                Expanded(
                  child: _summaryCard(
                    Icons.receipt_long_outlined,
                    'الطلبات',
                    '${orders.length}',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _summaryCard(
                    Icons.account_balance_wallet_outlined,
                    'المتبقي',
                    '${money(remainingTotal)} ج',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'خدماتنا',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: GhanjatApp.purple,
              ),
            ),

            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final ServiceData service =
                    services[index];

                String priceText = '';

                if (service.bagsCategory) {
                  priceText = 'بلاستيك / قماش';
                } else if (service.per100) {
                  priceText =
                      '${money(service.price)} / 100 كرت';
                } else {
                  priceText =
                      '${money(service.price)} / ${service.unit}';
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    onServiceTap(service);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(
                          0xFFE7E1EB,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          service.icon,
                          size: 38,
                          color: GhanjatApp.turquoise,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          priceText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: GhanjatApp.purple,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// نموذج الطلب
// ==========================================

class OrderFormPage extends StatefulWidget {
  final ServiceData service;

  final Future<void> Function() onSaved;

  const OrderFormPage({
    super.key,
    required this.service,
    required this.onSaved,
  });

  @override
  State<OrderFormPage> createState() {
    return _OrderFormPageState();
  }
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
      TextEditingController();

  final TextEditingController detailsController =
      TextEditingController();

  final TextEditingController paidController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  final TextEditingController transferLast6Controller =
      TextEditingController();

  final ImagePicker imagePicker =
      ImagePicker();

  XFile? receiptImage;

  String? paymentMethod;

  bool twoSides = false;

  static const String bankakAccount =
      '2769498';

  static const String fawryAccount =
      '51799301';

  static const String accountName =
      'احمد شمس الدين خالد احمد';

  double get quantity {
    return double.tryParse(
          quantityController.text.trim(),
        ) ??
        0;
  }

  double get paid {
    return double.tryParse(
          paidController.text.trim(),
        ) ??
        0;
  }

  double get unitPrice {
    if (widget.service.businessCard &&
        twoSides) {
      return 35000;
    }

    return widget.service.price;
  }

  // التصحيح المهم:
  // الكروت تدخل بعددها الحقيقي.
  // 100 كرت فال = 70,000
  // 200 كرت فال = 140,000
  // وليس 100 × 70,000.
  double get total {
    if (widget.service.per100) {
      return (quantity / 100) * unitPrice;
    }

    return quantity * unitPrice;
  }

  double get remaining {
    final double value =
        total - paid;

    return value < 0 ? 0 : value;
  }

  String get quantityText {
    if (widget.service.per100) {
      return '${quantity.round()} كرت';
    }

    return '${quantityNumber(quantity)} ${widget.service.unit}';
  }

  Map<String, String>? get selectedAccount {
    if (paymentMethod == 'بنكك') {
      return <String, String>{
        'account': bankakAccount,
        'name': accountName,
      };
    }

    if (paymentMethod == 'فوري') {
      return <String, String>{
        'account': fawryAccount,
        'name': accountName,
      };
    }

    return null;
  }  @override
  void dispose() {
    customerController.dispose();
    phoneController.dispose();
    quantityController.dispose();
    detailsController.dispose();
    paidController.dispose();
    notesController.dispose();
    transferLast6Controller.dispose();
    super.dispose();
  }

  Future<void> pickReceipt() async {
    final XFile? image =
        await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      receiptImage = image;
    });
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  bool validateQuantity() {
    if (quantity <= 0) {
      showError('اكتب كمية صحيحة');
      return false;
    }

    if (widget.service.per100 &&
        quantity % 100 != 0) {
      showError(
        'عدد الكروت لازم يكون 100 أو 200 أو 300 وهكذا',
      );
      return false;
    }

    return true;
  }

  bool validatePayment() {
    if (paymentMethod == null) {
      showError(
        'اختر طريقة الدفع: بنكك أو فوري',
      );
      return false;
    }

    final String last6 =
        transferLast6Controller.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(last6)) {
      showError(
        'اكتب آخر 6 أرقام من التحويل',
      );
      return false;
    }

    if (receiptImage == null) {
      showError(
        'اختر صورة إشعار التحويل',
      );
      return false;
    }

    return true;
  }

  Future<int?> saveOrder() async {
    if (!(formKey.currentState?.validate() ??
        false)) {
      return null;
    }

    if (!validateQuantity()) {
      return null;
    }

    if (!validatePayment()) {
      return null;
    }

    final String details =
        widget.service.businessCard
            ? (twoSides ? 'وجهين' : 'وجه واحد')
            : detailsController.text.trim();

    final int id =
        await AppDatabase.addOrder(
      <String, dynamic>{
        'customer':
            customerController.text.trim(),
        'phone':
            phoneController.text.trim(),
        'service':
            widget.service.name,
        'quantity':
            quantityText,
        'details':
            details,
        'total':
            total,
        'paid':
            paid,
        'remaining':
            remaining,
        'status':
            'جديد',
        'notes':
            notesController.text.trim(),
        'payment_method':
            paymentMethod,
        'transfer_last6':
            transferLast6Controller.text.trim(),
        'receipt_image':
            receiptImage?.path,
        'created_at':
            DateTime.now().toIso8601String(),
      },
    );

    await widget.onSaved();

    return id;
  }

  Future<void> sendOrder() async {
    final int? orderId =
        await saveOrder();

    if (orderId == null || !mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (
        BuildContext sheetContext,
      ) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'إرسال الطلب عبر واتساب',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: GhanjatApp.purple,
                    ),
                  ),

                  const SizedBox(height: 16),

                  whatsappButton(
                    sheetContext,
                    orderId,
                    '0115494130',
                    '249115494130',
                  ),

                  const SizedBox(height: 10),

                  whatsappButton(
                    sheetContext,
                    orderId,
                    '0994482612',
                    '249994482612',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget whatsappButton(
    BuildContext sheetContext,
    int orderId,
    String visiblePhone,
    String phone,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
        ),
        onPressed: () {
          Navigator.pop(sheetContext);

          openWhatsApp(
            orderId,
            phone,
          );
        },
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
        ),
        label: Text(
          visiblePhone,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> openWhatsApp(
    int orderId,
    String phone,
  ) async {
    final Map<String, String> account =
        selectedAccount!;

    final String message = '''
طلب جديد - غنجات للطباعة

رقم الطلب: #$orderId
الخدمة: ${widget.service.name}
اسم العميل: ${customerController.text.trim()}
الهاتف: ${phoneController.text.trim()}
الكمية: $quantityText
${detailsController.text.trim().isEmpty ? '' : 'التفاصيل: ${detailsController.text.trim()}'}

الإجمالي: ${money(total)} جنيه
المدفوع: ${money(paid)} جنيه
المتبقي: ${money(remaining)} جنيه

طريقة الدفع: $paymentMethod
رقم الحساب: ${account['account']}
اسم الحساب: ${account['name']}
آخر 6 أرقام من التحويل: ${transferLast6Controller.text.trim()}
تم اختيار صورة إشعار التحويل داخل الطلب.

الملاحظات: ${notesController.text.trim()}
''';

    final Uri uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    final bool opened =
        await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      showError(
        'تعذر فتح واتساب',
      );
    }
  }

  Widget paymentOption(
    String title,
    String account,
  ) {
    final bool selected =
        paymentMethod == title;

    return InkWell(
      borderRadius:
          BorderRadius.circular(18),
      onTap: () {
        setState(() {
          paymentMethod = title;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected
                ? GhanjatApp.purple
                : const Color(0xFFE1DCE6),
          ),
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Row(
          children: <Widget>[
            Radio<String>(
              value: title,
              groupValue: paymentMethod,
              activeColor: GhanjatApp.purple,
              onChanged: (
                String? value,
              ) {
                setState(() {
                  paymentMethod = value;
                });
              },
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'رقم الحساب: $account',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'الدفع',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GhanjatApp.purple,
          ),
        ),

        const SizedBox(height: 10),

        paymentOption(
          'بنكك',
          bankakAccount,
        ),

        const SizedBox(height: 10),

        paymentOption(
          'فوري',
          fawryAccount,
        ),

        if (selectedAccount != null)
          ...<Widget>[
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF8F5FA,
                ),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'الحساب: ${selectedAccount!['account']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'الاسم: ${selectedAccount!['name']}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
                  transferLast6Controller,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              decoration:
                  const InputDecoration(
                labelText:
                    'آخر 6 أرقام من التحويل',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: pickReceipt,
              icon: const Icon(
                Icons.image_outlined,
              ),
              label: Text(
                receiptImage == null
                    ? 'اختيار صورة إشعار التحويل'
                    : 'تم اختيار الصورة - تغيير الصورة',
              ),
            ),

            if (receiptImage != null)
              ...<Widget>[
                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(14),
                  child: Image.file(
                    File(
                      receiptImage!.path,
                    ),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String priceTitle =
        widget.service.per100
            ? '${money(unitPrice)} جنيه لكل 100 كرت'
            : '${money(unitPrice)} جنيه / ${widget.service.unit}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            GhanjatApp.purple,
        foregroundColor:
            Colors.white,
        title: Text(
          widget.service.name,
        ),
      ),

      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF8F5FA),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      widget.service.icon,
                      size: 42,
                      color:
                          GhanjatApp.turquoise,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.service.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      priceTitle,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    customerController,
                decoration:
                    const InputDecoration(
                  labelText: 'اسم العميل',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (
                  String? value,
                ) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'اكتب اسم العميل';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (
                  String? value,
                ) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'اكتب رقم الهاتف';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              if (widget.service.businessCard)
                ...<Widget>[
                  SwitchListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'طباعة وجهين',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      twoSides
                          ? '35,000 جنيه لكل 100 كرت'
                          : '30,000 جنيه لكل 100 كرت',
                    ),
                    value: twoSides,
                    activeColor:
                        GhanjatApp.purple,
                    onChanged: (
                      bool value,
                    ) {
                      setState(() {
                        twoSides = value;
                      });
                    },
                  ),

                  const SizedBox(height: 6),
                ],

              TextFormField(
                controller:
                    quantityController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      widget.service.per100
                          ? 'عدد الكروت - مثال 100 أو 200'
                          : 'الكمية (${widget.service.unit})',
                  border:
                      const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                },
                validator: (
                  String? value,
                ) {
                  final double? number =
                      double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (number == null ||
                      number <= 0) {
                    return 'اكتب كمية صحيحة';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              if (!widget.service.businessCard)
                TextFormField(
                  controller:
                      detailsController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(
                    labelText: 'التفاصيل',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

              if (!widget.service.businessCard)
                const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0FAF8),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Column(
                  children: <Widget>[
                    _moneyRow(
                      'الإجمالي',
                      total,
                      bold: true,
                    ),

                    const Divider(),

                    _moneyRow(
                      'المدفوع',
                      paid,
                    ),

                    const Divider(),

                    _moneyRow(
                      'المتبقي',
                      remaining,
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller:
                    paidController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'المبلغ المدفوع',
                  border:
                      OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller:
                    notesController,
                maxLines: 2,
                decoration:
                    const InputDecoration(
                  labelText: 'ملاحظات',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              paymentSection(),

              const SizedBox(height: 22),

              ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      GhanjatApp.purple,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.all(16),
                ),
                onPressed: sendOrder,
                icon: const Icon(
                  Icons.send,
                ),
                label: const Text(
                  'تأكيد وإرسال الطلب',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moneyRow(
    String title,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          const Spacer(),

          Text(
            '${money(value)} جنيه',
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: bold
                  ? GhanjatApp.purple
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// صفحة الطلبات
// ==========================================

class OrdersPage extends StatefulWidget {
  final List<Map<String, dynamic>> orders;

  final Future<void> Function() onRefresh;

  const OrdersPage({
    super.key,
    required this.orders,
    required this.onRefresh,
  });

  @override
  State<OrdersPage> createState() {
    return _OrdersPageState();
  }
}

class _OrdersPageState
    extends State<OrdersPage> {
  Future<void> changeStatus(
    Map<String, dynamic> order,
    String status,
  ) async {
    await AppDatabase.updateStatus(
      (order['id'] as num).toInt(),
      status,
    );

    await widget.onRefresh();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            GhanjatApp.purple,
        foregroundColor:
            Colors.white,
        title: const Text(
          'الطلبات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: widget.onRefresh,

        child: widget.orders.isEmpty
            ? ListView(
                children: const <Widget>[
                  SizedBox(height: 180),

                  Icon(
                    Icons.receipt_long_outlined,
                    size: 70,
                    color: Colors.black26,
                  ),

                  SizedBox(height: 12),

                  Center(
                    child: Text(
                      'لا توجد طلبات حتى الآن',
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.all(14),
                itemCount:
                    widget.orders.length,
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final Map<String, dynamic>
                      order =
                      widget.orders[index];

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            GhanjatApp.turquoise,
                        foregroundColor:
                            Colors.white,
                        child: Text(
                          '#${order['id']}',
                        ),
                      ),

                      title: Text(
                        '${order['service']}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        '${order['customer']} • ${money(order['total'] as num? ?? 0)} ج',
                      ),

                      childrenPadding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),

                      children: <Widget>[
                        _row(
                          'الهاتف',
                          '${order['phone']}',
                        ),

                        _row(
                          'الكمية',
                          '${order['quantity']}',
                        ),

                        _row(
                          'الإجمالي',
                          '${money(order['total'] as num? ?? 0)} جنيه',
                        ),

                        _row(
                          'المدفوع',
                          '${money(order['paid'] as num? ?? 0)} جنيه',
                        ),

                        _row(
                          'المتبقي',
                          '${money(order['remaining'] as num? ?? 0)} جنيه',
                        ),

                        _row(
                          'طريقة الدفع',
                          '${order['payment_method'] ?? '-'}',
                        ),

                        _row(
                          'آخر 6 أرقام',
                          '${order['transfer_last6'] ?? '-'}',
                        ),

                        const SizedBox(height: 8),

                        if ((order['receipt_image']
                                    as String?)
                                ?.isNotEmpty ==
                            true)
                          Builder(
                            builder: (
                              BuildContext context,
                            ) {
                              final String imagePath =
                                  order[
                                      'receipt_image'];

                              final File imageFile =
                                  File(imagePath);

                              if (!imageFile
                                  .existsSync()) {
                                return const Text(
                                  'صورة الإشعار غير متاحة على الجهاز',
                                  style: TextStyle(
                                    color:
                                        Colors.black54,
                                  ),
                                );
                              }

                              return ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                                child: Image.file(
                                  imageFile,
                                  height: 160,
                                  width:
                                      double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value:
                              '${order['status']}',
                          decoration:
                              const InputDecoration(
                            labelText: 'الحالة',
                            border:
                                OutlineInputBorder(),
                          ),
                          items: const <String>[
                            'جديد',
                            'قيد التنفيذ',
                            'جاهز',
                            'تم التسليم',
                          ].map(
                            (String status) {
                              return DropdownMenuItem<
                                  String>(
                                value: status,
                                child: Text(status),
                              );
                            },
                          ).toList(),
                          onChanged: (
                            String? value,
                          ) {
                            if (value != null) {
                              changeStatus(
                                order,
                                value,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _row(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
