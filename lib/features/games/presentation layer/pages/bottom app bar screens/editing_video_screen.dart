import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class EditingVideoScreen extends StatefulWidget {
  const EditingVideoScreen({super.key});

  @override
  State<EditingVideoScreen> createState() => _EditingVideoScreenState();
}

class _EditingVideoScreenState extends State<EditingVideoScreen> {
  VideoPlayerController? _controller;
  final ImagePicker _picker = ImagePicker();
  bool _isPickerActive = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (_isPickerActive) return;

    // Request video permission (optimized for Android 13+)
    var status = await Permission.videos.request();
    print("Requesting video permission...");
    print("Permission status: $status");

    if (!status.isGranted) {
      if (status.isDenied) {
        print("Permission denied by user");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Video permission is required to pick a video."),
            action: SnackBarAction(
              label: "Retry",
              onPressed: () async {
                // Retry permission request
                var newStatus = await Permission.videos.request();
                if (newStatus.isGranted) {
                  _pickVideoAfterPermission();
                }
              },
            ),
          ),
        );
      } else if (status.isPermanentlyDenied) {
        print("Permission permanently denied");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enable video permission in settings."),
            action: SnackBarAction(
              label: "Settings",
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Permission granted, proceed to pick video
    _pickVideoAfterPermission();
  }

  Future<void> _pickVideoAfterPermission() async {
    print("Permission granted, picking video...");
    setState(() {
      _isPickerActive = true;
    });
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        print("Video picked: ${video.path}");
        _controller?.dispose();
        _controller = VideoPlayerController.file(File(video.path))
          ..initialize().then((_) {
            setState(() {});
            _controller!.play();
            print("Video playing");
          });
      } else {
        print("No video selected");
      }
    } catch (e) {
      print("Error picking video: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking video: $e")));
    } finally {
      setState(() {
        _isPickerActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Éditeur de Vidéo"),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: () {})],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 50.w),
        child: Column(
          children: [
            SizedBox(height: 50.h),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              height: _controller == null ? 600.h : null,
              width: double.infinity,
              child:
                  _controller != null && _controller!.value.isInitialized
                      ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                      : Center(child: Text("Aucune vidéo sélectionnée")),
            ),
            SizedBox(height: 50.h),
            ElevatedButton(
              onPressed: _isPickerActive ? null : _pickVideo,
              child: Text("Pick a video"),
            ),
          ],
        ),
      ),
    );
  }
}
