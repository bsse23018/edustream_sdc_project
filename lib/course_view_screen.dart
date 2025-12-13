import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aws_config.dart';

class CourseViewScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseViewScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CourseViewScreen> createState() => _CourseViewScreenState();
}

class _CourseViewScreenState extends State<CourseViewScreen> {
  List<dynamic> _videos = [];
  bool _isLoading = true;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  int _playingIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final res = await http.post(
      Uri.parse(API_URL),
      body: jsonEncode({'action': 'get_videos', 'course_id': widget.courseId}),
    );
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          _videos = jsonDecode(res.body)['videos'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializePlayer(String url, int index) async {
    // Dispose old player if exists
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    setState(() => _playingIndex = index);

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.courseName,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // VIDEO PLAYER AREA
          Container(
            height: 250,
            color: Colors.grey[900],
            child:
                _chewieController != null &&
                    _videoPlayerController!.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.white54,
                          size: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Select a video to play",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
          ),

          // PLAYLIST AREA
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _videos.isEmpty
                  ? const Center(child: Text("No lectures uploaded yet."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _videos.length,
                      itemBuilder: (ctx, i) {
                        final v = _videos[i];
                        final isPlaying = i == _playingIndex;
                        return Card(
                          color: isPlaying ? Colors.indigo[50] : Colors.white,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: isPlaying ? Colors.indigo : Colors.grey,
                              size: 30,
                            ),
                            title: Text(
                              v['title'],
                              style: TextStyle(
                                fontWeight: isPlaying
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isPlaying ? Colors.indigo : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              "Added: ${DateTime.fromMillisecondsSinceEpoch(int.parse(v['timestamp'])).toString().split(' ')[0]}",
                            ),
                            // Inside ListView.builder -> Card -> ListTile
                            onTap: () {
                              // Just play the URL directly.
                              // Thanks to the Lambda update, this URL is now Public and Accessible.
                              _initializePlayer(v['url'], i);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
