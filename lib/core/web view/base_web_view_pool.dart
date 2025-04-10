import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class BaseWebViewPool {
  final List<WebViewController> _availableControllers = [];
  final Map<String, WebViewController> _loadedControllers = {};
  final int initialPoolSize;
  final int maxPoolSize;
  final Semaphore _semaphore;
  bool _isInitialized = false;

  BaseWebViewPool({
    required this.initialPoolSize,
    required this.maxPoolSize,
    required int concurrentLoads,
  }) : _semaphore = Semaphore(concurrentLoads);

  void initializePool() {
    if (_isInitialized) return;
    _isInitialized = true;
    for (int i = 0; i < initialPoolSize; i++) {
      final controller = _createController();
      _availableControllers.add(controller);
    }
    if (kDebugMode) {
      print('$runtimeType initialized with $initialPoolSize controllers');
    }
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    return controller;
  }

  Future<WebViewController> getController(String imageUrl) async {
    initializePool();
    await _semaphore.acquire();
    try {
      if (_loadedControllers.containsKey(imageUrl)) {
        if (kDebugMode) {
          print('$runtimeType: Reusing loaded controller for $imageUrl');
        }
        return _loadedControllers[imageUrl]!;
      }
      WebViewController controller;
      if (_availableControllers.isNotEmpty) {
        controller = _availableControllers.removeAt(0);
      } else if (_loadedControllers.length + _availableControllers.length < maxPoolSize) {
        controller = _createController();
        if (kDebugMode) {
          print('$runtimeType: Created new controller for $imageUrl. Total: ${_loadedControllers.length + _availableControllers.length + 1}');
        }
      } else {
        if (kDebugMode) {
          print('$runtimeType: Pool exhausted for $imageUrl. Waiting... Loaded: ${_loadedControllers.length}, Available: ${_availableControllers.length}');
        }
        await Future.delayed(const Duration(milliseconds: 50));
        return getController(imageUrl); // Retry
      }
      _loadedControllers[imageUrl] = controller;
      if (kDebugMode) {
        print('$runtimeType: Assigned controller for $imageUrl. Available: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
      }
      return controller;
    } catch (e) {
      _semaphore.release();
      rethrow;
    }
  }

  void releaseController(String imageUrl) {
    if (_loadedControllers.containsKey(imageUrl)) {
      final controller = _loadedControllers[imageUrl]!;
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _loadedControllers.remove(imageUrl);
      _availableControllers.add(controller);
      _semaphore.release();
      if (kDebugMode) {
        print('$runtimeType: Released controller for $imageUrl. Available: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
      }
    }
  }

  void disposeAll() {
    for (var controller in _loadedControllers.values) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _availableControllers.add(controller);
    }
    _loadedControllers.clear();
    _isInitialized = false;
    if (kDebugMode) {
      print('$runtimeType: All controllers released. Available: ${_availableControllers.length}');
    }
  }

  // Public method to check if a controller exists for an image URL
  bool hasController(String imageUrl) {
    return _loadedControllers.containsKey(imageUrl);
  }

  // Public method to get a loaded controller (nullable)
  WebViewController? getLoadedController(String imageUrl) {
    return _loadedControllers[imageUrl];
  }

  // Public method to check if a controller is in use
  bool isControllerInUse(WebViewController controller) {
    return _loadedControllers.containsValue(controller);
  }
}

class Semaphore {
  final int maxPermits;
  int _currentPermits;
  final Queue<Completer<void>> _waiters = Queue();

  Semaphore(this.maxPermits) : _currentPermits = maxPermits;

  Future<void> acquire() async {
    if (_currentPermits > 0) {
      _currentPermits--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _currentPermits++;
    }
  }
}