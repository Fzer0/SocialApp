import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/util/upload_bus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:app/data/firebase_service/firestor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/screen/addpost_text.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _uploadedImages = [];
  StreamSubscription<String>? _uploadSub;

  @override
  void initState() {
    super.initState();
    // Suscribirse al bus de uploads para actualizar la UI cuando llegue una nueva URL
    _uploadSub = UploadBus.controller.stream.listen((url) {
      setState(() {
        // insertar al inicio para mostrar primero las más recientes
        _uploadedImages.insert(0, url);
      });
    });
  }

  @override
  void dispose() {
    _uploadSub?.cancel();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPostTextScreen(file)));
      }
    }
  }

  void _showCommentBottomSheet(BuildContext context, String postId, String username) {
    final TextEditingController commentController = TextEditingController();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comentarios',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Comments list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestor().getComments(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final comments = snapshot.data?.docs ?? [];
                      if (comments.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay comentarios aún',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentDoc = comments[index];
                          final commentData = commentDoc.data() as Map<String, dynamic>;
                          final commentUsername = commentData['username'] ?? 'Usuario';
                          final commentText = commentData['comment'] ?? '';
                          final commentUid = commentData['uid'] ?? '';
                          final commentId = commentDoc.id;
                          final isOwnComment = currentUid == commentUid;

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar placeholder
                                ClipOval(
                                  child: SizedBox(
                                    width: 32.w,
                                    height: 32.h,
                                    child: Image.asset('images/person.png'),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        commentUsername,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        commentText,
                                        style: TextStyle(fontSize: 14.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwnComment) ...[
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditCommentDialog(context, postId, commentId, commentText);
                                      } else if (value == 'delete') {
                                        _showDeleteCommentDialog(context, postId, commentId);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                    icon: Icon(Icons.more_vert, size: 16.sp),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Comment input
                Container(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 8.h,
                    bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Agrega un comentario...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          ),
                          maxLines: null,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: () async {
                          final comment = commentController.text.trim();
                          if (comment.isNotEmpty) {
                            try {
                              await FirebaseFirestor().addComment(postId: postId, comment: comment);
                              commentController.clear();
                              // No mostrar snackbar para no interrumpir
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al agregar comentario: $e')),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(Icons.send, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sharePost(String imageUrl, String caption, String username) {
    final String text = 'Mira este post de $username: $caption\n$imageUrl';
    Share.share(text);
  }

  void _showEditCommentDialog(BuildContext context, String postId, String commentId, String currentComment) {
    final TextEditingController editController = TextEditingController(text: currentComment);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar comentario'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: 'Edita tu comentario...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final newComment = editController.text.trim();
                if (newComment.isNotEmpty && newComment != currentComment) {
                  try {
                    await FirebaseFirestor().updateComment(
                      postId: postId,
                      commentId: commentId,
                      newComment: newComment,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comentario actualizado')),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al actualizar comentario: $e')),
                      );
                    }
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCommentDialog(BuildContext context, String postId, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar comentario'),
          content: const Text('¿Estás seguro de que quieres eliminar este comentario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestor().deleteComment(
                    postId: postId,
                    commentId: commentId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comentario eliminado')),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar comentario: $e')),
                    );
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePostDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar publicación'),
          content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestor().deletePost(postId: postId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Publicación eliminada')),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar publicación: $e')),
                    );
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: SizedBox(
          width: 105.w,
          height: 28.h,
          child: Image.asset('images/logo_p.png'),
        ),
        
        leading: IconButton(
          onPressed: _openCamera,
          icon: Image.asset('images/camera.jpg'),
        ),
        actions: [
          // **Se eliminaron los botones de 'bug_report' y 'send.jpg'**
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // Horizontal list of users
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100.h,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final uid = docs[index].id;
                      final avatar = (data['profile'] ?? '') as String;
                      final username = (data['username'] ?? '') as String;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(Uid: uid)));
                          },
                          child: Column(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 56.w,
                                  height: 56.h,
                                  child: avatar.isEmpty
                                      ? Image.asset('images/person.png')
                                      : CachedNetworkImage(imageUrl: avatar, fit: BoxFit.cover, errorWidget: (c,s,e)=> Image.asset('images/person.png')),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              SizedBox(width: 60.w, child: Text(username, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Mostrar imágenes subidas recientemente
          if (_uploadedImages.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final imageUrl = _uploadedImages[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250.h,
                    errorBuilder: (c, e, s) => Container(
                      height: 250.h,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                );
              }, childCount: _uploadedImages.length),
            ),

          // Lista de posts desde Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('time', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Error cargando posts')),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No hay publicaciones todavía')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final imageUrl = (data['postImage'] ?? '') as String;
                    final username = (data['username'] ?? 'user') as String;
                    final caption = (data['caption'] ?? '') as String;
                    final postId = docs[index].id;
                    final likes = List.from(data['likes'] ?? []);
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    final isLiked = currentUid != null && likes.contains(currentUid);
                    final postUid = data['uid'] ?? '';
                    final isOwnPost = currentUid == postUid;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado simple
                          ListTile(
                            leading: ClipOval(
                              child: SizedBox(
                                width: 35.w,
                                height: 35.h,
                                child: Image.network(
                                  (data['profileImage'] ?? '' ) as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Image.asset('images/person.png'),
                                ),
                              ),
                            ),
                            title: Text(username, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                            subtitle: Text((data['location'] ?? '') as String, style: TextStyle(fontSize: 11.sp)),
                            trailing: isOwnPost
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeletePostDialog(context, postId);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar publicación'),
                                      ),
                                    ],
                                    icon: const Icon(Icons.more_horiz),
                                  )
                                : const Icon(Icons.more_horiz),
                          ),
                          // Imagen del post
                          SizedBox(
                            width: double.infinity,
                            height: 300.h,
                            child: imageUrl.isEmpty
                                ? Container(color: Colors.grey.shade200)
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      height: 250.h,
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                          ),
                          // Actions row (like, comment, share)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestor().toggleLike(postId: postId);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating like: $e')));
                                    }
                                  },
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.black,
                                  ),
                                ),
                                Text('${likes.length}'),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _showCommentBottomSheet(context, postId, username);
                                      },
                                      icon: const Icon(Icons.comment, color: Colors.black),
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestor().getComments(postId),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data?.docs.length ?? 0;
                                        return Text('$count');
                                      },
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    _sharePost(imageUrl, caption, username);
                                  },
                                  icon: const Icon(Icons.share, color: Colors.black),
                                ),
                              ],
                            ),
                          ),

                          // Caption
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                            child: Row(
                              children: [
                                Text('$username, ', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                Expanded(child: Text(caption, style: TextStyle(fontSize: 13.sp))),
                              ],
                            ),
                          ),


                        ],
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}