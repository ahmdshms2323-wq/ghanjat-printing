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

// ==================================================
// قاعدة البيانات
// ==================================================

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final String databasePath = p.join(
      await getDatabasesPath(),
      'ghanjat_orders.db',
    );

    _db = await openDatabase(
      databasePath,

      // تم رفع الإصدار من 1 إلى 2
      version: 2,

      onCreate: (Database db, int version) async {
        await db.execute(
          '''
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
          ''',
        );
      },

      // يحافظ على الطلبات القديمة
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

// ==================================================
// بيانات الخدمات
// ==================================================

class ServiceData {
  final String name;
  final IconData icon;
  final String unit;
  final double price;

  final bool businessCard;
  final bool pack100;
  final bool bagsCategory;

  const ServiceData({
    required this.name,
    required this.icon,
    required this.unit,
    required this.price,
    this.businessCard = false,
    this.pack100 = false,
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
    unit: '100 كرت',
    price: 70000,
    pack100: true,
  ),
];

// ==================================================
// الصفحة الأساسية
// ==================================================

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

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
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 18),

                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF0FAF8),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: GhanjatApp.turquoise,
                      ),
                    ),
                    title: const Text(
                      'أكياس بلاستيك',
                      style: TextStyle(
                        fontSize: 18,
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
                      Navigator.of(sheetContext).pop();

                      openOrderForm(
                        plasticBagService,
                      );
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF0FAF8),
                      child: Icon(
                        Icons.shopping_bag,
                        color: GhanjatApp.turquoise,
                      ),
                    ),
                    title: const Text(
                      'أكياس قماش',
                      style: TextStyle(
                        fontSize: 18,
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
                      Navigator.of(sheetContext).pop();

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
                    const SizedBox(height: 15),

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
                            Navigator.of(
                              sheetContext,
                            ).pop();

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
        onDrawerChanged: (bool isOpen) {
          setState(() {
            drawerOpen = isOpen;
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

// ==================================================
// الصفحة الرئيسية + القائمة الجانبية
// ==================================================

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  final ValueChanged<ServiceData> onServiceTap;

  final VoidCallback onOrdersTap;

  final ValueChanged<bool> onDrawerChanged;

  const HomeContent({
    Key? key,
    required this.orders,
    required this.onServiceTap,
    required this.onOrdersTap,
    required this.onDrawerChanged,
  }) : super(key: key);

  Future<void> openLink(String link) async {
    final Uri uri = Uri.parse(link);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void drawerService(
    BuildContext context,
    ServiceData service,
  ) {
    Navigator.of(context).pop();

    Future<void>.delayed(
      const Duration(milliseconds: 150),
      () async {
        onServiceTap(service);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 18,
                  ),
                  color: GhanjatApp.purple,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  leading: const Icon(
                    Icons.home,
                    color: GhanjatApp.purple,
                  ),
                  title: const Text(
                    'الرئيسية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Text(
                    'خدماتنا',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
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
                      trailing: const Icon(
                        Icons.chevron_left,
                        size: 20,
                      ),
                      onTap: () {
                        drawerService(
                          context,
                          service,
                        );
                      },
                    );
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: GhanjatApp.purple,
                  ),
                  title: const Text(
                    'الطلبات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: CircleAvatar(
                    radius: 14,
                    backgroundColor: GhanjatApp.purple,
                    child: Text(
                      '${orders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();

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
                    'تواصل معنا',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                  ),
                  title: const Text(
                    '0115494130',
                  ),
                  onTap: () {
                    openLink(
                      'https://wa.me/249115494130',
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
                    openLink(
                      'https://wa.me/249994482612',
                    );
                  },
                ),

                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.facebook,
                  ),
                  title: const Text(
                    'فيسبوك',
                  ),
                  onTap: () {},
                ),

                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.tiktok,
                  ),
                  title: const Text(
                    'تيك توك',
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: GhanjatApp.purple,
        elevation: 0,
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
          16,
          10,
          16,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'ghanjat_banner.jpg',
                fit: BoxFit.cover,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Container(
                    height: 150,
                    color: GhanjatApp.light,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.print,
                      size: 70,
                      color: GhanjatApp.purple,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'خدماتنا',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: GhanjatApp.purple,
              ),
            ),

            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final ServiceData service =
                    services[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    onServiceTap(service);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GhanjatApp.light,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE9E0EF),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          service.icon,
                          size: 42,
                          color: GhanjatApp.purple,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          service.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  const Text(
                    'تواصل معنا',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GhanjatApp.purple,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                GhanjatApp.turquoise,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            openLink(
                              'https://wa.me/249115494130',
                            );
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                          ),
                          label: const Text(
                            '0115494130',
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                GhanjatApp.purple,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            openLink(
                              'https://wa.me/249994482612',
                            );
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                          ),
                          label: const Text(
                            '0994482612',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderFormPage extends StatefulWidget {
  final ServiceData service;
  final Future<void> Function() onSaved;

  const OrderFormPage({
    Key? key,
    required this.service,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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

  final TextEditingController transferLast6Controller =
      TextEditingController();

  String businessSide = 'اتجاه واحد';

  // في البداية ما في طريقة دفع مختارة
  String? paymentMethod;

  XFile? receiptImage;

  bool saving = false;

  // بيانات بنكك
  static const String bankakAccount = '2769498';

  // بيانات فوري
  static const String fawryAccount = '51799301';

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
    if (widget.service.businessCard) {
      return businessSide == 'اتجاهين'
          ? 35000
          : 30000;
    }

    return widget.service.price;
  }

  double get total {
    return quantity * unitPrice;
  }

  double get remaining {
    final double value = total - paid;

    return value < 0 ? 0 : value;
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

  String get selectedAccount {
    if (paymentMethod == 'بنكك') {
      return bankakAccount;
    }

    if (paymentMethod == 'فوري') {
      return fawryAccount;
    }

    return '';
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> pickReceipt() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        receiptImage = image;
      });
    } catch (_) {
      if (!mounted) return;

      showMessage(
        'تعذر اختيار الصورة، حاول مرة أخرى',
      );
    }
  }

  bool validatePayment() {
    if (paymentMethod == null) {
      showMessage(
        'اختر طريقة الدفع: بنكك أو فوري',
      );

      return false;
    }

    final String last6 =
        transferLast6Controller.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(last6)) {
      showMessage(
        'أدخل آخر 6 أرقام من عملية التحويل',
      );

      return false;
    }

    if (receiptImage == null) {
      showMessage(
        'ارفع صورة إشعار التحويل',
      );

      return false;
    }

    return true;
  }

  Future<int?> saveOrder() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return null;
    }

    if (!validatePayment()) {
      return null;
    }

    if (saving) {
      return null;
    }

    setState(() {
      saving = true;
    });

    try {
      final int id = await AppDatabase.addOrder(
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
              detailsController.text.trim(),
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

          // بيانات الدفع الجديدة
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
    } catch (e) {
      if (mounted) {
        showMessage(
          'حدث خطأ أثناء حفظ الطلب',
        );
      }

      return null;
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> sendOrder() async {
    final int? orderId = await saveOrder();

    if (orderId == null || !mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
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

                  const SizedBox(height: 15),

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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(14),
        ),
        onPressed: () {
          Navigator.of(sheetContext).pop();

          openWhatsApp(
            orderId,
            number,
          );
        },
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
        ),
        label: Text(
          number,
          style: const TextStyle(
            fontSize: 19,
          ),
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
        'التفاصيل: ${detailsController.text.trim()}\n\n'
        'الإجمالي: ${money(total)} جنيه\n'
        'المدفوع: ${money(paid)} جنيه\n'
        'المتبقي: ${money(remaining)} جنيه\n\n'
        'طريقة الدفع: $paymentMethod\n'
        'رقم الحساب: $selectedAccount\n'
        'اسم الحساب: $accountName\n'
        'آخر 6 أرقام من التحويل: ${transferLast6Controller.text.trim()}\n'
        'تم رفع صورة إشعار التحويل داخل الطلب\n\n'
        'الملاحظات: ${notesController.text.trim()}';

    final Uri uri = Uri.parse(
      'https://wa.me/$international?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Widget paymentOption({
    required String title,
    required IconData icon,
  }) {
    final bool selected =
        paymentMethod == title;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            paymentMethod = title;

            transferLast6Controller.clear();
            receiptImage = null;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0FAF8)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? GhanjatApp.turquoise
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                size: 31,
                color: selected
                    ? GhanjatApp.purple
                    : Colors.grey.shade600,
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color: selected
                      ? GhanjatApp.purple
                      : Colors.black87,
                ),
              ),

              const SizedBox(height: 5),

              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected
                    ? GhanjatApp.turquoise
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GhanjatApp.light,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFE4DCEA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_outlined,
                color: GhanjatApp.purple,
              ),

              SizedBox(width: 8),

              Text(
                'طريقة الدفع',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      GhanjatApp.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'اختر طريقة الدفع أولاً',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: <Widget>[
              paymentOption(
                title: 'بنكك',
                icon:
                    Icons.account_balance_outlined,
              ),

              const SizedBox(width: 12),

              paymentOption(
                title: 'فوري',
                icon:
                    Icons.mobile_friendly_outlined,
              ),
            ],
          ),

          if (paymentMethod != null) ...<Widget>[
            const SizedBox(height: 20),

            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'بيانات حساب $paymentMethod',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          GhanjatApp.purple,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'رقم الحساب',
                    style: TextStyle(
                      color:
                          Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Directionality(
                    textDirection:
                        TextDirection.ltr,
                    child: SelectableText(
                      selectedAccount,
                      textAlign:
                          TextAlign.right,
                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const Divider(
                    height: 25,
                  ),

                  const Text(
                    'اسم الحساب',
                    style: TextStyle(
                      color:
                          Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    accountName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller:
                  transferLast6Controller,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              decoration:
                  const InputDecoration(
                labelText:
                    'آخر 6 أرقام من عملية التحويل',
                hintText: 'مثال: 123456',
                prefixIcon:
                    Icon(
                  Icons.pin_outlined,
                ),
                border:
                    OutlineInputBorder(),
                counterText: '',
              ),
              validator: (String? value) {
                if (paymentMethod == null) {
                  return null;
                }

                final String input =
                    value?.trim() ?? '';

                if (!RegExp(r'^\d{6}$')
                    .hasMatch(input)) {
                  return 'أدخل 6 أرقام بالضبط';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'صورة إشعار التحويل',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    GhanjatApp.purple,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
              onPressed: pickReceipt,
              icon: Icon(
                receiptImage == null
                    ? Icons
                        .add_photo_alternate_outlined
                    : Icons
                        .change_circle_outlined,
              ),
              label: Text(
                receiptImage == null
                    ? 'رفع صورة إشعار التحويل'
                    : 'تغيير صورة الإشعار',
              ),
            ),

            if (receiptImage != null) ...<Widget>[
              const SizedBox(height: 14),

              Container(
                height: 220,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color:
                        Colors.grey.shade300,
                  ),
                ),
                clipBehavior:
                    Clip.antiAlias,
                child: Image.file(
                  File(receiptImage!.path),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return const Center(
                      child: Text(
                        'تم اختيار صورة الإشعار',
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 19,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'تم رفع صورة الإشعار',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            GhanjatApp.purple,
        foregroundColor:
            Colors.white,
        centerTitle: true,
        title:
            Text(widget.service.name),
      ),

      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      GhanjatApp.light,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 27,
                      backgroundColor:
                          const Color(
                        0xFFF0FAF8,
                      ),
                      child: Icon(
                        widget.service.icon,
                        color:
                            GhanjatApp.turquoise,
                        size: 31,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: <Widget>[
                          Text(
                            widget.service.name,
                            style:
                                const TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          if (!widget
                              .service
                              .businessCard)
                            Text(
                              '${money(widget.service.price)} جنيه / ${widget.service.unit}',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (widget.service.businessCard) ...<Widget>[
                const Text(
                  'نوع طباعة البزنس كارد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: businessSide,
                  decoration:
                      const InputDecoration(
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.style_outlined,
                    ),
                  ),
                  items:
                      const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'اتجاه واحد',
                      child: Text(
                        'اتجاه واحد - 30,000 جنيه',
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'اتجاهين',
                      child: Text(
                        'اتجاهين - 35,000 جنيه',
                      ),
                    ),
                  ],
                  onChanged:
                      (String? value) {
                    if (value == null) return;

                    setState(() {
                      businessSide = value;
                    });
                  },
                ),

                const SizedBox(height: 20),
              ],

              TextFormField(
                controller:
                    customerController,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    const InputDecoration(
                  labelText: 'اسم العميل',
                  prefixIcon:
                      Icon(
                    Icons.person_outline,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                validator:
                    (String? value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'أدخل اسم العميل';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon:
                      Icon(
                    Icons.phone_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                validator:
                    (String? value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'أدخل رقم الهاتف';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller:
                    quantityController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    InputDecoration(
                  labelText:
                      widget.service.pack100
                          ? 'عدد المجموعات - كل مجموعة 100 كرت'
                          : 'الكمية (${widget.service.unit})',
                  prefixIcon:
                      const Icon(
                    Icons.numbers,
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                },
                validator:
                    (String? value) {
                  final double? number =
                      double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (number == null ||
                      number <= 0) {
                    return 'أدخل كمية صحيحة';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller:
                    detailsController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'تفاصيل الطلب',
                  hintText:
                      'اكتب المقاس، اللون أو أي تفاصيل أخرى',
                  prefixIcon:
                      Icon(
                    Icons.description_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

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
                  prefixIcon:
                      Icon(
                    Icons.payments_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                },
                validator:
                    (String? value) {
                  final double? number =
                      double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (number == null ||
                      number < 0) {
                    return 'أدخل مبلغ صحيح';
                  }

                  if (number > total) {
                    return 'المبلغ المدفوع أكبر من إجمالي الطلب';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller:
                    notesController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'ملاحظات إضافية',
                  prefixIcon:
                      Icon(
                    Icons.note_alt_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 22),

              // ملخص الحساب
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF0FAF8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: <Widget>[
                        const Text(
                          'الإجمالي',
                        ),
                        Text(
                          '${money(total)} جنيه',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: <Widget>[
                        const Text(
                          'المدفوع',
                        ),
                        Text(
                          '${money(paid)} جنيه',
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: <Widget>[
                        const Text(
                          'المتبقي',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${money(remaining)} جنيه',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                GhanjatApp.purple,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================
              // نظام الدفع
              // ==================================

              paymentSection(),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      GhanjatApp.purple,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                ),
                onPressed:
                    saving ? null : sendOrder,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const FaIcon(
                        FontAwesomeIcons.whatsapp,
                      ),
                label: Text(
                  saving
                      ? 'جاري حفظ الطلب...'
                      : 'تأكيد وإرسال الطلب',
                  style:
                      const TextStyle(
                    fontSize: 18,
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
}

// ==================================================
// صفحة الطلبات
// ==================================================

class OrdersPage extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Future<void> Function() onRefresh;

  const OrdersPage({
    Key? key,
    required this.orders,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<OrdersPage> createState() =>
      _OrdersPageState();
}

class _OrdersPageState
    extends State<OrdersPage> {
  String money(dynamic value) {
    final double number =
        (value as num? ?? 0).toDouble();

    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case 'تحت التنفيذ':
        return Colors.orange;

      case 'جاهز':
        return Colors.blue;

      case 'تم التسليم':
        return Colors.green;

      default:
        return GhanjatApp.purple;
    }
  }

  Future<void> changeStatus(
    Map<String, dynamic> order,
  ) async {
    final String? result =
        await showModalBottomSheet<String>(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder:
          (BuildContext context) {
        const List<String> statuses =
            <String>[
          'جديد',
          'تحت التنفيذ',
          'جاهز',
          'تم التسليم',
        ];

        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'تغيير حالة الطلب',
                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ...statuses.map(
                    (String status) {
                      return ListTile(
                        leading: Icon(
                          status ==
                                  order[
                                      'status']
                              ? Icons
                                  .radio_button_checked
                              : Icons
                                  .radio_button_unchecked,
                          color:
                              statusColor(
                            status,
                          ),
                        ),
                        title:
                            Text(status),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pop(
                            status,
                          );
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

    if (result == null) return;

    await AppDatabase.updateStatus(
      order['id'] as int,
      result,
    );

    await widget.onRefresh();

    if (mounted) {
      setState(() {});
    }
  }

  Widget receiptPreview(
    String? path,
  ) {
    if (path == null ||
        path.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final File file = File(path);

    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        top: 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'إشعار التحويل',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: Image.file(
              file,
              height: 180,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            GhanjatApp.purple,
        foregroundColor:
            Colors.white,
        automaticallyImplyLeading:
            false,
        centerTitle: true,
        title: const Text(
          'الطلبات',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed:
                widget.onRefresh,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: widget.orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons
                        .receipt_long_outlined,
                    size: 65,
                    color:
                        Colors.grey,
                  ),

                  SizedBox(
                    height: 12,
                  ),

                  Text(
                    'ما في طلبات لسه',
                    style:
                        TextStyle(
                      fontSize: 19,
                      color:
                          Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh:
                  widget.onRefresh,
              child: ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  100,
                ),
                itemCount:
                    widget.orders.length,
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final Map<String, dynamic>
                      order =
                      widget.orders[index];

                  final String status =
                      order['status']
                              ?.toString() ??
                          'جديد';

                  final String
                      paymentMethod =
                      order['payment_method']
                              ?.toString() ??
                          '';

                  final String last6 =
                      order['transfer_last6']
                              ?.toString() ??
                          '';

                  final String
                      receiptPath =
                      order['receipt_image']
                              ?.toString() ??
                          '';

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                        ExpansionTile(
                      leading:
                          CircleAvatar(
                        backgroundColor:
                            GhanjatApp
                                .light,
                        child: Text(
                          '#${order['id']}',
                          style:
                              const TextStyle(
                            color:
                                GhanjatApp
                                    .purple,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),

                      title: Text(
                        order['customer']
                                ?.toString() ??
                            '',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        order['service']
                                ?.toString() ??
                            '',
                      ),

                      trailing:
                          Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              statusColor(
                                    status,
                                  )
                                  .withOpacity(
                            0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Text(
                          status,
                          style:
                              TextStyle(
                            color:
                                statusColor(
                              status,
                            ),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      childrenPadding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        18,
                      ),

                      children:
                          <Widget>[
                        const Divider(),

                        ListTile(
                          dense: true,
                          leading:
                              const Icon(
                            Icons
                                .phone_outlined,
                          ),
                          title: Text(
                            'الهاتف: ${order['phone'] ?? ''}',
                          ),
                        ),

                        ListTile(
                          dense: true,
                          leading:
                              const Icon(
                            Icons
                                .inventory_2_outlined,
                          ),
                          title: Text(
                            'الكمية: ${order['quantity'] ?? ''}',
                          ),
                        ),

                        ListTile(
                          dense: true,
                          leading:
                              const Icon(
                            Icons
                                .payments_outlined,
                          ),
                          title: Text(
                            'الإجمالي: ${money(order['total'])} جنيه',
                          ),
                          subtitle: Text(
                            'المدفوع: ${money(order['paid'])} جنيه\n'
                            'المتبقي: ${money(order['remaining'])} جنيه',
                          ),
                        ),

                        if (paymentMethod
                            .isNotEmpty)
                          Container(
                            width:
                                double.infinity,
                            margin:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            padding:
                                const EdgeInsets.all(
                              14,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF0FAF8,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children:
                                  <Widget>[
                                const Text(
                                  'بيانات الدفع',
                                  style:
                                      TextStyle(
                                    color:
                                        GhanjatApp
                                            .purple,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize:
                                        17,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'طريقة الدفع: $paymentMethod',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'آخر 6 أرقام: $last6',
                                ),

                                receiptPreview(
                                  receiptPath,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(
                          height: 12,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              OutlinedButton.icon(
                            onPressed:
                                () {
                              changeStatus(
                                order,
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .edit_outlined,
                            ),
                            label:
                                const Text(
                              'تغيير حالة الطلب',
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
