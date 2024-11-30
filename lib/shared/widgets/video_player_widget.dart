// lib/shared/widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/themes/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/sample.mp4")
      ..initialize().then((_) {
        setState(() {});
      });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }


  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Positioned(
          bottom: AppSpacing.xs,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isPlaying ? _controller.pause() : _controller.play();
                    _isPlaying = !_isPlaying;
                  });
                },
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.background,
                ),
                iconSize: 24,
              ),
              Expanded(
                child: Slider(
                  value: _controller.value.position.inSeconds.toDouble(),
                  max: _controller.value.duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _controller.seekTo(Duration(seconds: value.toInt()));
                    });
                  },
                  activeColor: AppColors.error,
                  inactiveColor: AppColors.background,
                ),
              ),
              Text(
                "${formatDuration(_controller.value.position)} / ${formatDuration(_controller.value.duration)}",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        : const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}
