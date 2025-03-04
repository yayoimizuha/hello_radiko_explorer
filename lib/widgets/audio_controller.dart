import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hello_radiko_explorer/services/audio_service.dart';

class AudioController extends StatefulWidget {
  const AudioController({super.key});

  @override
  _AudioControllerState createState() => _AudioControllerState();
}

class _AudioControllerState extends State<AudioController> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    AudioService.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await AudioService.pause();
    } else {
      await AudioService.resume();
    }
  }

  String _formatDuration(Duration d) {
    int minutes = d.inMinutes;
    int seconds = d.inSeconds % 60;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 30,
                child: StreamBuilder<Duration?>(
                  stream: AudioService.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: AudioService.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        return SliderTheme(
                          data: SliderTheme.of(
                            context,
                          ).copyWith(trackHeight: 4.0),
                          child: Slider(
                            value: min(
                              position.inSeconds.toDouble(),
                              duration.inSeconds.toDouble(),
                            ),
                            min: 0,
                            max: duration.inSeconds.toDouble(),
                            onChanged: (value) async {
                              await AudioService.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 24.0,
                      icon: const Icon(Icons.replay_30),
                      onPressed: () async {
                        await AudioService.skipSize(-30);
                      },
                    ),
                    IconButton(
                      iconSize: 24.0,
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlay,
                    ),
                    IconButton(
                      iconSize: 24.0,
                      icon: const Icon(Icons.forward_30),
                      onPressed: () async {
                        await AudioService.skipSize(30);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 4,
            bottom: 2,
            child: StreamBuilder<Duration?>(
              stream: AudioService.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: AudioService.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    return Text(
                      "${_formatDuration(position)}/${_formatDuration(duration)}",
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
