// En el archivo: social_app/screen/reelsScreen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReelScreen extends StatefulWidget {
  const ReelScreen({super.key});

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
  // Asegúrate de que esta instancia es la misma que la que usas en toda la app
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // Verifica que el nombre de la colección 'reels' sea exactamente igual al de tu base de datos
          stream: _firestore.collection('reels').orderBy('time', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Ocurrió un error.'));
            }

            // Comprueba si el snapshot no tiene datos o si la lista de documentos está vacía
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay reels disponibles.'));
            }

            // Si llegamos a este punto, significa que sí hay datos
            final reels = snapshot.data!.docs;

            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              itemBuilder: (context, index) {
                final reelData = reels[index].data() as Map<String, dynamic>;
                // Asegúrate de que 'url' sea el nombre de campo correcto en tu documento de Firestore
                final videoUrl = reelData['url']; 

                // Aquí deberías usar un widget de video, como video_player, para mostrar el reel
                // Por ejemplo, para un video simple, puedes usar una librería de video
                // Actualmente, solo muestra el texto como ejemplo
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