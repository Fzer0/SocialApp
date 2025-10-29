import 'dart:io';

import 'package:flutter/material.dart';

class ReelsEditeScreen extends StatelessWidget {
  final File file;
  const ReelsEditeScreen(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File path:'),
            const SizedBox(height: 8),
            Text(file.path),
            const SizedBox(height: 20),
            const Text('Aquí puedes implementar la edición del reel (preview, recorte, audio, etc.)'),
          ],
        ),
      ),
    );
  }
}
