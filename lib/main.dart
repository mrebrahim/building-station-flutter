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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a1a2e)),
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

  // ✅ رابط Lovable app - المنظر اللي عايزه
  static const String _url = 'https://building-station-mobile-hub.lovable.app/';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isConnected = result != ConnectivityResult.none);
    Connectivity().onConnectivityChanged.listen((result) {
      final connected = result != ConnectivityResult.none;
      if (connected && !_isConnected) _controller.reload();
      setState(() => _isConnected = connected);
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a1a2e))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() { _isLoading = true; _hasError = false; }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              setState(() { _isLoading = false; _hasError = true; });
            }
          },
          // ✅ السماح لكل الروابط بالفتح جوا التطبيق (WooCommerce + QiCard + كل بوابات الدفع)
          onNavigationRequest: (request) => NavigationDecision.navigate,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon.png', height: 80),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFFf5a623), strokeWidth: 3),
            const SizedBox(height: 16),
            const Text('محطة البناء', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
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
            const Text('لا يوجد اتصال بالإنترنت', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text('تحقق من اتصالك وحاول مجدداً', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
            const Text('حدث خطأ في التحميل', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () { setState(() => _hasError = false); _controller.reload(); },
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
