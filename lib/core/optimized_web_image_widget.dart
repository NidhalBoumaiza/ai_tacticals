import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shimmer/shimmer.dart';

class OptimizedWebImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;

  const OptimizedWebImageWidget({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    this.fit = BoxFit.contain,
  });

  @override
  State<OptimizedWebImageWidget> createState() => _OptimizedWebImageWidgetState();
}

class _OptimizedWebImageWidgetState extends State<OptimizedWebImageWidget> {
  late InAppWebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return _buildShimmerLoader();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          disableVerticalScroll: true,
          disableHorizontalScroll: true,
          javaScriptEnabled: false,
          supportZoom: false,
          useShouldInterceptRequest: true,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          _loadImage();
        },
        onLoadStart: (controller, url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onLoadStop: (controller, url) {
          if (mounted) setState(() => _isLoading = false);
        },
        onLoadError: (controller, url, code, message) {
          if (mounted) setState(() {
            _isLoading = false;
            _hasError = true;
          });
        },
      ),
    );
  }

  Future<void> _loadImage() async {
    try {
      await _webViewController.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(widget.imageUrl),
          headers: {
            'Cache-Control': 'max-age=3600' // Cache for 1 hour
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(widget.height / 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Icon(
        Icons.error_outline,
        size: widget.height * 0.5,
        color: Colors.grey[400],
      ),
    );
  }

  @override
  void dispose() {
    _webViewController.dispose();
    super.dispose();
  }
}