import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BaseWebViewPool {
  final int initialPoolSize;
  final int maxPoolSize;
  final int concurrentLoads;
  final Queue<WebViewController> _availableControllers = Queue();
  final Map<String, WebViewController> _loadedControllers = {};
  final Map<WebViewController, String> _controllerToUrl = {};
  final Queue<Completer<WebViewController>> _controllerRequests = Queue();
  bool _isDisposed = false;

  BaseWebViewPool({
    required this.initialPoolSize,
    required this.maxPoolSize,
    required this.concurrentLoads,
  }) {
    _initializePool();
  }

  void _initializePool() {
    for (int i = 0; i < initialPoolSize; i++) {
      _availableControllers.add(_createController());
    }
    if (kDebugMode) print('Pool initialized with $initialPoolSize controllers');
  }

  WebViewController _createController() {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.disabled)
          ..setBackgroundColor(Colors.transparent)
          ..setUserAgent(
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
          );
    return controller;
  }

  Future<WebViewController> getController(String url) async {
    if (_isDisposed) throw Exception('WebViewPool is disposed');

    if (_loadedControllers.containsKey(url)) {
      if (kDebugMode) print('Reusing loaded controller for $url');
      return _loadedControllers[url]!;
    }

    if (_availableControllers.isNotEmpty) {
      final controller = _availableControllers.removeFirst();
      await _loadUrl(controller, url);
      _loadedControllers[url] = controller;
      _controllerToUrl[controller] = url;
      if (kDebugMode) {
        print(
          'Acquired controller for $url. Loaded: ${_loadedControllers.length}, Available: ${_availableControllers.length}',
        );
      }
      return controller;
    } else if (_loadedControllers.length + _availableControllers.length <
        maxPoolSize) {
      final controller = _createController();
      await _loadUrl(controller, url);
      _loadedControllers[url] = controller;
      _controllerToUrl[controller] = url;
      if (kDebugMode) {
        print(
          'Created new controller for $url. Loaded: ${_loadedControllers.length}, Available: ${_availableControllers.length}',
        );
      }
      return controller;
    } else {
      final completer = Completer<WebViewController>();
      _controllerRequests.add(completer);
      if (kDebugMode)
        print(
          'Queued request for $url. Queue size: ${_controllerRequests.length}',
        );
      return completer.future;
    }
  }

  Future<void> _loadUrl(WebViewController controller, String url) async {
    await controller.loadRequest(Uri.parse(url));
  }

  void releaseController(String url) {
    if (_isDisposed || !_loadedControllers.containsKey(url)) return;

    final controller = _loadedControllers.remove(url);
    if (controller != null) {
      _controllerToUrl.remove(controller);
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));

      if (_controllerRequests.isNotEmpty) {
        final completer = _controllerRequests.removeFirst();
        completer.complete(controller);
        if (kDebugMode) print('Reassigned controller to queued request');
      } else {
        _availableControllers.add(controller);
        if (kDebugMode) {
          print(
            'Released $url. Loaded: ${_loadedControllers.length}, Available: ${_availableControllers.length}',
          );
        }
      }
    }
  }

  bool hasController(String url) => _loadedControllers.containsKey(url);

  WebViewController? getLoadedController(String url) => _loadedControllers[url];

  bool isControllerInUse(WebViewController controller) =>
      _controllerToUrl.containsKey(controller);

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _loadedControllers.forEach((url, controller) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
    });
    _loadedControllers.clear();
    _controllerToUrl.clear();

    for (var controller in _availableControllers) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
    }
    ;
    _availableControllers.clear();

    _controllerRequests.forEach(
      (completer) => completer.completeError(Exception('Pool disposed')),
    );
    _controllerRequests.clear();

    if (kDebugMode) print('WebViewPool disposed');
  }
}
