import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../error/exceptions.dart';

class WebViewApiCall {
  static final List<WebViewController> _controllerPool = [];
  static const int _initialPoolSize = 3; // Start small
  static const int _maxPoolSize = 8;    // Reasonable cap for mobile
  static final Semaphore _semaphore = Semaphore(5); // Limit concurrent requests
  static bool _isPoolInitialized = false;
  static final Queue<WebViewController> _cleanupQueue = Queue();

  WebViewApiCall() {
    _initializePool();
  }

  void _initializePool() {
    if (_isPoolInitialized) return;
    Future.microtask(() {
      for (int i = 0; i < _initialPoolSize; i++) {
        _controllerPool.add(_createController());
      }
      _isPoolInitialized = true;
      if (kDebugMode) {
        print('WebView pool initialized with $_initialPoolSize controllers');
      }
    });
  }

  static WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
    return controller;
  }

  Future<WebViewController> _getController() async {
    await _semaphore.acquire();
    try {
      if (_controllerPool.isNotEmpty) {
        return _controllerPool.removeLast();
      } else if (_controllerPool.length + _cleanupQueue.length < _maxPoolSize) {
        final controller = _createController();
        if (kDebugMode) {
          print('Created new controller. Total: ${_controllerPool.length + _cleanupQueue.length + 1}');
        }
        return controller;
      } else if (_cleanupQueue.isNotEmpty) {
        return _cleanupQueue.removeFirst();
      } else {
        if (kDebugMode) {
          print('Pool exhausted. Waiting for a controller.');
        }
        await Future.delayed(const Duration(milliseconds: 100)); // Small delay to wait for release
        return _getController(); // Retry
      }
    } catch (e) {
      _semaphore.release();
      rethrow;
    }
  }

  void _releaseController(WebViewController controller) {
    controller.clearCache();
    controller.clearLocalStorage();
    controller.loadRequest(Uri.parse('about:blank'));
    _cleanupQueue.add(controller);
    if (_cleanupQueue.length > 2) { // Keep a small buffer
      _cleanupQueue.removeFirst();
    }
    _semaphore.release();
    if (kDebugMode) {
      print('Controller released. Pool: ${_controllerPool.length}, Cleanup: ${_cleanupQueue.length}');
    }
  }

  Future<dynamic> fetchJsonFromWebView(String url) async {
    final controller = await _getController();
    final completer = Completer<dynamic>();

    try {
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (finishedUrl) async {
            if (completer.isCompleted) return;
            try {
              final rawResult = await controller.runJavaScriptReturningResult('document.body.innerText');
              String jsonString = rawResult is String ? rawResult : rawResult.toString();
              final processedString = _processJsonString(jsonString);
              final jsonData = jsonDecode(processedString);
              if (!completer.isCompleted) {
                completer.complete(jsonData);
              }
            } catch (e) {
              if (!completer.isCompleted) {
                completer.completeError(ServerException('Failed to process JSON: $e'));
              }
            } finally {
              _releaseController(controller);
            }
          },
          onWebResourceError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(ServerException('WebView error: ${error.description}'));
              _releaseController(controller);
            }
          },
        ),
      );

      await controller.loadRequest(Uri.parse(url));
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.completeError(ServerException('Request timed out after 30 seconds'));
            _releaseController(controller);
          }
          throw ServerException('Request timed out after 30 seconds');
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(ServerException('Failed to load request: $e'));
        _releaseController(controller);
      }
      rethrow;
    }
  }

  String _processJsonString(String jsonString) {
    jsonString = jsonString.trim();
    if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
      jsonString = jsonString.substring(1, jsonString.length - 1);
    }
    jsonString = jsonString.replaceAll(r'\"', '"');
    jsonString = jsonString.replaceAllMapped(
      RegExp(r'(\\+u)([0-9a-fA-F]{4})'),
          (Match m) {
        if (m.group(1)!.length.isOdd) {
          return String.fromCharCode(int.parse(m.group(2)!, radix: 16));
        }
        return '${'\\' * (m.group(1)!.length - 1)}u${m.group(2)}';
      },
    );
    jsonString = jsonString.replaceAll(r'\\', r'\');
    return jsonString;
  }

  void disposePool() {
    for (var controller in _controllerPool) {
      controller.clearCache();
      controller.clearLocalStorage();
      controller.loadRequest(Uri.parse('about:blank'));
    }
    for (var controller in _cleanupQueue) {
      controller.clearCache();
      controller.clearLocalStorage();
      controller.loadRequest(Uri.parse('about:blank'));
    }
    _controllerPool.clear();
    _cleanupQueue.clear();
    _isPoolInitialized = false;
    if (kDebugMode) {
      print('WebView pool disposed');
    }
  }
}

// Simple Semaphore implementation
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