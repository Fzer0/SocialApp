import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'package:path_provider/path_provider.dart'; 

import 'package:app/data/firebase_service/storage.dart';
import 'package:app/util/upload_bus.dart';
import 'package:app/data/firebase_service/firestor.dart';
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
      // 1. Obtener la ruta temporal
      final dir = await getTemporaryDirectory();
      final targetPath = "${dir.path}/compressed_image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // 2. Realizar la compresión
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        widget.file.absolute.path, 
        targetPath, 
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        throw Exception("Fallo al comprimir la imagen.");
      }
      final File finalFile = File(compressedXFile.path); 
      
    // 3. Subir el archivo COMPRIMIDO a Storage
    // uploadImageToStorage puede devolver String? — usar ?? '' para garantizar String no nulo
    String post_url = (await StorageMetod()
      .uploadImageToStorage('posts', finalFile)) ?? '';
          
      // 4. Solo guardar la imagen en Storage: si no tenemos URL, avisar error
      if (post_url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fallo al subir la imagen.')), 
          );
        }
        return;
      }

      // Si la subida fue exitosa, crear documento en Firestore para que la imagen
      // se liste permanentemente en el feed, además de notificar al UploadBus.
      bool created = false;
      Object? creationError;
      try {
        created = await Firebase_Firestor().CreatePost(
          postImage: post_url,
          caption: caption.text.trim(),
          location: location.text.trim(),
        );
      } catch (e) {
        creationError = e;
        print('Error creating post document: $e');
        created = false;
      }

      if (mounted) {
        if (created) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post publicado')),
          );
          // Notificar a cualquier oyente (ej. Home) que hay una nueva imagen
          try {
            UploadBus.controller.add(post_url);
          } catch (e) {
            print('UploadBus add failed: $e');
          }
          // Devolver la URL al screen anterior
          Navigator.of(context).pop(post_url);
        } else {
          // Si no se creó el documento en Firestore, mostrar diálogo con opción a reintentar.
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Subida completada, pero falla al crear el post'),
              content: Text('La imagen se subió a Storage, pero no se pudo crear el documento en Firestore.\nError: ${creationError ?? 'desconocido'}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Notificar al usuario y cerrar el screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Imagen subida: $post_url')),
                    );
                    Navigator.of(context).pop(post_url);
                  },
                  child: const Text('Ignorar'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reintentando crear post...')));
                    try {
                      final retried = await Firebase_Firestor().CreatePost(
                        postImage: post_url,
                        caption: caption.text.trim(),
                        location: location.text.trim(),
                      );
                      if (retried) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post publicado')));
                        try { UploadBus.controller.add(post_url); } catch (e) { print('UploadBus add failed: $e'); }
                        Navigator.of(context).pop(post_url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo crear el post')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando post: $e')));
                    }
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
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