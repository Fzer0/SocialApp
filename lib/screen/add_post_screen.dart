import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

// Asume que esta es tu pantalla de destino para navegar
class AddPostTextScreen extends StatelessWidget {
  final File file;
  const AddPostTextScreen(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next Screen')),
      body: Center(
        child: Text('File path: ${file.path}'),
      ),
    );
  }
}

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  List<AssetEntity> _assets = [];
  AssetEntity? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.image);

      if (albums.isNotEmpty) {
        final List<AssetEntity> media =
            await albums[0].getAssetListPaged(page: 0, size: 60);

        setState(() {
          _assets = media;
          _selectedAsset = media.isNotEmpty ? media[0] : null;
        });
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (_selectedAsset != null) {
      final File? file = await _selectedAsset!.file;
      if (file != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddPostTextScreen(file),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: GestureDetector(
                onTap: _navigateToNextScreen,
                child: Text(
                  'Next',
                  style: TextStyle(fontSize: 15.sp, color: Colors.blue),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Sección de la imagen seleccionada
              SizedBox(
                height: 375.h,
                child: _selectedAsset == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder(
                        future: _selectedAsset!.originFile,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.data != null) {
                            return Image.file(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
              ),
              // Separador y título de la galería
              Container(
                width: double.infinity,
                height: 40.h,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    'Recent',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Galería de imágenes con GridView.builder
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Evita el scroll anidado
                itemCount: _assets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  final AssetEntity asset = _assets[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAsset = asset;
                      });
                    },
                    child: FutureBuilder(
                      future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}