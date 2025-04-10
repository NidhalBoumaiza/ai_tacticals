import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';


import '../../features/games/presentation layer/cubit/team image loading cubit/team_image_loading_cubit.dart';
import '../../features/games/presentation layer/cubit/team image loading cubit/team_image_loading_state.dart';

class TeamWebViewPool {
  static final List<WebViewController> _availableControllers = [];
  static final Map<String, WebViewController> _loadedControllers = {};
  static const int _initialPoolSize = 20; // Increased for reliability
  static const int _maxPoolSize = 50;
  static bool _isInitialized = false;

  static void initializePool() {
    if (_isInitialized) return;
    _isInitialized = true;
    for (int i = 0; i < _initialPoolSize; i++) {
      final controller = _createController();
      _availableControllers.add(controller);
    }
    print('TeamWebViewPool initialized with $_initialPoolSize controllers');
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
    print('Pool status - Available: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
    if (_loadedControllers.containsKey(imageUrl)) {
      print('Reusing loaded controller for $imageUrl');
      return _loadedControllers[imageUrl]!;
    }
    WebViewController controller;
    if (_availableControllers.isNotEmpty) {
      controller = _availableControllers.removeAt(0);
    } else {
      controller = _createController();
      print('Created new controller for $imageUrl. Total: ${_loadedControllers.length + _availableControllers.length + 1}');
    }
    _loadedControllers[imageUrl] = controller;
    print('Team controller assigned for $imageUrl. Pool size: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
    return controller;
  }

  static void releaseController(String imageUrl) {
    if (_loadedControllers.containsKey(imageUrl)) {
      final controller = _loadedControllers[imageUrl]!;
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _loadedControllers.remove(imageUrl);
      _availableControllers.add(controller);
      print('Team controller released for $imageUrl. Pool size: ${_availableControllers.length}, Loaded: ${_loadedControllers.length}');
    }
  }

  static void disposeAll() {
    for (var controller in _loadedControllers.values) {
      controller.clearCache();
      controller.loadRequest(Uri.parse('about:blank'));
      _availableControllers.add(controller);
    }
    _loadedControllers.clear();
    print('All team controllers released. Pool size: ${_availableControllers.length}');
  }
}

class TeamWebImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final VoidCallback onLoaded;

  const TeamWebImageWidget({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    required this.onLoaded,
  });

  @override
  State<TeamWebImageWidget> createState() => _TeamWebImageWidgetState();
}

class _TeamWebImageWidgetState extends State<TeamWebImageWidget> with AutomaticKeepAliveClientMixin {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasStartedLoading = false;
  bool _timedOut = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('TeamWebImageWidget init for ${widget.imageUrl}');
    if (TeamWebViewPool._loadedControllers.containsKey(widget.imageUrl)) {
      _controller = TeamWebViewPool._loadedControllers[widget.imageUrl];
      _isLoading = false;
      _hasStartedLoading = true;
      print('Reusing existing controller for ${widget.imageUrl}');
    } else {
      context.read<TeamImageLoadingCubit>().addImageToQueue(widget.imageUrl);
      // Add timeout to fallback if loading stalls
      Future.delayed(Duration(seconds: 10), () {
        if (mounted && _isLoading && !_timedOut) {
          print('Loading timed out for ${widget.imageUrl}');
          setState(() {
            _isLoading = false;
            _timedOut = true;
          });
          widget.onLoaded();
        }
      });
    }
  }

  void _loadImage() {
    if (!mounted || _hasStartedLoading) {
      print('Skipping load for ${widget.imageUrl} - not mounted or already started');
      return;
    }

    print('Attempting to load image: ${widget.imageUrl}');
    _controller = TeamWebViewPool.getController(widget.imageUrl);

    _controller!.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          if (mounted) setState(() => _isLoading = true);
          print('Page started for ${widget.imageUrl}');
        },
        onPageFinished: (String url) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.read<TeamImageLoadingCubit>().markImageAsLoaded(widget.imageUrl);
            widget.onLoaded();
          }
          print('Page finished for ${widget.imageUrl}');
        },
        onWebResourceError: (WebResourceError error) {
          print('Team error loading ${widget.imageUrl}: ${error.description}');
          if (mounted) {
            setState(() => _isLoading = false);
            context.read<TeamImageLoadingCubit>().markImageAsLoaded(widget.imageUrl);
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
    print('Team started loading ${widget.imageUrl}');
  }

  @override
  void dispose() {
    if (_controller != null && !TeamWebViewPool._loadedControllers.containsValue(_controller)) {
      TeamWebViewPool.releaseController(widget.imageUrl);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<TeamImageLoadingCubit, TeamImageLoadingState>(
      listener: (context, state) {
        print('BlocListener state for ${widget.imageUrl}: $state');
        if (state is TeamImageLoadingInProgress && state.currentUrls.contains(widget.imageUrl) && !_hasStartedLoading) {
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
            if (_isLoading && !_timedOut)
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
            if ((!_isLoading && _controller == null) || _timedOut)
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