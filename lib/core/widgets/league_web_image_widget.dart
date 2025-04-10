import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../features/games/presentation layer/cubit/League Image Loading Cubit/league_image_loading_cubit.dart';
import '../../features/games/presentation layer/cubit/League Image Loading Cubit/league_image_loading_state.dart';


class LeagueWebViewPool {
  static final List<WebViewController> _availableControllers = [];
  static final Map<String, WebViewController> _loadedControllers = {};
  static const int _initialPoolSize = 50; // Larger pool for LeagueScreen
  static const int _maxPoolSize = 200;    // Reasonable max to avoid crashes
  static bool _isInitialized = false;

  static void initializePool() {
    if (_isInitialized) return;
    _isInitialized = true;
    for (int i = 0; i < _initialPoolSize; i++) {
      final controller = _createController();
      _availableControllers.add(controller);
    }
    print('LeagueWebViewPool initialized with $_initialPoolSize controllers');
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
    } else if (_loadedControllers.length + _availableControllers.length < _maxPoolSize) {
      controller = _createController();
      print('Created new controller for $imageUrl. Total controllers: ${_loadedControllers.length + _availableControllers.length + 1}');
    } else {
      print('League pool exhausted for $imageUrl. Waiting for release. Loaded: ${_loadedControllers.length}, Available: ${_availableControllers.length}');
      controller = _availableControllers.isNotEmpty ? _availableControllers.removeAt(0) : _createController();
    }
    _loadedControllers[imageUrl] = controller;
    print('League controller assigned for $imageUrl. Pool size: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
    return controller;
  }

  static void releaseController(String imageUrl) {
    if (_loadedControllers.containsKey(imageUrl)) {
      final controller = _loadedControllers[imageUrl]!;
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _loadedControllers.remove(imageUrl);
      _availableControllers.add(controller);
      print('League controller released for $imageUrl. Pool size: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
    }
  }

  static void disposeAll() {
    for (var controller in _loadedControllers.values) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _availableControllers.add(controller);
    }
    _loadedControllers.clear();
    print('All league controllers released. Pool size: ${_availableControllers.length}');
  }
}

class LeagueWebImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final VoidCallback onLoaded;

  const LeagueWebImageWidget({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    required this.onLoaded,
  });

  @override
  State<LeagueWebImageWidget> createState() => _LeagueWebImageWidgetState();
}

class _LeagueWebImageWidgetState extends State<LeagueWebImageWidget> with AutomaticKeepAliveClientMixin {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasStartedLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (LeagueWebViewPool._loadedControllers.containsKey(widget.imageUrl)) {
      _controller = LeagueWebViewPool._loadedControllers[widget.imageUrl];
      _isLoading = false;
      _hasStartedLoading = true;
    } else {
      context.read<LeagueImageLoadingCubit>().addImageToQueue(widget.imageUrl);
    }
  }

  void _loadImage() {
    if (!mounted || _hasStartedLoading) return;

    _controller = LeagueWebViewPool.getController(widget.imageUrl);

    _controller!.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (String url) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.read<LeagueImageLoadingCubit>().markImageAsLoaded(widget.imageUrl);
            widget.onLoaded();
          }
        },
        onWebResourceError: (WebResourceError error) {
          print('League error loading ${widget.imageUrl}: ${error.description}');
          if (mounted) {
            setState(() => _isLoading = false);
            context.read<LeagueImageLoadingCubit>().markImageAsLoaded(widget.imageUrl);
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
    print('League started loading ${widget.imageUrl}');
  }

  @override
  void dispose() {
    if (_controller != null && !LeagueWebViewPool._loadedControllers.containsValue(_controller)) {
      LeagueWebViewPool.releaseController(widget.imageUrl);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<LeagueImageLoadingCubit, LeagueImageLoadingState>(
      listener: (context, state) {
        if (state is LeagueImageLoadingInProgress && state.currentUrls.contains(widget.imageUrl) && !_hasStartedLoading) {
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