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
  static const Color light = Color(0xFFF2F8F7);

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

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String dbPath = p.join(
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

  static Future<int> insertOrder(
    Map<String, dynamic> order,
  ) async {
    final Database db = await database;
    return db.insert('orders', order);
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

class ServiceData {
  final String name;
  final IconData icon;
  final String unit;
  final double price;
  final bool isBusinessCard;
  final bool isPack100;

  const ServiceData({
    required this.name,
    required this.icon,
    required this.unit,
    required this.price,
    this.isBusinessCard = false,
    this.isPack100 = false,
  });
}

const List<ServiceData> services = <ServiceData>[
  ServiceData(
    name: 'بزنس كارد',
    icon: Icons.badge_outlined,
    unit: '100 كرت',
    price: 30000,
    isBusinessCard: true,
    isPack100: true,
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
    icon: Icons.card_giftcard_outlined,
    unit: '100 كرت',
    price: 70000,
    isPack100: true,
  ),
];

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() {
    return _MainPageState();
  }
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

    if (!mounted) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(
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
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ValueChanged<ServiceData> onServiceTap;

  const HomePage({
    Key? key,
    required this.orders,
    required this.onServiceTap,
  }) : super(key: key);

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) {
        return '${match[1]},';
      },
    );
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 30,
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
                    size: 68,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'غنجات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'لخدمات الطباعة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
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
                    icon: Icons.receipt_long_outlined,
                    title: 'الطلبات',
                    value: '${orders.length}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    icon:
                        Icons.account_balance_wallet_outlined,
                    title: 'المتبقي',
                    value: '${money(totalRemaining)} ج',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              'خدماتنا',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...services.map(
              (ServiceData service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 1,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: GhanjatApp.light,
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
                        service.isBusinessCard
                            ? '100 كرت: اتجاه واحد 30,000 • اتجاهين 35,000'
                            : '${money(service.price)} جنيه / ${service.unit}',
                      ),
                      trailing:
                          const Icon(Icons.chevron_left),
                      onTap: () {
                        onServiceTap(service);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
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
                  ContactNumber(number: '0115494130'),
                  SizedBox(height: 10),
                  ContactNumber(number: '0994482612'),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: GhanjatApp.turquoise,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(title),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GhanjatApp.purple,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
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

class OrderFormPage extends StatefulWidget {
  final ServiceData service;
  final Future<void> Function() onSaved;

  const OrderFormPage({
    Key? key,
    required this.service,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<OrderFormPage> createState() {
    return _OrderFormPageState();
  }
}

class _OrderFormPageState extends State<OrderFormPage> {
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
  bool saving = false;

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
    if (widget.service.isBusinessCard) {
      if (businessSide == 'اتجاهين') {
        return 35000;
      }

      return 30000;
    }

    return widget.service.price;
  }

  double get total {
    return quantity * unitPrice;
  }

  double get remaining {
    final double result = total - paid;

    if (result < 0) {
      return 0;
    }

    return result;
  }

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) {
        return '${match[1]},';
      },
    );
  }

  String get quantityText {
    if (widget.service.isPack100) {
      final int cards = (quantity * 100).round();
      return '$cards كرت';
    }

    final String amount = quantity % 1 == 0
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(2);

    return '$amount ${widget.service.unit}';
  }

  Future<int?> saveOrder() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return null;
    }

    if (quantity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الكمية لازم تكون أكبر من صفر',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return null;
    }

    setState(() {
      saving = true;
    });

    String details = detailsController.text.trim();

    if (widget.service.isBusinessCard) {
      if (details.isEmpty) {
        details = businessSide;
      } else {
        details = '$businessSide - $details';
      }
    }

    final int id = await AppDatabase.insertOrder(
      <String, dynamic>{
        'customer': customerController.text.trim(),
        'phone': phoneController.text.trim(),
        'service': widget.service.name,
        'quantity': quantityText,
        'details': details,
        'total': total,
        'paid': paid,
        'remaining': remaining,
        'notes': notesController.text.trim(),
        'status': 'جديد',
        'created_at':
            DateTime.now().toIso8601String(),
      },
    );

    await widget.onSaved();

    if (mounted) {
      setState(() {
        saving = false;
      });
    }

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

  Future<void> saveAndSend() async {
    final int? id = await saveOrder();

    if (id == null || !mounted) {
      return;
    }

    _showWhatsAppNumbers(id);
  }

  void _showWhatsAppNumbers(int orderId) {
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
                  size: 45,
                ),
                const SizedBox(height: 12),
                Text(
                  'إرسال الطلب #$orderId عبر واتساب',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _whatsappChoice(
                  sheetContext,
                  orderId,
                  '0115494130',
                ),
                const SizedBox(height: 10),
                _whatsappChoice(
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

  Widget _whatsappChoice(
    BuildContext sheetContext,
    int orderId,
    String number,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();

          _openWhatsApp(
            orderId,
            number,
          );
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
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(
    int orderId,
    String localNumber,
  ) async {
    final String internationalNumber =
        localNumber == '0115494130'
            ? '249115494130'
            : '249994482612';

    final String details =
        detailsController.text.trim().isEmpty
            ? 'لا توجد'
            : detailsController.text.trim();

    final String notes =
        notesController.text.trim().isEmpty
            ? 'لا توجد'
            : notesController.text.trim();

    String printType = '';

    if (widget.service.isBusinessCard) {
      printType =
          'نوع الطباعة: $businessSide\n';
    }

    final String message =
        'طلب جديد - غنجات للطباعة\n\n'
        'رقم الطلب: #$orderId\n'
        'الخدمة: ${widget.service.name}\n'
        '$printType'
        'العميل: ${customerController.text.trim()}\n'
        'الهاتف: ${phoneController.text.trim()}\n'
        'الكمية: $quantityText\n'
        'التفاصيل: $details\n'
        'الإجمالي: ${money(total)} جنيه\n'
        'المدفوع: ${money(paid)} جنيه\n'
        'المتبقي: ${money(remaining)} جنيه\n'
        'الحالة: جديد\n'
        'الملاحظات: $notes';

    final Uri uri = Uri.parse(
      'https://wa.me/$internationalNumber?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget amountRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 19 : 17,
              fontWeight: FontWeight.bold,
              color: bold
                  ? GhanjatApp.purple
                  : Colors.black87,
            ),
          ),
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

    super.dispose();
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
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: GhanjatApp.light,
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  child: Icon(
                    widget.service.icon,
                    color: GhanjatApp.turquoise,
                    size: 58,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.service.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              if (widget.service.isBusinessCard)
                Container(
                  decoration: BoxDecoration(
                    color: GhanjatApp.light,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: <Widget>[
                      RadioListTile<String>(
                        value: 'اتجاه واحد',
                        groupValue: businessSide,
                        title: const Text(
                          'اتجاه واحد - 30,000 جنيه / 100 كرت',
                        ),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            businessSide = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        value: 'اتجاهين',
                        groupValue: businessSide,
                        title: const Text(
                          'اتجاهين - 35,000 جنيه / 100 كرت',
                        ),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            businessSide = value;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GhanjatApp.light,
                    borderRadius:
                        BorderRadius.circular(18),
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

              const SizedBox(height: 22),

              const Text(
                'بيانات الطلب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              buildTextField(
                controller: customerController,
                label: 'اسم العميل',
                icon: Icons.person_outline,
                requiredField: true,
              ),

              const SizedBox(height: 12),

              buildTextField(
                controller: phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                requiredField: true,
              ),

              const SizedBox(height: 12),

              buildTextField(
                controller: quantityController,
                label: widget.service.isPack100
                    ? 'عدد الحزم - كل حزمة 100 كرت'
                    : 'الكمية بـ ${widget.service.unit}',
                icon: Icons.numbers,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                requiredField: true,
                onChanged: (String value) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              buildTextField(
                controller: detailsController,
                label: 'المقاس / التفاصيل',
                icon: Icons.straighten,
              ),

              const SizedBox(height: 12),

              buildTextField(
                controller: paidController,
                label: 'المبلغ المدفوع',
                icon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                onChanged: (String value) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  prefixIcon: const Icon(
                    Icons.notes,
                    color: GhanjatApp.turquoise,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: GhanjatApp.light,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Column(
                  children: <Widget>[
                    amountRow(
                      'الإجمالي',
                      '${money(total)} جنيه',
                      bold: true,
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
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed:
                      saving ? null : saveOnly,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        GhanjatApp.purple,
                    foregroundColor:
                        Colors.white,
                  ),
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'حفظ الطلب',
                    style:
                        TextStyle(fontSize: 19),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed:
                      saving ? null : saveAndSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green,
                    foregroundColor:
                        Colors.white,
                  ),
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                  ),
                  label: const Text(
                    'حفظ وإرسال عبر واتساب',
                    style:
                        TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

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
      (Match match) {
        return '${match[1]},';
      },
    );
  }

  Color statusColor(String status) {
    if (status == 'تم التسليم') {
      return Colors.green;
    }

    if (status == 'جاهز') {
      return Colors.blue;
    }

    if (status == 'تحت التنفيذ') {
      return Colors.orange;
    }

    return Colors.grey;
  }

  Future<void> showStatusPicker(
    BuildContext pageContext,
    Map<String, dynamic> order,
  ) async {
    final String? newStatus =
        await showModalBottomSheet<String>(
      context: pageContext,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),
              const Text(
                'تغيير حالة الطلب',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _statusTile(
                sheetContext,
                'جديد',
              ),
              _statusTile(
                sheetContext,
                'تحت التنفيذ',
              ),
              _statusTile(
                sheetContext,
                'جاهز',
              ),
              _statusTile(
                sheetContext,
                'تم التسليم',
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (newStatus == null) {
      return;
    }

    await AppDatabase.updateStatus(
      order['id'] as int,
      newStatus,
    );

    await onRefresh();
  }

  Widget _statusTile(
    BuildContext sheetContext,
    String status,
  ) {
    return ListTile(
      leading: Icon(
        Icons.circle,
        color: statusColor(status),
        size: 15,
      ),
      title: Text(status),
      onTap: () {
        Navigator.of(sheetContext).pop(status);
      },
    );
  }

  Future<void> confirmDelete(
    BuildContext pageContext,
    Map<String, dynamic> order,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الطلب'),
            content: Text(
              'متأكد من حذف الطلب رقم #${order['id']}؟',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(false);
                },
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(true);
                },
                child: const Text(
                  'حذف',
                  style:
                      TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AppDatabase.deleteOrder(
      order['id'] as int,
    );

    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            GhanjatApp.purple,
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
                style:
                    TextStyle(fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding:
                    const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder:
                    (BuildContext pageContext,
                        int index) {
                  final Map<String, dynamic>
                      order = orders[index];

                  final double total =
                      (order['total']
                                  as num? ??
                              0)
                          .toDouble();

                  final double paid =
                      (order['paid']
                                  as num? ??
                              0)
                          .toDouble();

                  final double remaining =
                      (order['remaining']
                                  as num? ??
                              0)
                          .toDouble();

                  final String status =
                      order['status']
                              ?.toString() ??
                          'جديد';

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            GhanjatApp
                                .turquoise,
                        foregroundColor:
                            Colors.white,
                        child: Text(
                          '${order['id']}',
                        ),
                      ),
                      title: Text(
                        order['customer']
                                ?.toString() ??
                            '',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${order['service']} • باقي ${money(remaining)} ج',
                      ),
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(
                            Icons.phone_outlined,
                          ),
                          title: Text(
                            order['phone']
                                    ?.toString() ??
                                '',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.numbers,
                          ),
                          title: Text(
                            'الكمية: ${order['quantity']}',
                          ),
                        ),
                        if ((order['details']
                                    ?.toString() ??
                                '')
                            .isNotEmpty)
                          ListTile(
                            leading: const Icon(
                              Icons.info_outline,
                            ),
                            title: Text(
                              order['details']
                                  .toString(),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(
                            Icons
                                .payments_outlined,
                          ),
                          title: Text(
                            'الإجمالي: ${money(total)} جنيه',
                          ),
                          subtitle: Text(
                            'المدفوع: ${money(paid)} • المتبقي: ${money(remaining)}',
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.circle,
                            color:
                                statusColor(status),
                            size: 15,
                          ),
                          title: Text(
                            'الحالة: $status',
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child:
                                    ElevatedButton.icon(
                                  onPressed: () {
                                    showStatusPicker(
                                      pageContext,
                                      order,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.sync,
                                  ),
                                  label:
                                      const Text(
                                    'تغيير الحالة',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  confirmDelete(
                                    pageContext,
                                    order,
                                  );
                                },
                                icon: const Icon(
                                  Icons
                                      .delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ],
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
