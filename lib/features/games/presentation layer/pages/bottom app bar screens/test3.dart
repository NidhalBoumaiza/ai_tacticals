import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class Test3 extends StatefulWidget {
  const Test3({super.key});

  @override
  _Test3State createState() => _Test3State();
}

class _Test3State extends State<Test3> {
  late VideoPlayerController _controller;
  bool _isPainting = false;
  List<Offset> _paintPoints = [];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      )
      ..initialize().then((_) {
        setState(() {});
      });
    _requestPermissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [Permission.storage].request();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPainting = true;
      } else {
        _controller.play();
        _isPainting = false;
      }
    });
  }

  Future<void> _savePaintedVideo() async {
    final frame = await _captureFrameFromVideo();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = _controller.value.size;
    canvas.drawImage(frame, Offset.zero, Paint());
    VideoPainter(_paintPoints).paint(canvas, size);
    final picture = recorder.endRecording();
    final paintedImage = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await paintedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getExternalStorageDirectory();
    final imagePath = '${directory!.path}/painted_frame.png';
    await File(imagePath).writeAsBytes(buffer);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved painted frame to $imagePath')),
    );
  }

  Future<ui.Image> _captureFrameFromVideo() async {
    final completer = Completer<ui.Image>();
    completer.complete(await decodeImageFromList(Uint8List(0))); // Dummy image
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body:
          _controller.value.isInitialized
              ? Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (_isPainting)
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _paintPoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _paintPoints.add(Offset(-1, -1));
                        });
                      },
                      child: CustomPaint(
                        painter: VideoPainter(_paintPoints),
                        size: Size(
                          _controller.value.size.width,
                          _controller.value.size.height,
                        ),
                      ),
                    ),
                ],
              )
              : Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            onPressed: _togglePlayPause,
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          SizedBox(height: 10.h),
          FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            onPressed: _savePaintedVideo,
            child: Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}

class VideoPainter extends CustomPainter {
  final List<Offset> paintPoints;

  VideoPainter(this.paintPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < paintPoints.length - 1; i++) {
      if (paintPoints[i] != Offset(-1, -1) &&
          paintPoints[i + 1] != Offset(-1, -1)) {
        canvas.drawLine(paintPoints[i], paintPoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
