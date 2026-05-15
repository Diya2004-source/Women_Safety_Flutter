import 'package:flutter/material.dart';

class ShareLocationPage extends StatelessWidget {
  const ShareLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Location'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Share your current location with trusted contacts.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
