import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'package:path_provider/path_provider.dart'; 

import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/firebase_service/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPostTextScreen extends StatefulWidget {
  final File file;
  const AddPostTextScreen(this.file, {super.key});

  @override
  State<AddPostTextScreen> createState() => _AddPostTextScreenState();
}

class _AddPostTextScreenState extends State<AddPostTextScreen> {
  final caption = TextEditingController();
  final location = TextEditingController();
  bool isLoading = false; 

  @override
  void dispose() {
    caption.dispose();
    location.dispose();
    super.dispose();
  }

  void _sharePost() async {
    if (isLoading) return; 

    setState(() {
      isLoading = true;
    });

    try {
      // === 🎯 INICIO DE LA OPTIMIZACIÓN: COMPRESIÓN DE IMAGEN ===
      
      // 1. Obtener la ruta temporal para guardar el archivo comprimido
      final dir = await getTemporaryDirectory();
      final targetPath = "${dir.path}/compressed_image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // 2. Realizar la compresión
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        widget.file.absolute.path, 
        targetPath, 
        quality: 85, // Reduce la calidad al 85% (gran mejora de velocidad)
        // Puedes añadir minWidth: 1080 o minHeight: 1080 si deseas redimensionar
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        throw Exception("Fallo al comprimir la imagen.");
      }
      
      // Convertir XFile (el resultado de la compresión) a File
      final File finalFile = File(compressedXFile.path); 
      
      // === 🎯 FIN DE LA OPTIMIZACIÓN ===
      

      // 3. Subir el archivo COMPRIMIDO (finalFile) a Storage
      String post_url = await StorageMetod()
          .uploadImageToStorage('posts', finalFile); 
          
      // 4. Guardar la referencia en Firestore
      await Firebase_Firestor().CreatePost(
        postImage: post_url,
        caption: caption.text.trim(),
        location: location.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post publicado con éxito!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fallo al publicar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('New post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: GestureDetector(
                onTap: isLoading ? null : _sharePost,
                child: Text('Share',
                  style: TextStyle(
                    color: isLoading ? Colors.grey : Colors.blue, 
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
          child: isLoading 
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ))
              : SingleChildScrollView(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        child: Row(
                          children: [
                            Container(
                              width: 65.w,
                              height: 65.h,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                image: DecorationImage(
                                  // El widget sigue mostrando el archivo original (widget.file)
                                  image: FileImage(widget.file), 
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded( 
                              child: SizedBox(
                                height: 60.h,
                                child: TextField(
                                  controller: caption,
                                  decoration: const InputDecoration(
                                    hintText: 'Write a caption ...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  maxLines: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: SizedBox(
                          height: 30.h,
                          child: TextField(
                            controller: location,
                            decoration: const InputDecoration(
                              hintText: 'Add location',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
    );
  }
}