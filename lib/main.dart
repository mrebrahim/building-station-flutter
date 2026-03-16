import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ============================================================
// WooCommerce Config
// ============================================================
const String kBaseUrl = 'https://building-station.com';
const String kConsumerKey = 'ck_1229137c2d3053518c465a85c654ab191afd3529';
const String kConsumerSecret = 'cs_a53fe9e55c493db928d949614ee6c01d213c89a0';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BuildingStationApp());
}

class BuildingStationApp extends StatelessWidget {
  const BuildingStationApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محطة البناء',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a1a2e)),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      home: const MainScreen(),
    );
  }
}

// ============================================================
// Main Screen with Bottom Nav
// ============================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF1a1a2e),
        indicatorColor: const Color(0xFFf5a623),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.shopping_cart, color: Colors.white),
            label: 'السلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.white),
            label: 'طلباتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WooCommerce API Service
// ============================================================
class WooService {
  static String _auth() {
    final credentials = base64Encode(utf8.encode('$kConsumerKey:$kConsumerSecret'));
    return 'Basic $credentials';
  }

  static Future<List<dynamic>> getProducts({int page = 1, int perPage = 20}) async {
    final uri = Uri.parse('$kBaseUrl/wp-json/wc/v3/products?per_page=$perPage&page=$page&status=publish');
    final res = await http.get(uri, headers: {'Authorization': _auth()});
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getCategories() async {
    final uri = Uri.parse('$kBaseUrl/wp-json/wc/v3/products/categories?per_page=20&hide_empty=true');
    final res = await http.get(uri, headers: {'Authorization': _auth()});
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>?> createOrder(Map<String, dynamic> orderData) async {
    final uri = Uri.parse('$kBaseUrl/wp-json/wc/v3/orders');
    final res = await http.post(
      uri,
      headers: {'Authorization': _auth(), 'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    return null;
  }

  static Future<List<dynamic>> getOrders(String email) async {
    final uri = Uri.parse('$kBaseUrl/wp-json/wc/v3/orders?search=$email&per_page=20');
    final res = await http.get(uri, headers: {'Authorization': _auth()});
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }
}

// ============================================================
// Cart Manager (in-memory)
// ============================================================
class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> items = [];

  void add(Map<String, dynamic> product, int qty) {
    final idx = items.indexWhere((i) => i['id'] == product['id']);
    if (idx >= 0) {
      items[idx]['qty'] += qty;
    } else {
      items.add({...product, 'qty': qty});
    }
  }

  void remove(int productId) => items.removeWhere((i) => i['id'] == productId);

  double get total => items.fold(0, (sum, i) => sum + (double.tryParse(i['price'].toString()) ?? 0) * (i['qty'] as int));

  int get count => items.fold(0, (sum, i) => sum + (i['qty'] as int));
}

// ============================================================
// Home Screen
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await WooService.getProducts();
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Image.asset('assets/icon.png', height: 36),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFf5a623)))
          : _products.isEmpty
              ? const Center(
                  child: Text('لا توجد منتجات', style: TextStyle(color: Colors.white70)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) => ProductCard(product: _products[i]),
                  ),
                ),
    );
  }
}

