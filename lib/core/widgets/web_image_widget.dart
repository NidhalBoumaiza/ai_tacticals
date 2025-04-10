import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/web view/base_web_view_pool.dart';
import '../../features/games/presentation layer/cubit/image loading cubit/image_loading_cubit.dart';
import '../../features/games/presentation layer/cubit/image loading cubit/image_loading_state.dart';


class WebViewPool extends BaseWebViewPool {
  WebViewPool()
      : super(
    initialPoolSize: 5,
    maxPoolSize: 15,
    concurrentLoads: 5,
  );
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
  static final WebViewPool _pool = WebViewPool();
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasStartedLoading = false;
  bool _timedOut = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (_pool.hasController(widget.imageUrl)) {
      _controller = _pool.getLoadedController(widget.imageUrl);
      _isLoading = false;
      _hasStartedLoading = true;
    } else {
      context.read<ImageLoadingCubit>().addImageToQueue(widget.imageUrl);
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isLoading && !_timedOut) {
          setState(() {
            _isLoading = false;
            _timedOut = true;
          });
          widget.onLoaded();
        }
      });
    }
  }

  Future<void> _loadImage() async {
    if (!mounted || _hasStartedLoading) return;

    _controller = await _pool.getController(widget.imageUrl);

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
          if (kDebugMode) {
            print('Error loading ${widget.imageUrl}: ${error.description}');
          }
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
  }

  @override
  void dispose() {
    if (_controller != null && !_pool.isControllerInUse(_controller!)) {
      _pool.releaseController(widget.imageUrl);
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