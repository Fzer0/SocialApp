import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:app/screen/addpost_text.dart'; 


class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  List<AssetEntity> _assets = [];
  AssetEntity? _selectedAsset;
  AssetPathEntity? _recentAlbum;
  int _currentPage = 0;
  bool _isLoading = false;
  final int _pageSize = 20;
  bool _hasMore = true;
  
  final ScrollController _scrollController = ScrollController(); 

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    _scrollController.addListener(_scrollListener); 
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_hasMore || _isLoading) return;

    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      _fetchAssets(isLoadMore: true);
    }
  }

  Future<void> _fetchAssets({bool isLoadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (!isLoadMore) {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permisos de galería denegados.')),
             );
          }
          setState(() => _isLoading = false);
          return;
      }
      
      final List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.image);
      
      if (albums.isEmpty) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se encontraron imágenes en el dispositivo.')),
             );
          }
          setState(() => _isLoading = false);
          return;
      }
      
      AssetPathEntity targetAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums[0],
      );

      _recentAlbum = targetAlbum;
      _assets.clear();
      _currentPage = 0;
      _hasMore = true;
    }

    if (_recentAlbum != null && _hasMore) {
      final List<AssetEntity> media =
          await _recentAlbum!.getAssetListPaged(page: _currentPage, size: _pageSize);

      if (media.isEmpty) {
        _hasMore = false;
      } else {
        setState(() {
          _assets.addAll(media);
          _currentPage++;
          if (_selectedAsset == null) {
            _selectedAsset = _assets.first; 
          }
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
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

  Widget _buildAssetThumbnail(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return Container(color: Colors.grey[200]);
      },
    );
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
          controller: _scrollController, 
          child: Column(
            children: [
              // 1. Sección de la imagen seleccionada (Vista previa)
              SizedBox(
                height: 375.h,
                child: _selectedAsset == null
                    ? const Center(child: CircularProgressIndicator())
                    : _assets.isEmpty && _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : FutureBuilder<Uint8List?>(
                            future: _selectedAsset!.thumbnailDataWithSize(
                                ThumbnailSize(MediaQuery.of(context).size.width.toInt(), 375.h.toInt()), 
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done &&
                                  snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                            },
                          ),
              ),
              // 2. Separador
              Container(
                width: double.infinity,
                height: 40.h,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    'Recientes',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // 3. Galería de imágenes con GridView.builder
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    child: _buildAssetThumbnail(asset),
                  );
                },
              ),
              // 4. Indicador de Carga
              if (_isLoading && _hasMore)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_hasMore && _assets.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
                  child: Text('Fin de la galería'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}