// ============================================================
// Product Card
// ============================================================
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['images']?.isNotEmpty == true ? product['images'][0]['src'] : '';
    final name = product['name'] ?? '';
    final price = product['price'] ?? '0';
    final regularPrice = product['regular_price'] ?? '';
    final onSale = product['on_sale'] == true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover)
                  : Container(height: 130, color: Colors.grey[800],
                      child: const Icon(Icons.image, color: Colors.white30, size: 40)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$price IQD', style: const TextStyle(color: Color(0xFFf5a623), fontWeight: FontWeight.bold, fontSize: 13)),
                      if (onSale && regularPrice.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(regularPrice, style: const TextStyle(color: Colors.white30, fontSize: 10,
                            decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        CartManager().add(product, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ أضيف للسلة'), duration: Duration(seconds: 1),
                              backgroundColor: Color(0xFFf5a623)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf5a623),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('أضف للسلة', style: TextStyle(fontSize: 11)),
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
}

// ============================================================
// Product Detail Screen
// ============================================================
class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['images']?.isNotEmpty == true ? product['images'][0]['src'] : '';
    final name = product['name'] ?? '';
    final price = product['price'] ?? '0';
    final description = product['short_description'] ?? product['description'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, width: double.infinity, height: 280, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$price IQD', style: const TextStyle(color: Color(0xFFf5a623), fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty)
                    Text(description.replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        CartManager().add(product, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ أضيف للسلة'), backgroundColor: Color(0xFFf5a623)),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('أضف للسلة', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf5a623),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
}

// ============================================================
// Cart Screen
// ============================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('السلة', style: TextStyle(color: Colors.white)),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('السلة فارغة', style: TextStyle(color: Colors.white70, fontSize: 16)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      final imageUrl = item['images']?.isNotEmpty == true ? item['images'][0]['src'] : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a2e),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  Text('${item['price']} IQD', style: const TextStyle(color: Color(0xFFf5a623))),
                                  Text('الكمية: ${item['qty']}', style: const TextStyle(color: Colors.white54)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => setState(() => cart.remove(item['id'])),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1a1a2e),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي:', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text('${cart.total.toStringAsFixed(0)} IQD',
                              style: const TextStyle(color: Color(0xFFf5a623), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          ).then((_) => setState(() {})),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFf5a623),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إتمام الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// Checkout Screen - QiCard Payment via WebView
// ============================================================
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loading = false;

  Future<void> _placeOrder() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);

    final cart = CartManager();
    final nameParts = _nameController.text.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final orderData = {
      'payment_method': 'qicard',
      'payment_method_title': 'QiCard',
      'set_paid': false,
      'billing': {
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address_1': _addressController.text,
        'country': 'IQ',
      },
      'line_items': cart.items.map((item) => {
        'product_id': item['id'],
        'quantity': item['qty'],
      }).toList(),
    };

    final order = await WooService.createOrder(orderData);
    setState(() => _loading = false);

    if (order != null) {
      final paymentUrl = order['payment_url'] ?? '$kBaseUrl/checkout/order-pay/${order['id']}/?pay_for_order=true&key=${order['order_key']}';
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              paymentUrl: paymentUrl,
              orderId: order['id'].toString(),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في إنشاء الطلب'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('إتمام الطلب', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات الشحن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildField(_nameController, 'الاسم الكامل', Icons.person),
            _buildField(_emailController, 'البريد الإلكتروني', Icons.email),
            _buildField(_phoneController, 'رقم الهاتف', Icons.phone),
            _buildField(_addressController, 'العنوان', Icons.location_on),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: Color(0xFFf5a623), size: 32),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QiCard Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('الدفع ببطاقة QiCard', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('محدد', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf5a623),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('ادفع الآن بـ QiCard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: const Color(0xFFf5a623)),
          filled: true,
          fillColor: const Color(0xFF1a1a2e),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ============================================================
// Payment WebView Screen (QiCard)
// ============================================================
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  const PaymentWebViewScreen({super.key, required this.paymentUrl, required this.orderId});
  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (url) {
          setState(() => _isLoading = false);
          // ✅ لو الدفع اكتمل ورجع لصفحة thank-you
          if (url.contains('order-received') || url.contains('thank-you')) {
            CartManager().items.clear();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF1a1a2e),
                title: const Text('✅ تم الدفع', style: TextStyle(color: Colors.white)),
                content: Text('تم استلام طلبك #${widget.orderId} بنجاح!',
                    style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('حسناً', style: TextStyle(color: Color(0xFFf5a623))),
                  ),
                ],
              ),
            );
          }
        },
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('الدفع بـ QiCard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFf5a623))),
        ],
      ),
    );
  }
}

// ============================================================
// Orders Screen
// ============================================================
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _emailController = TextEditingController();
  List<dynamic> _orders = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _search() async {
    setState(() { _loading = true; _searched = true; });
    final orders = await WooService.getOrders(_emailController.text);
    setState(() { _orders = orders; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('طلباتي', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ادخل بريدك الإلكتروني',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1a1a2e),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFFf5a623)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf5a623),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('بحث'),
                ),
              ],
            ),
          ),
          if (_loading) const CircularProgressIndicator(color: Color(0xFFf5a623)),
          if (_searched && !_loading && _orders.isEmpty)
            const Text('لا توجد طلبات', style: TextStyle(color: Colors.white54)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _orders.length,
              itemBuilder: (ctx, i) {
                final order = _orders[i];
                final status = order['status'] ?? '';
                final statusColor = status == 'completed' ? Colors.green
                    : status == 'processing' ? Colors.blue
                    : status == 'pending' ? Colors.orange
                    : Colors.grey;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('طلب #${order['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('${order['total']} IQD', style: const TextStyle(color: Color(0xFFf5a623))),
                          Text(order['date_created']?.toString().substring(0, 10) ?? '',
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Account Screen
// ============================================================
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('حسابي', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon.png', height: 80),
            const SizedBox(height: 20),
            const Text('محطة البناء', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('متجر مواد البناء', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFFf5a623)),
              title: const Text('تواصل معنا', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFf5a623)),
              title: const Text('عن التطبيق', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
