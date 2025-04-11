import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ScreenWebViewManager {
  static final Map<String, ScreenWebViewManager> _instances = {};
  final String screenKey;
  final Queue<WebViewController> _availableControllers = Queue();
  final Map<String, WebViewController> _activeControllers = {};
  final Map<WebViewController, String> _controllerToUrl = {};
  final int _maxControllers = 15;
  final Queue<Completer<WebViewController>> _controllerRequests = Queue();
  bool _isDisposed = false;

  factory ScreenWebViewManager(String screenKey) {
    return _instances.putIfAbsent(screenKey, () => ScreenWebViewManager._(screenKey));
  }

  ScreenWebViewManager._(this.screenKey) {
    _initializePool();
  }

  void _initializePool() {
    for (int i = 0; i < _maxControllers; i++) {
      _availableControllers.add(_createController());
    }
    if (kDebugMode) print('Initialized pool with $_maxControllers controllers');
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
    return controller;
  }

  Future<WebViewController> acquireController(String url) async {
    if (_isDisposed) throw Exception('ScreenWebViewManager for $screenKey is disposed');

    if (_activeControllers.containsKey(url)) {
      if (kDebugMode) print('Reusing controller for $url');
      return _activeControllers[url]!;
    }

    if (_availableControllers.isNotEmpty) {
      final controller = _availableControllers.removeFirst();
      _activeControllers[url] = controller;
      _controllerToUrl[controller] = url;
      if (kDebugMode) {
        print('Screen $screenKey: Acquired controller for $url. Active: ${_activeControllers.length}, Available: ${_availableControllers.length}');
      }
      return controller;
    } else {
      final completer = Completer<WebViewController>();
      _controllerRequests.add(completer);
      if (kDebugMode) print('Screen $screenKey: Queued request for $url. Queue size: ${_controllerRequests.length}');
      return completer.future;
    }
  }

  void releaseController(String url, WebViewController? controller) {
    if (_isDisposed || controller == null || !_activeControllers.containsKey(url)) return;

    if (_activeControllers[url] == controller) {
      _activeControllers.remove(url);
      _controllerToUrl.remove(controller);

      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));

      if (_controllerRequests.isNotEmpty) {
        final completer = _controllerRequests.removeFirst();
        completer.complete(controller);
        if (kDebugMode) print('Screen $screenKey: Reassigned controller to queued request for $url');
      } else {
        _availableControllers.add(controller);
        if (kDebugMode) {
          print('Screen $screenKey: Released $url. Active: ${_activeControllers.length}, Available: ${_availableControllers.length}');
        }
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _activeControllers.forEach((url, controller) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
    });
    _activeControllers.clear();
    _controllerToUrl.clear();

    for (var controller in _availableControllers) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
    }
    _availableControllers.clear();

    _controllerRequests.forEach((completer) => completer.completeError(Exception('Manager disposed')));
    _controllerRequests.clear();

    _instances.remove(screenKey);
    if (kDebugMode) print('Screen $screenKey: Manager disposed');
  }
}

// New WebImage widget using ScreenWebViewManager
