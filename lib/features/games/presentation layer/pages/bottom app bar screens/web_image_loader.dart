import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shimmer/shimmer.dart';

class WebImagePoolManager {
  static final WebImagePoolManager _instance = WebImagePoolManager._();
  final Queue<InAppWebViewController> _availableControllers = Queue();
  final Map<String, InAppWebViewController> _activeControllers = {};
  final Map<InAppWebViewController, String> _controllerToUrl = {};
  static const int _maxControllers = 10; // Adjust based on testing
  final Queue<Completer<InAppWebViewController>> _controllerRequests = Queue();
  bool _isDisposed = false;

  factory WebImagePoolManager() => _instance;

  WebImagePoolManager._();

  // Controllers are created via widget instances, not pre-initialized
  void registerController(InAppWebViewController controller, String url) {
    if (_isDisposed) return;
    _activeControllers[url] = controller;
    _controllerToUrl[controller] = url;
    if (kDebugMode) {
      print(
        'Registered controller for $url. Active: ${_activeControllers.length}, Available: ${_availableControllers.length}',
      );
    }
  }

  Future<InAppWebViewController> acquireController(String url) async {
    if (_isDisposed) throw Exception('WebImagePoolManager is disposed');

    if (_activeControllers.containsKey(url)) {
      if (kDebugMode) print('Reusing controller for $url');
      return _activeControllers[url]!;
    }

    if (_availableControllers.isNotEmpty) {
      final controller = _availableControllers.removeFirst();
      _activeControllers[url] = controller;
      _controllerToUrl[controller] = url;
      if (kDebugMode) {
        print(
          'Acquired controller for $url. Active: ${_activeControllers.length}, Available: ${_availableControllers.length}',
        );
      }
      return controller;
    } else if (_activeControllers.length + _availableControllers.length <
        _maxControllers) {
      // Controller will be created by the widget; return a future that waits for it
      final completer = Completer<InAppWebViewController>();
      _controllerRequests.add(completer);
      if (kDebugMode)
        print(
          'Queued request for $url. Queue size: ${_controllerRequests.length}',
        );
      return completer.future;
    } else {
      final completer = Completer<InAppWebViewController>();
      _controllerRequests.add(completer);
      if (kDebugMode)
        print(
          'Queued request for $url (pool full). Queue size: ${_controllerRequests.length}',
        );
      return completer.future;
    }
  }

  void releaseController(String url) {
    if (_isDisposed || !_activeControllers.containsKey(url)) return;

    final controller = _activeControllers.remove(url);
    if (controller != null) {
      _controllerToUrl.remove(controller);
      controller.clearCache();
      controller.loadData(data: '<html><body></body></html>');

      if (_controllerRequests.isNotEmpty) {
        final completer = _controllerRequests.removeFirst();
        completer.complete(controller);
        if (kDebugMode) print('Reassigned controller to queued request');
      } else {
        _availableControllers.add(controller);
        if (kDebugMode) {
          print(
            'Released $url. Active: ${_activeControllers.length}, Available: ${_availableControllers.length}',
          );
        }
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _activeControllers.forEach((url, controller) {
      controller.clearCache();
      controller.loadData(data: '<html><body></body></html>');
    });
    _activeControllers.clear();
    _controllerToUrl.clear();

    for (var controller in _availableControllers) {
      controller.clearCache();
      controller.loadData(data: '<html><body></body></html>');
    }
    ;
    _availableControllers.clear();

    _controllerRequests.forEach(
      (completer) => completer.completeError(Exception('Pool disposed')),
    );
    _controllerRequests.clear();

    if (kDebugMode) print('WebImagePoolManager disposed');
  }
}

class WebImageLoader extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final String uniqueKey;

  const WebImageLoader({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.uniqueKey,
  });

  @override
  State<WebImageLoader> createState() => _WebImageLoaderState();
}

class _WebImageLoaderState extends State<WebImageLoader>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  final WebImagePoolManager _poolManager = WebImagePoolManager();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  Future<void> _loadController() async {
    try {
      // Acquire a controller; it may wait for an available one or trigger widget creation
      _webViewController = await _poolManager.acquireController(
        widget.uniqueKey,
      );
      await _loadImage();
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  Future<void> _loadImage() async {
    if (_webViewController == null) return;

    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: transparent;
            overflow: hidden;
          }
          img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
          }
        </style>
      </head>
      <body>
        <img src="${widget.url}" 
             onerror="this.onerror=null;this.style.display='none';" 
             onload="this.style.opacity=1" 
             style="opacity:0;transition:opacity 0.3s">
      </body>
      </html>
    ''';

    try {
      await _webViewController!.loadData(
        data: htmlContent,
        mimeType: 'text/html',
        encoding: 'utf-8',
      );
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child:
          _hasError
              ? _buildErrorWidget()
              : _isLoading
              ? _buildShimmerLoader()
              : InAppWebView(
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                  disableVerticalScroll: true,
                  disableHorizontalScroll: true,
                  javaScriptEnabled: false,
                  supportZoom: false,
                  cacheEnabled: true,
                  userAgent:
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  _poolManager.registerController(controller, widget.uniqueKey);
                  _loadImage();
                },
                onLoadStart: (controller, url) {
                  if (mounted) setState(() => _isLoading = true);
                },
                onLoadStop: (controller, url) {
                  if (mounted)
                    setState(() {
                      _isLoading = false;
                      _hasError = false;
                    });
                },
                onLoadError: (controller, url, code, message) {
                  if (kDebugMode)
                    print('Load error for ${widget.url}: $code - $message');
                  if (mounted)
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                },
              ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.sports_soccer,
        size: widget.width * 0.5,
        color: Colors.grey[400],
      ),
    );
  }

  @override
  void dispose() {
    _poolManager.releaseController(widget.uniqueKey);
    super.dispose();
  }
}
