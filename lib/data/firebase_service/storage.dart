// storage.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageMetod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadImageToStorage(String folderName, File file) async {

    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      // print('❌ Error: Usuario no autenticado. La subida a Storage fallará por reglas.');
      return null;
    }

    // ⚠️ NUEVA VERIFICACIÓN DE ARCHIVO: Asegura que el File tiene contenido.
    try {
      if (!await file.exists() || await file.length() == 0) {
        // print('❌ Error: El archivo ${file.path} no existe o está vacío (0 bytes). Abortando subida.');
        return null;
      }
    } catch (e) {
      // print('❌ Error al verificar el archivo antes de subir: $e');
      return null;
    }
    // ***************************************

    String fileId = const Uuid().v4();
    Reference ref = _storage.ref()
        .child(folderName)
        .child(currentUser.uid)
        .child(fileId);

    // print('🔎 Storage upload debug - currentUser.uid: ${currentUser.uid}');
    // print('🔎 Storage upload debug - destination path: ${folderName}/${currentUser.uid}/$fileId');

    String extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/$extension',
    );

    UploadTask uploadTask = ref.putFile(file, metadata);

    const int timeoutSeconds = 120;
    int attempts = 0;
    const int maxAttempts = 2;
    TaskSnapshot snapshot;

    while (true) {
      attempts++;
      try {
        snapshot = await uploadTask.timeout(const Duration(seconds: timeoutSeconds));
        break;
      } on TimeoutException catch (e) {
        // print('❌ Upload timeout on attempt $attempts: $e');

        if (attempts >= maxAttempts) {
          // print('❌ Max upload attempts reached, aborting upload.');
          return null;
        }
        try {
          await uploadTask.cancel();
          uploadTask = ref.putFile(file, metadata);
          // print('🔁 Retrying upload (attempt ${attempts + 1})...');
        } catch (err) {
          // print('⚠️ Failed to re-create upload task for retry: $err');
          return null;
        }
      } on FirebaseException catch (e) {
        // print('❌ ERROR FIREBASE STORAGE (${e.code}): ${e.message}');
        return null;
      } catch (e) {
        // print('❌ Error inesperado durante la subida: $e');
        return null;
      }
    }

    try {
      String downloadUrl = await snapshot.ref.getDownloadURL();
      // print('✅ Upload finished, downloadUrl: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      // print('❌ Error al obtener Download URL: $e');
      return null;
    }
  }


}
