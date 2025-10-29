// storage.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p; // Necesitas este paquete: flutter pub add path

class StorageMetod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadImageToStorage(String folderName, File file) async {
    
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      print('❌ Error: Usuario no autenticado. La subida a Storage fallará por reglas.');
      return null;
    }
    
    String fileId = const Uuid().v4();
    Reference ref = _storage.ref()
        .child(folderName) 
        .child(currentUser.uid) 
        .child(fileId); 
  // Debug: mostrar UID del usuario actual y ruta destino
  print('🔎 Storage upload debug - currentUser.uid: ${currentUser.uid}');
  print('🔎 Storage upload debug - destination path: ${folderName}/${currentUser.uid}/$fileId');
    
    // CORRECCIÓN CLAVE: Determinar la extensión y crear metadatos explícitos.
    String extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    
    final SettableMetadata metadata = SettableMetadata(
      // Forzar un Content-Type válido para evitar NullPointerException en Android.
      contentType: 'image/$extension', 
    );
    
    // Inicializar la tarea con los metadatos.
    UploadTask uploadTask = ref.putFile(file, metadata); 

    // Lógica de reintento: Mantenida y ligeramente ajustada para la estabilidad.
    const int timeoutSeconds = 120;
    int attempts = 0;
    const int maxAttempts = 2;
    TaskSnapshot snapshot;

    while (true) {
      attempts++;
      try {
        snapshot = await uploadTask.timeout(const Duration(seconds: timeoutSeconds));
        // Si no hay timeout, la subida fue exitosa.
        break; 
      } on TimeoutException catch (e) {
        print('❌ Upload timeout on attempt $attempts: $e');

        if (attempts >= maxAttempts) {
          print('❌ Max upload attempts reached, aborting upload.');
          return null;
        }

        // Re-crear uploadTask para reintentar la subida
        try {
          // Se cancela la tarea anterior para liberar recursos y evitar conflictos.
          await uploadTask.cancel(); 
          
          // Se crea una nueva tarea de subida con el mismo archivo y metadatos.
          uploadTask = ref.putFile(file, metadata); 
          print('🔁 Retrying upload (attempt ${attempts + 1})...');
        } catch (err) {
          print('⚠️ Failed to re-create upload task for retry: $err');
          // Si falló el reintento, salimos.
          return null; 
        }
      } on FirebaseException catch (e) {
        // Capturar errores de Firebase (PERMISSION_DENIED, etc.)
        print('❌ ERROR FIREBASE STORAGE (${e.code}): ${e.message}');
        return null;
      } catch (e) {
        // Capturar otros errores generales
        print('❌ Error inesperado durante la subida: $e');
        return null;
      }
    }

    try {
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ Upload finished, downloadUrl: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Error al obtener Download URL: $e');
      return null;
    }
  }
}