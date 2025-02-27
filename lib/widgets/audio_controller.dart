import 'package:flutter/material.dart';
import 'package:hello_radiko_explorer/services/audio_service.dart';

class AudioController extends StatefulWidget {
  const AudioController({Key? key}) : super(key: key);

  @override
  _AudioControllerState createState() => _AudioControllerState();
}

class _AudioControllerState extends State<AudioController> {
  bool _isPlaying = false;

  void _togglePlay() async {
    if (_isPlaying) {
      await AudioService.pause();
    } else {
      await AudioService.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePlay,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () async {
              await AudioService.stop();
              setState(() {
                _isPlaying = false;
              });
            },
          ),
        ],
      ),
    );
  }
}