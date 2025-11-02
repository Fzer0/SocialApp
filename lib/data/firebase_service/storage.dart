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
      return null;
    }
    try {
      if (!await file.exists() || await file.length() == 0) {
        return null;
      }
    } catch (e) {
      return null;
    }

    String fileId = const Uuid().v4();
    Reference ref = _storage.ref()
        .child(folderName)
        .child(currentUser.uid)
        .child(fileId);

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

        if (attempts >= maxAttempts) {
          return null;
        }
        try {
          await uploadTask.cancel();
          uploadTask = ref.putFile(file, metadata);
        } catch (err) {
          return null;
        }
      } on FirebaseException catch (e) {
        return null;
      } catch (e) {
        return null;
      }
    }
    try {
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      return null;
    }
  }


}
