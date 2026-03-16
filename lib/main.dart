import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a2e),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isConnected = true;

  // ✅ رابط WooCommerce الخاص بك - غيّره لرابط موقعك
  static const String _url = 'https://building-station.com/';

  // ✅ دومينات مسموح الـ WebView يفتحها (موقعك + بوابات الدفع)
  static const List<String> _allowedDomains = [
    'building-station.com',
    // QiCard domains
    'qicard.com',
    'payment.qicard.com',
    'gateway.qicard.com',
    'pg.qicard.com',
    // WooCommerce & WordPress
    'woocommerce.com',
    // PayPal (احتياطي)
    'paypal.com',
    'www.paypal.com',
    'paypal.me',
    // Stripe (احتياطي)
    'stripe.com',
    'js.stripe.com',
    // 3D Secure banks
    'mastercard.com',
    'visa.com',
    '3dsecure.io',
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
    Connectivity().onConnectivityChanged.listen((result) {
      final connected = result != ConnectivityResult.none;
      if (connected && !_isConnected) _controller.reload();
      setState(() => _isConnected = connected);
    });
  }

  bool _isDomainAllowed(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      for (final domain in _allowedDomains) {
        if (host == domain || host.endsWith('.$domain')) return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a1a2e))
      // ✅ مهم جداً للدفع
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // تجاهل أخطاء الـ subresources
            if (error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // ✅ السماح لكل روابط الدفع والموقع
            if (_isDomainAllowed(url)) {
              return NavigationDecision.navigate;
            }

            // ✅ السماح لـ about:blank و data: URLs
            if (url.startsWith('about:') || url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }

            // ✅ السماح لـ intent:// و market:// للتطبيقات
            if (url.startsWith('intent://') || url.startsWith('market://')) {
              return NavigationDecision.navigate;
            }

            // ✅ السماح لأي HTTPS بشكل عام عشان الدفع
            if (url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          _controller.goBack();
        } else {
          if (context.mounted) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: SafeArea(
          child: Stack(
            children: [
              if (!_isConnected)
                _buildNoInternetWidget()
              else if (_hasError)
                _buildErrorWidget()
              else
                WebViewWidget(controller: _controller),
              if (_isLoading && !_hasError && _isConnected)
                _buildLoadingWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFf5a623), strokeWidth: 3),
            SizedBox(height: 20),
            Text(
              'محطة البناء',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 64),
            const SizedBox(height: 20),
            const Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            const Text(
              'تحقق من اتصالك وحاول مجدداً',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await _checkConnectivity();
                if (_isConnected) _controller.reload();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf5a623),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            const Text(
              'حدث خطأ في التحميل',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasError = false);
                _controller.reload();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة التحميل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf5a623),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
