import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebView extends StatefulWidget {
  final Future<Map<String, String>?> initialFuture;
  final Function(bool success, {String? reference}) onFinish;

  const PaymentWebView({
    super.key,
    required this.initialFuture,
    required this.onFinish,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  String? _rawUrl;
  String? _serverReference;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    try {
      final data = await widget.initialFuture;
      if (data == null) throw Exception('Could not get payment details from server');
      
      _rawUrl = data['url'];
      _serverReference = data['reference'];

      if (_rawUrl == null) throw Exception('Payment URL is missing');

      if (kIsWeb) {
        // On web: redirect the browser tab directly to Paystack checkout.
        // Paystack will redirect back to the callback_url after payment.
        final uri = Uri.parse(_rawUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
        // Pop this widget — the browser has navigated away
        if (mounted) Navigator.of(context).pop();
        return;
      }

      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw Exception(
          'In-App Payment is only fully supported on mobile devices (Android/iOS).\n\n'
          'Please continue by clicking "Open External Checkout" below.'
        );
      }
      
      if (!mounted) return;

      final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0x00000000));
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            _checkSuccess(url);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            _checkSuccess(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkSuccess(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      
      await controller.loadRequest(Uri.parse(_rawUrl!));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _checkSuccess(String url) {
    if (_isFinished) return true;
    
    // Check for Paystack success indicators or our custom callback
    if (url.contains('unipast.app/payment/callback') || 
        url.contains('paystack.com/success') ||
        url.contains('checkout.paystack.com/success')) {
      _isFinished = true;
      widget.onFinish(true, reference: _serverReference);
      return true;
    }
    return false;
  }

  Future<void> _openInExternalBrowser() async {
    if (_rawUrl != null) {
      final uri = Uri.parse(_rawUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Secure Payment',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_rawUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Open in Browser',
              onPressed: _openInExternalBrowser,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null) 
            WebViewWidget(controller: _controller!)
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    if (_rawUrl != null) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Open External Checkout'),
                        onPressed: _openInExternalBrowser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading && _error == null)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryTeal),
                    const SizedBox(height: 24),
                    Text(
                      _controller == null 
                          ? 'Waking up secure gateway...' 
                          : 'Loading checkout page...',
                      style: GoogleFonts.inter(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
