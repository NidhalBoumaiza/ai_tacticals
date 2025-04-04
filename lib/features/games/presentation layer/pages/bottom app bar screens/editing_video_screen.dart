import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:video_player/video_player.dart';
import '../../cubit/video editing cubit/video_editing_cubit.dart';
import '../../cubit/video editing cubit/video_editing_state.dart';
import 'full_screen_video_page.dart';

class EditingVideoScreen extends StatefulWidget {
  const EditingVideoScreen({super.key});

  @override
  State<EditingVideoScreen> createState() => _EditingVideoScreenState();
}

class _EditingVideoScreenState extends State<EditingVideoScreen> {
  final GlobalKey _videoKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Éditeur de Vidéo"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            BlocBuilder<VideoEditingCubit, VideoEditingState>(
              builder: (context, videoState) {
                return Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                  child: RepaintBoundary(
                    key: _videoKey,
                    child: videoState.controller != null && videoState.controller!.value.isInitialized
                        ? AspectRatio(
                      aspectRatio: videoState.controller!.value.aspectRatio,
                      child: VideoPlayer(videoState.controller!),
                    )
                        : const Center(child: Text("Aucune vidéo sélectionnée")),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildPickVideoButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPickVideoButton(BuildContext context) {
    return BlocBuilder<VideoEditingCubit, VideoEditingState>(
      builder: (context, state) => ElevatedButton(
        onPressed: state.isPickerActive
            ? null
            : () async {
          var status = await Permission.videos.request();
          if (status.isGranted) {
            await context.read<VideoEditingCubit>().pickVideo();
            if (context.read<VideoEditingCubit>().state.controller != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                PersistentNavBarNavigator.pushNewScreen(
                  context,
                  screen: const FullScreenVideoPage(),
                  withNavBar: false,
                  pageTransitionAnimation: PageTransitionAnimation.slideRight,
                );
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video permission denied")));
          }
        },
        child: const Text("Pick a video"),
      ),
    );
  }
}