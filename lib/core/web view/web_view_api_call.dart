import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../error/exceptions.dart';
import 'dart:async';

class WebViewApiCall {
  final WebViewController _webViewController;
  Completer<dynamic>? _currentCompleter;
  bool _isProcessing = false;

  WebViewApiCall() : _webViewController = WebViewController() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (finishedUrl) async {
            if (_currentCompleter == null || _currentCompleter!.isCompleted) {
              return;
            }

            try {
              // Get raw JSON string from WebView
              final rawResult = await _webViewController.runJavaScriptReturningResult(
                'document.body.innerText',
              );

              String jsonString;
              if (rawResult is String) {
                jsonString = rawResult;
              } else {
                jsonString = rawResult.toString();
              }

              // Process the JSON string
              final processedString = _processJsonString(jsonString);

              // Parse the JSON
              final jsonData = jsonDecode(processedString);

              _currentCompleter!.complete(jsonData);
            } catch (e, stackTrace) {
              _currentCompleter!.completeError(
                ServerException('Failed to process JSON: $e'),
              );
            } finally {
              _isProcessing = false;
              _currentCompleter = null;
            }
          },
          onWebResourceError: (error) {
            if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
              _currentCompleter!.completeError(
                ServerException('WebView error: ${error.description}'),
              );
              _isProcessing = false;
              _currentCompleter = null;
            }
          },
        ),
      );
  }

  String _processJsonString(String jsonString) {
    // Step 1: Remove surrounding quotes if present
    jsonString = jsonString.trim();
    if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
      jsonString = jsonString.substring(1, jsonString.length - 1);
    }

    // Step 2: Unescape the string (convert \" to ")
    jsonString = jsonString.replaceAll(r'\"', '"');

    // Step 3: Convert all Unicode escape sequences to actual characters
    // This handles both \uXXXX and \\uXXXX cases
    jsonString = jsonString.replaceAllMapped(
      RegExp(r'(\\+u)([0-9a-fA-F]{4})'),
          (Match m) {
        // If there was an odd number of backslashes, convert to character
        if (m.group(1)!.length.isOdd) {
          return String.fromCharCode(int.parse(m.group(2)!, radix: 16));
        }
        // Even number of backslashes means it's a literal backslash followed by u
        return '${'\\' * (m.group(1)!.length - 1)}u${m.group(2)}';
      },
    );

    // Step 4: Handle any remaining escape sequences
    jsonString = jsonString.replaceAll(r'\\', r'\');

    return jsonString;
  }

  Future<dynamic> fetchJsonFromWebView(String url) async {
    if (_isProcessing) {
      throw ServerException('WebView is busy with another request');
    }

    _isProcessing = true;
    _currentCompleter = Completer<dynamic>();

    try {
      await _webViewController.loadRequest(Uri.parse(url));
      return await _currentCompleter!.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          if (!_currentCompleter!.isCompleted) {
            _currentCompleter!.completeError(
              ServerException('Request timed out after 30 seconds'),
            );
          }
          throw ServerException('Request timed out after 30 seconds');
        },
      );
    } catch (e, stackTrace) {
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.completeError(
          ServerException('Failed to load request: $e'),
        );
      }
      rethrow;
    } finally {
      if (_currentCompleter != null && _currentCompleter!.isCompleted) {
        _isProcessing = false;
        _currentCompleter = null;
      }
    }
  }
}

// import 'dart:convert';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../error/exceptions.dart';
// import 'dart:async';
//
// class WebViewApiCall {
//   final WebViewController _webViewController;
//   Completer<dynamic>? _currentCompleter;
//   bool _isProcessing = false;
//
//   WebViewApiCall() : _webViewController = WebViewController() {
//     _webViewController
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (finishedUrl) async {
//             print('WebViewApiCall: onPageFinished triggered for: $finishedUrl');
//             if (_currentCompleter == null || _currentCompleter!.isCompleted) {
//               print('WebViewApiCall: No active completer, ignoring onPageFinished');
//               return;
//             }
//
//             try {
//               print('WebViewApiCall: Attempting to fetch innerText');
//               String jsonString = await _webViewController.runJavaScriptReturningResult(
//                 'document.body.innerText',
//               ) as String;
//               print('WebViewApiCall: Raw jsonString: $jsonString');
//
//               // Clean the JSON string
//               jsonString = jsonString.trim();
//               if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
//                 jsonString = jsonString.substring(1, jsonString.length - 1);
//               }
//               jsonString = jsonString.replaceAll('\\"', '"');
//               print('WebViewApiCall: Cleaned jsonString: $jsonString');
//
//               // Ensure UTF-8 decoding
//               final utf8Decoder = Utf8Decoder(allowMalformed: true);
//               final decodedString = utf8Decoder.convert(jsonString.codeUnits);
//               print('WebViewApiCall: Decoded jsonString: $decodedString');
//
//               final jsonData = jsonDecode(decodedString);
//               print('WebViewApiCall: Parsed jsonData: $jsonData');
//
//               _currentCompleter!.complete(jsonData);
//             } catch (e, stackTrace) {
//               print('WebViewApiCall: Error in onPageFinished: $e');
//               print('WebViewApiCall: Stack trace: $stackTrace');
//               _currentCompleter!.completeError(ServerException('Failed to fetch data from WebView: $e'));
//             } finally {
//               print('WebViewApiCall: Resetting state in finally');
//               _isProcessing = false;
//               _currentCompleter = null;
//             }
//           },
//           onWebResourceError: (error) {
//             print('WebViewApiCall: onWebResourceError: ${error.description}');
//             if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
//               _currentCompleter!.completeError(ServerException('WebView error: ${error.description}'));
//               _isProcessing = false;
//               _currentCompleter = null;
//             }
//           },
//         ),
//       );
//   }
//
//   Future<dynamic> fetchJsonFromWebView(String url) async {
//     print('WebViewApiCall: Starting fetchJsonFromWebView for URL: $url');
//
//     if (_isProcessing) {
//       print('WebViewApiCall: Already processing a request, rejecting new one');
//       throw ServerException('WebView is busy with another request');
//     }
//
//     _isProcessing = true;
//     _currentCompleter = Completer<dynamic>();
//
//     try {
//       print('WebViewApiCall: Loading request for URL: $url');
//       await _webViewController.loadRequest(Uri.parse(url));
//
//       print('WebViewApiCall: Waiting for response with 12-second timeout');
//       return await _currentCompleter!.future.timeout(
//         const Duration(seconds: 30),
//         onTimeout: () {
//           print('WebViewApiCall: Timeout after 12 seconds');
//           if (!_currentCompleter!.isCompleted) {
//             _currentCompleter!.completeError(ServerException('Request timed out after 12 seconds'));
//           }
//           throw ServerException('Request timed out after 12 seconds');
//         },
//       );
//     } catch (e) {
//       print('WebViewApiCall: Error in fetchJsonFromWebView: $e');
//       if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
//         _currentCompleter!.completeError(ServerException('Failed to load request: $e'));
//       }
//       rethrow;
//     } finally {
//       if (_currentCompleter != null && _currentCompleter!.isCompleted) {
//         _isProcessing = false;
//         _currentCompleter = null;
//       }
//     }
//   }
// }