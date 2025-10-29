import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('reels').orderBy('time', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Ocurrió un error.'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay reels disponibles.'));
            }

            final reels = snapshot.data!.docs;

            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              itemBuilder: (context, index) {
                final reelData = reels[index].data() as Map<String, dynamic>;
                final videoUrl = reelData['url'];
                return Center(
                  child: Text('Reel ${index + 1}: $videoUrl'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}