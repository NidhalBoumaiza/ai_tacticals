import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../features/games/presentation layer/cubit/League Image Loading Cubit/league_image_loading_cubit.dart';
import '../../features/games/presentation layer/cubit/League Image Loading Cubit/league_image_loading_state.dart';
import '../web view/base_web_view_pool.dart';

class WebViewPool extends BaseWebViewPool {
  WebViewPool()
    : super(initialPoolSize: 5, maxPoolSize: 20, concurrentLoads: 10);
}

class WebImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final VoidCallback onLoaded;
  static final WebViewPool pool = WebViewPool();

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

class _WebImageWidgetState extends State<WebImageWidget>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasStartedLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (WebImageWidget.pool.hasController(widget.imageUrl)) {
      _controller = WebImageWidget.pool.getLoadedController(widget.imageUrl);
      _isLoading = false;
      _hasStartedLoading = true;
    } else {
      final cubit = context.read<LeagueImageLoadingCubit?>();
      if (cubit != null) {
        cubit.addImageToQueue(widget.imageUrl);
      } else {
        _loadImage();
      }
    }
  }

  Future<void> _loadImage() async {
    if (!mounted || _hasStartedLoading) return;

    try {
      _controller = await WebImageWidget.pool.getController(widget.imageUrl);
      _controller!.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
              context.read<LeagueImageLoadingCubit?>()?.markImageAsLoaded(
                widget.imageUrl,
              );
              widget.onLoaded();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode)
              print('Error loading ${widget.imageUrl}: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _controller = null; // Ensure controller is null on error
              });
              context.read<LeagueImageLoadingCubit?>()?.markImageAsLoaded(
                widget.imageUrl,
              );
              widget.onLoaded();
            }
          },
        ),
      );
      _hasStartedLoading = true;
    } catch (e) {
      if (kDebugMode) print('Failed to load ${widget.imageUrl}: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (_controller != null &&
        !WebImageWidget.pool.isControllerInUse(_controller!)) {
      WebImageWidget.pool.releaseController(widget.imageUrl);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<LeagueImageLoadingCubit?>();
    if (cubit != null) {
      return BlocListener<LeagueImageLoadingCubit, LeagueImageLoadingState>(
        listener: (context, state) {
          if (state is LeagueImageLoadingInProgress &&
              state.currentUrls.contains(widget.imageUrl) &&
              !_hasStartedLoading) {
            _loadImage();
          }
        },
        child: _buildImageContent(),
      );
    }
    return _buildImageContent();
  }

  Widget _buildImageContent() {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_hasStartedLoading && _controller != null && !_isLoading)
            ClipOval(child: WebViewWidget(controller: _controller!)),
          if (_isLoading) // Show shimmer during loading
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
          if (!_isLoading && _controller == null) // Show soccer icon on error
            ClipOval(
              child: Container(
                height: widget.height,
                width: widget.width,
                color: Colors.grey[200],
                child: Icon(
                  Icons.sports_soccer,
                  size: widget.height * 0.5,
                  color: Colors.grey[400],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
