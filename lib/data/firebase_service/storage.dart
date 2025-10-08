import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageMetod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<String> uploadImageToStorage(String name, File file) async {
    // Verificar que el usuario actual no sea nulo antes de continuar
    if (_auth.currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }
    
    Reference ref = _storage.ref().child(name).child(_auth.currentUser!.uid);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}