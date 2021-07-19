import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoApp extends StatefulWidget {
  final String video;
  VideoApp({this.video});
  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.video == null
        ? VideoPlayerController.network(
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
        : VideoPlayerController.asset(widget.video)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: InkWell(
        onTap: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Stack(alignment: Alignment.center, children: [
          Center(
              child: _controller.value.initialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : CircularProgressIndicator()),
          _controller.value.isPlaying || !_controller.value.initialized
              ? SizedBox.shrink()
              : Icon(
                  Icons.play_arrow,
                  size: 60,
                  color: Colors.white,
                )
        ]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
