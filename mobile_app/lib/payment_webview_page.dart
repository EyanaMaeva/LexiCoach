import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_colors.dart';

const _logTag = '[Payment]';

/// Opens a payment checkout page in an in-app WebView and pops with
/// `true`/`false` as soon as the page navigates to [successUrlPrefix] or
/// [cancelUrlPrefix]. This is only a UX hint: the caller must still confirm
/// the payment server-side (webhook), the redirect alone proves nothing.
class PaymentWebViewPage extends StatefulWidget {
  const PaymentWebViewPage({
    super.key,
    required this.checkoutUrl,
    required this.successUrlPrefix,
    required this.cancelUrlPrefix,
  });

  final String checkoutUrl;
  final String successUrlPrefix;
  final String cancelUrlPrefix;

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    debugPrint('$_logTag PaymentWebViewPage: loading checkout_url=${widget.checkoutUrl}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('$_logTag PaymentWebViewPage: onPageStarted url=$url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('$_logTag PaymentWebViewPage: onPageFinished url=$url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint(
              '$_logTag PaymentWebViewPage: onWebResourceError code=${error.errorCode} '
              'description=${error.description} url=${error.url}',
            );
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.successUrlPrefix)) {
              debugPrint('$_logTag PaymentWebViewPage: success redirect detected url=${request.url}');
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith(widget.cancelUrlPrefix)) {
              debugPrint('$_logTag PaymentWebViewPage: cancel redirect detected url=${request.url}');
              _finish(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _finish(bool success) {
    if (_hasFinished || !mounted) return;
    _hasFinished = true;
    debugPrint('$_logTag PaymentWebViewPage: closing webview, success=$success');
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Paiement sécurisé',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
            onPressed: () => _finish(false),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
