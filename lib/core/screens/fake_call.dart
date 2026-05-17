import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class FakeCallPage extends StatefulWidget {
  const FakeCallPage({super.key});

  @override
  State<FakeCallPage> createState() => _FakeCallPageState();
}

class _FakeCallPageState extends State<FakeCallPage> {
  late AudioPlayer _audioPlayer;
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    ));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startRinging() async {
    try {
      await _audioPlayer.setVolume(2.0); // Set to maximum volume
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop continuously
      await _audioPlayer.play(AssetSource('audio/call.mp3'));
      setState(() {
        _isRinging = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio $e')),
      );
    }
  }

  void _stopRinging() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isRinging = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping audio: ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Trigger a fake incoming call to get out of unsafe situations.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: _isRinging ? Colors.red : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isRinging ? 'Ringing...' : 'Ready',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isRinging ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Start Button
                  ElevatedButton.icon(
                    onPressed: _isRinging ? null : _startRinging,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                    icon: const Icon(Icons.phone_in_talk),
                    label: const Text('Start Call'),
                  ),
                  const SizedBox(width: 24),
                  // Stop Button
                  ElevatedButton.icon(
                    onPressed: _isRinging ? _stopRinging : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                    icon: const Icon(Icons.call_end),
                    label: const Text('Pick Call'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
