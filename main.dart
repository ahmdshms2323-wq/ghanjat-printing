import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
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
      home: const HomePage(),
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

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const List<ServiceData> services = <ServiceData>[
    ServiceData(
      name: 'بزنس كارد',
      icon: Icons.badge_outlined,
      description:
          'طباعة بزنس كارد احترافي. كل حزمة تحتوي على 100 كرت.',
      unit: 'حزمة 100 كرت',
      price: 30000,
      isBusinessCard: true,
      isCardPack: true,
    ),
    ServiceData(
      name: 'استيكرات منتجات',
      icon: Icons.label_outline,
      description:
          'طباعة استيكرات للمنتجات والعبوات والمشاريع التجارية.',
      unit: 'متر',
      price: 40000,
    ),
    ServiceData(
      name: 'أكياس بلاستيك',
      icon: Icons.shopping_bag_outlined,
      description:
          'طباعة أكياس بلاستيك للمحلات والمشاريع التجارية.',
      unit: 'كيلو',
      price: 25000,
    ),
    ServiceData(
      name: 'أكياس قماش',
      icon: Icons.shopping_bag,
      description:
          'طباعة أكياس قماش للمحلات والمشاريع مع إمكانية إضافة الشعار.',
      unit: 'كيلو',
      price: 80000,
    ),
    ServiceData(
      name: 'لوحات إعلانية',
      icon: Icons.campaign_outlined,
      description:
          'تصميم وتنفيذ اللوحات الإعلانية للمحلات والشركات والمناسبات.',
      unit: 'متر',
      price: 35000,
    ),
    ServiceData(
      name: 'كروت الفال',
      icon: Icons.card_giftcard_outlined,
      description:
          'طباعة كروت الفال للمناسبات. كل حزمة تحتوي على 100 كرت.',
      unit: 'حزمة 100 كرت',
      price: 70000,
      isCardPack: true,
    ),
  ];

  void openService(
    BuildContext context,
    ServiceData service,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: ServicePage(service: service),
          );
        },
      ),
    );
  }

  Widget serviceButton(
    BuildContext context,
    ServiceData service,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 75,
        child: ElevatedButton(
          onPressed: () {
            openService(context, service);
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
                service.icon,
                size: 30,
                color: GhanjatApp.turquoise,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      service.isBusinessCard
                          ? '100 كرت من 30,000 جنيه'
                          : '${money(service.price)} جنيه / ${service.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
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

  static String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  Widget contactNumber(String number) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.greenAccent,
            size: 26,
          ),
          const SizedBox(width: 10),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
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
        appBar: AppBar(
          backgroundColor: GhanjatApp.purple,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'غنجات للطباعة',
            style: TextStyle(fontSize: 23),
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
                    vertical: 32,
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
                      SizedBox(height: 12),
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
                const SizedBox(height: 28),
                const Text(
                  'خدماتنا',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...services.map(
                  (ServiceData service) =>
                      serviceButton(context, service),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: GhanjatApp.purple,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'تواصل معنا',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 17),
                      contactNumber('0115494130'),
                      const SizedBox(height: 12),
                      contactNumber('0994482612'),
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

class ServicePage extends StatefulWidget {
  final ServiceData service;

  const ServicePage({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController customerController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController(text: '1');

  final TextEditingController sizeController =
      TextEditingController();

  final TextEditingController paidController =
      TextEditingController(text: '0');

  final TextEditingController notesController =
      TextEditingController();

  String businessSide = 'اتجاه واحد';

  double get quantity {
    return double.tryParse(quantityController.text) ?? 0;
  }

  double get paid {
    return double.tryParse(paidController.text) ?? 0;
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
    if (quantity <= 0) {
      return 0;
    }

    return quantity * unitPrice;
  }

  double get remaining {
    if (paid >= total) {
      return 0;
    }

    return total - paid;
  }

  String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  String quantityText() {
    if (widget.service.isCardPack) {
      final int cards = (quantity * 100).round();

      return '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} حزمة = $cards كرت';
    }

    return '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2)} ${widget.service.unit}';
  }

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

    String extra = '';

    if (widget.service.isBusinessCard) {
      extra = '\nنوع الطباعة: $businessSide';
    }

    final String size = sizeController.text.trim().isEmpty
        ? 'غير محدد'
        : sizeController.text.trim();

    final String notes = notesController.text.trim().isEmpty
        ? 'لا توجد'
        : notesController.text.trim();

    final String message =
        'طلب جديد - غنجات للطباعة\n\n'
        'الخدمة: ${widget.service.name}'
        '$extra\n'
        'اسم العميل: ${customerController.text.trim()}\n'
        'رقم العميل: ${phoneController.text.trim()}\n'
        'الكمية: ${quantityText()}\n'
        'المقاس / التفاصيل: $size\n'
        'سعر الوحدة: ${money(unitPrice)} جنيه\n'
        'الإجمالي: ${money(total)} جنيه\n'
        'المدفوع: ${money(paid)} جنيه\n'
        'المتبقي: ${money(remaining)} جنيه\n'
        'الملاحظات: $notes';

    final Uri uri = Uri.parse(
      'https://wa.me/$internationalNumber?text=${Uri.encodeComponent(message)}',
    );

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      if (context.mounted) {
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
  }

  void selectWhatsAppNumber(BuildContext context) {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أدخل الكمية أولاً',
            textAlign: TextAlign.center,
          ),
        ),
      );

      return;
    }

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
                  'إرسال الطلب إلى',
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
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(sheetContext).pop();

          openWhatsApp(
            pageContext,
            number,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
          size: 24,
        ),
        label: Text(
          number,
          style: const TextStyle(
            fontSize: 21,
          ),
        ),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: isRequired
          ? (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال $label';
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

  Widget priceRow(
    String title,
    String value, {
    bool important = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: important ? 18 : 16,
              fontWeight: important
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: important ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: important
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
    sizeController.dispose();
    paidController.dispose();
    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String quantityLabel;

    if (widget.service.isCardPack) {
      quantityLabel = 'عدد الحزم - كل حزمة 100 كرت';
    } else {
      quantityLabel = 'الكمية بـ ${widget.service.unit}';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GhanjatApp.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(widget.service.name),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 115,
                    height: 115,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      widget.service.icon,
                      size: 58,
                      color: GhanjatApp.turquoise,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.service.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.service.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),

                if (widget.service.isBusinessCard)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'اختار نوع الطباعة',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'السعر',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${money(unitPrice)} جنيه / ${widget.service.unit}',
                          style: const TextStyle(
                            color: GhanjatApp.purple,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

                inputField(
                  controller: customerController,
                  label: 'اسم العميل',
                  icon: Icons.person_outline,
                  isRequired: true,
                ),

                const SizedBox(height: 12),

                inputField(
                  controller: phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                ),

                const SizedBox(height: 12),

                inputField(
                  controller: quantityController,
                  label: quantityLabel,
                  icon: Icons.numbers,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  isRequired: true,
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 12),

                inputField(
                  controller: sizeController,
                  label: 'المقاس / تفاصيل إضافية',
                  icon: Icons.straighten,
                ),

                const SizedBox(height: 12),

                inputField(
                  controller: paidController,
                  label: 'المبلغ المدفوع',
                  icon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: <Widget>[
                      priceRow(
                        'الكمية',
                        quantityText(),
                      ),
                      priceRow(
                        'سعر الوحدة',
                        '${money(unitPrice)} جنيه',
                      ),
                      const Divider(),
                      priceRow(
                        'الإجمالي',
                        '${money(total)} جنيه',
                        important: true,
                      ),
                      priceRow(
                        'المدفوع',
                        '${money(paid)} جنيه',
                      ),
                      priceRow(
                        'المتبقي',
                        '${money(remaining)} جنيه',
                        important: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      selectWhatsAppNumber(context);
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
                      size: 27,
                    ),
                    label: const Text(
                      'إرسال الطلب عبر واتساب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
