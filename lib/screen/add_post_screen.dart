import 'dart:io';
import 'dart:typed_data'; // Importar Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

// --------------------------------------------------------------------------
// PANTALLA DE DESTINO (AddPostTextScreen)
// --------------------------------------------------------------------------
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
  // Variables de estado y paginación
  List<AssetEntity> _assets = [];
  AssetEntity? _selectedAsset;
  AssetPathEntity? _recentAlbum; // Álbum principal (All Photos/Recientes)
  int _currentPage = 0; // Página actual cargada
  bool _isLoading = false; // Bandera para evitar llamadas múltiples
  final int _pageSize = 20; // Tamaño de página más pequeño para rapidez
  bool _hasMore = true; // Indica si quedan más fotos por cargar
  
  // Controlador de Scroll para detectar el final de la lista
  final ScrollController _scrollController = ScrollController(); 

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    // Listener para la carga infinita
    _scrollController.addListener(_scrollListener); 
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Listener que se dispara al hacer scroll
  void _scrollListener() {
    // Si no quedan más fotos o ya está cargando, salir.
    if (!_hasMore || _isLoading) return;

    // Detecta si el usuario está cerca del final (90% del scroll).
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      _fetchAssets(isLoadMore: true);
    }
  }

  // Función de Carga Paginada y Robusta
  Future<void> _fetchAssets({bool isLoadMore = false}) async {
    if (_isLoading) return; // Si ya está cargando, ignora

    setState(() {
      _isLoading = true;
    });

    if (!isLoadMore) {
      // --- Lógica de Carga Inicial (Permisos y Álbum) ---
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
      
      // Obtener la lista de álbumes (solo imágenes)
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
      
      // 🐛 CORRECCIÓN: Seleccionar el álbum "All" o el primero como respaldo
      AssetPathEntity targetAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums[0],
      );

      _recentAlbum = targetAlbum;
      _assets.clear();
      _currentPage = 0;
      _hasMore = true;
    }

    // --- Lógica de Carga de Página ---
    if (_recentAlbum != null && _hasMore) {
      final List<AssetEntity> media =
          await _recentAlbum!.getAssetListPaged(page: _currentPage, size: _pageSize);

      if (media.isEmpty) {
        // Se llegó al final de la galería
        _hasMore = false;
      } else {
        setState(() {
          _assets.addAll(media);
          _currentPage++;
          if (_selectedAsset == null) {
            _selectedAsset = _assets.first; // Seleccionar la primera foto al inicio
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
      // Obtener el archivo completo solo al momento de navegar
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

  // Widget para mostrar una miniatura de la imagen de la galería
  Widget _buildAssetThumbnail(AssetEntity asset) {
    return FutureBuilder<Uint8List?>( // Especifica el tipo de retorno (Uint8List?)
      // Carga la miniatura de 200x200 para la galería (rápido)
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
          // Asigna el ScrollController para carga infinita
          controller: _scrollController, 
          child: Column(
            children: [
              // 1. Sección de la imagen seleccionada (usa thumbnail de alta resolución)
              SizedBox(
                height: 375.h,
                child: _selectedAsset == null
                    ? const Center(child: CircularProgressIndicator())
                    // Muestra un indicador si la lista aún está vacía, sino el FutureBuilder
                    : _assets.isEmpty && _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : FutureBuilder<Uint8List?>(
                            // Carga la imagen principal usando una miniatura de alta resolución (rápida)
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
              // 2. Separador y título de la galería (sin cambios)
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
              // 3. Galería de imágenes con GridView.builder
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll del GridView
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
              // 4. Indicador de Carga: Muestra un spinner si se están cargando más fotos
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