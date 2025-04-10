import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../features/games/presentation layer/cubit/image loading cubit/image_loading_cubit.dart';
import '../../features/games/presentation layer/cubit/image loading cubit/image_loading_state.dart';

class WebViewPool {
  static final List<WebViewController> _availableControllers = [];
  static final Map<String, WebViewController> _loadedControllers = {};
  static const int _initialPoolSize = 20; // Increased to handle more images
  static bool _isInitialized = false;

  static void initializePool() {
    if (_isInitialized) return;
    _isInitialized = true;
    for (int i = 0; i < _initialPoolSize; i++) {
      final controller = _createController();
      _availableControllers.add(controller);
    }
    print('WebViewPool initialized with $_initialPoolSize controllers');
  }

  static WebViewController _createController() {
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

  static WebViewController getController(String imageUrl) {
    initializePool();
    if (_loadedControllers.containsKey(imageUrl)) {
      return _loadedControllers[imageUrl]!;
    }
    WebViewController controller;
    if (_availableControllers.isNotEmpty) {
      controller = _availableControllers.removeAt(0);
    } else {
      controller = _createController();
    }
    _loadedControllers[imageUrl] = controller;
    print('Controller assigned for $imageUrl. Pool size: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
    return controller;
  }

  static void releaseController(String imageUrl) {
    if (_loadedControllers.containsKey(imageUrl)) {
      final controller = _loadedControllers[imageUrl]!;
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _loadedControllers.remove(imageUrl);
      _availableControllers.add(controller);
      print('Controller released for $imageUrl. Pool size: ${_availableControllers.length}');
    }
  }

  static void disposeAll() {
    for (var controller in _loadedControllers.values) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _availableControllers.add(controller);
    }
    _loadedControllers.clear();
    print('All controllers released. Pool size: ${_availableControllers.length}');
  }
}

class WebImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final VoidCallback onLoaded;

  const WebImageWidget({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    required this.onLoaded,
  });

  @override
  State<WebImageWidget> createState() => _WebImageWidgetState();
}

class _WebImageWidgetState extends State<WebImageWidget> with AutomaticKeepAliveClientMixin {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasStartedLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (WebViewPool._loadedControllers.containsKey(widget.imageUrl)) {
      _controller = WebViewPool._loadedControllers[widget.imageUrl];
      _isLoading = false;
      _hasStartedLoading = true;
    } else {
      context.read<ImageLoadingCubit>().addImageToQueue(widget.imageUrl);
    }
  }

  void _loadImage() {
    if (!mounted || _hasStartedLoading) return;

    _controller = WebViewPool.getController(widget.imageUrl);

    _controller!.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (String url) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.read<ImageLoadingCubit>().markImageAsLoaded(widget.imageUrl);
            widget.onLoaded();
          }
        },
        onWebResourceError: (WebResourceError error) {
          print('Error loading ${widget.imageUrl}: ${error.description}');
          if (mounted) {
            setState(() => _isLoading = false);
            context.read<ImageLoadingCubit>().markImageAsLoaded(widget.imageUrl);
            widget.onLoaded();
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );

    _controller!.loadRequest(Uri.parse(widget.imageUrl));
    _hasStartedLoading = true;
    print('Started loading ${widget.imageUrl}');
  }

  @override
  void dispose() {
    // Only release if not reused elsewhere
    if (_controller != null && !WebViewPool._loadedControllers.containsValue(_controller)) {
      WebViewPool.releaseController(widget.imageUrl);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<ImageLoadingCubit, ImageLoadingState>(
      listener: (context, state) {
        if (state is ImageLoadingInProgress && state.currentUrls.contains(widget.imageUrl) && !_hasStartedLoading) {
          _loadImage();
        }
      },
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_hasStartedLoading && _controller != null && !_isLoading)
              ClipOval(child: WebViewWidget(controller: _controller!)),
            if (_isLoading)
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ClipOval(
                  child: Container(
                    height: widget.height,
                    width: widget.width,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (!_isLoading && _controller == null)
              ClipOval(
                child: Image.asset(
                  'assets/placeholder.png',
                  height: widget.height,
                  width: widget.width,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}