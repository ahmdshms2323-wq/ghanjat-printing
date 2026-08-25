
import 'package:flutter/material.dart';
import 'data/app_database.dart';

void main() {
  runApp(const GhanjatApp());
}

class GhanjatApp extends StatelessWidget {
  const GhanjatApp({super.key});

  static const teal = Color(0xFF67A99F);
  static const purple = Color(0xFF39285F);
  static const lightTeal = Color(0xFFEAF5F3);
  static const background = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'غنجات للطباعة',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          primary: teal,
          secondary: purple,
        ),
        fontFamilyFallback: const ['Arial', 'Tahoma'],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final List<OrderItem> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final rows = await AppDatabase.instance.getOrders();
    if (!mounted) return;
    setState(() {
      orders
        ..clear()
        ..addAll(rows.map(OrderItem.fromMap));
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        orders: orders,
        onNewOrder: () => setState(() => index = 2),
      ),
      OrdersPage(orders: orders),
      NewOrderPage(
        onSaved: (order) async {
          await AppDatabase.instance.createOrder(
            customerName: order.customer,
            customerPhone: order.phone,
            serviceName: order.service,
            quantity: order.quantity,
            width: order.width,
            height: order.height,
            total: order.amount,
            paid: order.paid,
            status: order.status,
            dueDate: order.dueDate,
            notes: order.notes,
          );
          await _loadOrders();
          if (!mounted) return;
          setState(() => index = 1);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الطلب في قاعدة البيانات')),
          );
        },
      ),
      const CustomersPage(),
      const MorePage(),
    ];

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'الطلبات'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'طلب جديد'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'العملاء'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'المزيد'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final List<OrderItem> orders;
  final VoidCallback onNewOrder;

  const DashboardPage({
    super.key,
    required this.orders,
    required this.onNewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final totalSales = orders.fold<double>(0, (sum, item) => sum + item.amount);
    final ready = orders.where((e) => e.status == 'جاهز').length;
    final active = orders.where((e) => e.status != 'جاهز').length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Container(
                color: GhanjatApp.teal,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.print, color: GhanjatApp.purple),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'غنجات لخدمات الطباعة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'جودة الطباعة تبدأ من هنا',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_none, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.asset(
                        'assets/images/ghanjat_banner.jpg',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: GhanjatApp.purple,
                          alignment: Alignment.center,
                          child: const Text(
                            'غنجات لخدمات الطباعة',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onNewOrder,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة طلب جديد'),
                        style: FilledButton.styleFrom(
                          backgroundColor: GhanjatApp.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        StatCard(title: 'إجمالي الطلبات', value: '${orders.length}', icon: Icons.assignment_outlined),
                        StatCard(title: 'قيد التنفيذ', value: '$active', icon: Icons.print_outlined),
                        StatCard(title: 'جاهزة للتسليم', value: '$ready', icon: Icons.check_circle_outline),
                        StatCard(title: 'إجمالي المبيعات', value: '${totalSales.toStringAsFixed(0)} ج', icon: Icons.payments_outlined),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'خدماتنا'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          ServiceCard(icon: Icons.panorama_horizontal_outlined, label: 'بنر'),
                          ServiceCard(icon: Icons.sell_outlined, label: 'استيكرات'),
                          ServiceCard(icon: Icons.credit_card_outlined, label: 'كروت'),
                          ServiceCard(icon: Icons.shopping_bag_outlined, label: 'أكياس'),
                          ServiceCard(icon: Icons.view_quilt_outlined, label: 'لوحات'),
                          ServiceCard(icon: Icons.text_fields, label: 'حروف بارزة'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle(title: 'أحدث الطلبات'),
                    const SizedBox(height: 10),
                    ...orders.reversed.take(4).map((e) => OrderTile(order: e)),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GhanjatApp.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Text('تواصل معنا', style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ContactChip(number: '0994482612'),
                              ContactChip(number: '0115494130'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: GhanjatApp.lightTeal,
                child: Icon(icon, color: GhanjatApp.teal),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const Spacer(),
        const Icon(Icons.arrow_back_ios_new, size: 14, color: GhanjatApp.teal),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const ServiceCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: GhanjatApp.purple, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class OrderItem {
  final int? id;
  final String number;
  final String customer;
  final String? phone;
  final String service;
  final int quantity;
  final double width;
  final double height;
  final double amount;
  final double paid;
  final double balance;
  final String status;
  final String? dueDate;
  final String? notes;

  OrderItem({
    this.id,
    required this.number,
    required this.customer,
    this.phone,
    required this.service,
    this.quantity = 1,
    this.width = 0,
    this.height = 0,
    required this.amount,
    this.paid = 0,
    this.balance = 0,
    required this.status,
    this.dueDate,
    this.notes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      number: map['order_number']?.toString() ?? '',
      customer: map['customer_name']?.toString() ?? 'بدون اسم',
      phone: map['customer_phone']?.toString(),
      service: map['service_name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      amount: (map['total'] as num?)?.toDouble() ?? 0,
      paid: (map['paid'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'جديد',
      dueDate: map['due_date']?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}

class OrderTile extends StatelessWidget {
  final OrderItem order;
  const OrderTile({super.key, required this.order});

  Color statusColor(String status) {
    if (status == 'جاهز') return Colors.green;
    if (status.contains('الطباعة')) return Colors.blue;
    if (status.contains('التصميم')) return Colors.deepPurple;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7E9EE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: GhanjatApp.lightTeal,
              child: Text(order.number.replaceAll('#', ''), style: const TextStyle(fontSize: 10, color: GhanjatApp.purple)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customer, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(order.service, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${order.amount.toStringAsFixed(0)} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(order.status, style: TextStyle(color: color, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  final List<OrderItem> orders;
  const OrdersPage({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الطلبات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('متابعة كل طلبات المطبعة', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          TextField(
            decoration: const InputDecoration(
              hintText: 'ابحث باسم العميل أو رقم الطلب',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, i) => OrderTile(order: orders.reversed.toList()[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class NewOrderPage extends StatefulWidget {
  final Future<void> Function(OrderItem) onSaved;
  const NewOrderPage({super.key, required this.onSaved});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  final formKey = GlobalKey<FormState>();
  final customer = TextEditingController();
  final phone = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final width = TextEditingController(text: '0');
  final height = TextEditingController(text: '0');
  final total = TextEditingController(text: '0');
  final paid = TextEditingController(text: '0');
  final notes = TextEditingController();

  String service = 'بنر';
  String status = 'جديد';

  double get totalValue => double.tryParse(total.text) ?? 0;
  double get paidValue => double.tryParse(paid.text) ?? 0;
  double get balance => (totalValue - paidValue).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('طلب جديد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('أدخل بيانات العميل وتفاصيل شغل الطباعة', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            AppField(
              controller: customer,
              label: 'اسم العميل',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اسم العميل' : null,
            ),
            const SizedBox(height: 12),
            AppField(controller: phone, label: 'رقم الهاتف', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: service,
              decoration: const InputDecoration(labelText: 'نوع الخدمة', prefixIcon: Icon(Icons.print_outlined)),
              items: const ['بنر', 'كارد', 'استيكرات منتجات', 'أكياس بلاستيك', 'أكياس قماش', 'لوحات إعلانية', 'حروف بارزة', 'أخرى']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => service = v ?? service),
            ),
            const SizedBox(height: 12),
            AppField(controller: quantity, label: 'الكمية', icon: Icons.numbers, keyboard: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppField(
                    controller: width,
                    label: 'العرض',
                    icon: Icons.straighten,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppField(
                    controller: height,
                    label: 'الطول',
                    icon: Icons.height,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppField(
              controller: total,
              label: 'السعر الإجمالي',
              icon: Icons.payments_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            AppField(
              controller: paid,
              label: 'المدفوع',
              icon: Icons.account_balance_wallet_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'حالة الطلب', prefixIcon: Icon(Icons.timelapse)),
              items: const ['جديد', 'جاري التصميم', 'جاري الطباعة', 'جاهز', 'تم التسليم']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => status = v ?? status),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GhanjatApp.lightTeal,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${balance.toStringAsFixed(0)} جنيه',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GhanjatApp.purple),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;

                  await widget.onSaved(
                    OrderItem(
                      number: '',
                      customer: customer.text.trim(),
                      phone: phone.text.trim(),
                      service: service,
                      quantity: int.tryParse(quantity.text) ?? 1,
                      width: double.tryParse(width.text) ?? 0,
                      height: double.tryParse(height.text) ?? 0,
                      amount: totalValue,
                      paid: paidValue,
                      balance: balance,
                      status: status,
                      notes: notes.text.trim(),
                    ),
                  );

                  customer.clear();
                  phone.clear();
                  quantity.text = '1';
                  width.text = '0';
                  height.text = '0';
                  total.text = '0';
                  paid.text = '0';
                  notes.clear();
                  if (!mounted) return;
                  setState(() {
                    service = 'بنر';
                    status = 'جديد';
                  });
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ الطلب'),
                style: FilledButton.styleFrom(
                  backgroundColor: GhanjatApp.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 70, color: GhanjatApp.teal),
            SizedBox(height: 14),
            Text('العملاء', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('في النسخة القادمة نضيف سجل العملاء وطلباتهم السابقة.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.design_services_outlined, 'التصميمات'),
      (Icons.request_quote_outlined, 'الفواتير'),
      (Icons.payments_outlined, 'المدفوعات'),
      (Icons.bar_chart_outlined, 'التقارير'),
      (Icons.inventory_2_outlined, 'المخزون'),
      (Icons.settings_outlined, 'الإعدادات'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text('المزيد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...items.map(
            (e) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(e.$1, color: GhanjatApp.purple),
                title: Text(e.$2),
                trailing: const Icon(Icons.chevron_left),
              ),
            ),
          ),
          const Spacer(),
          const Center(
            child: Column(
              children: [
                Text('غنجات لخدمات الطباعة', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('0994482612  •  0115494130', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactChip extends StatelessWidget {
  final String number;
  const ContactChip({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.chat, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 5),
        Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
