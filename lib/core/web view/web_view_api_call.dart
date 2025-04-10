import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../error/exceptions.dart';

class WebViewApiCall {
  static final List<WebViewController> _controllerPool = [];
  static const int _maxPoolSize = 10; // Limit pool size to avoid memory issues
  static bool _isPoolInitialized = false;
  static final Map<int, Completer<dynamic>> _activeRequests = {}; // Track active requests by controller hash

  WebViewApiCall() {
    _initializePool();
  }

  void _initializePool() {
    if (_isPoolInitialized) return;
    // Initialize pool asynchronously to avoid main thread blocking
    Future.microtask(() {
      for (int i = 0; i < _maxPoolSize ~/ 2; i++) { // Start with half the pool size
        _controllerPool.add(_createController());
      }
      _isPoolInitialized = true;
    });
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
    return controller;
  }

  WebViewController _getAvailableController() {
    if (_controllerPool.isNotEmpty) {
      return _controllerPool.removeAt(0);
    }
    return _createController(); // Create new if pool is empty
  }

  void _releaseController(WebViewController controller) {
    controller.clearCache();
    controller.clearLocalStorage();
    controller.loadRequest(Uri.parse('about:blank')); // Reset state
    if (_controllerPool.length < _maxPoolSize) {
      _controllerPool.add(controller);
    }
  }

  Future<dynamic> fetchJsonFromWebView(String url) async {
    final controller = _getAvailableController();
    final completer = Completer<dynamic>();
    final controllerId = controller.hashCode;

    _activeRequests[controllerId] = completer;

    // Set navigation delegate asynchronously
    await Future.microtask(() {
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (finishedUrl) async {
            if (!_activeRequests.containsKey(controllerId) || completer.isCompleted) return;

            try {
              final rawResult = await controller.runJavaScriptReturningResult(
                'document.body.innerText',
              );

              String jsonString = rawResult is String ? rawResult : rawResult.toString();
              final processedString = _processJsonString(jsonString);
              final jsonData = jsonDecode(processedString);

              completer.complete(jsonData);
            } catch (e) {
              completer.completeError(ServerException('Failed to process JSON: $e'));
            } finally {
              _activeRequests.remove(controllerId);
              _releaseController(controller);
            }
          },
          onWebResourceError: (error) {
            if (_activeRequests.containsKey(controllerId) && !completer.isCompleted) {
              completer.completeError(ServerException('WebView error: ${error.description}'));
              _activeRequests.remove(controllerId);
              _releaseController(controller);
            }
          },
        ),
      );
    });

    try {
      await controller.loadRequest(Uri.parse(url));
      return await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.completeError(ServerException('Request timed out after 35 seconds'));
            _activeRequests.remove(controllerId);
            _releaseController(controller);
          }
          throw ServerException('Request timed out after 35 seconds');
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(ServerException('Failed to load request: $e'));
        _activeRequests.remove(controllerId);
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
    _controllerPool.clear();
    _activeRequests.clear();
    _isPoolInitialized = false;
  }
}