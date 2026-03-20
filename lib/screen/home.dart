import 'dart:async';
import 'dart:io';

import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/screen/addpost_text.dart';
import 'package:app/screen/post_detail_screen.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:app/util/time_format.dart';
import 'package:app/util/upload_bus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app/screen/edit_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final List<String> _uploadedImages = [];
  StreamSubscription<String>? _uploadSub;
  Set<String> followingLocal = {};

  @override
  void initState() {
    super.initState();
    _uploadSub = UploadBus.controller.stream.listen((url) {
      if (!mounted) return;
      setState(() {
        if (!_uploadedImages.contains(url)) {
          _uploadedImages.insert(0, url);
        }
      });
    });
  }

  @override
  void dispose() {
    _uploadSub?.cancel();
    super.dispose();
  }

  void _showErrorMessage(Object e, {String fallback = 'Ocurrió un error'}) {
    if (!mounted) return;

    String message = fallback;
    final errorText = e.toString().toLowerCase();

    if (errorText.contains('permission')) {
      message = 'No tienes permisos para realizar esta acción';
    } else if (errorText.contains('network')) {
      message = 'Error de red. Revisa tu conexión';
    } else if (errorText.contains('auth')) {
      message = 'Debes iniciar sesión nuevamente';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  TextStyle get _popupTextStyle => TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      );

  Future<void> _refreshHome() async {
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && mounted) {
      final file = File(pickedFile.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddPostTextScreen(file),
        ),
      );
    }
  }

  void _sharePost(String imageUrl, String caption, String username) {
    final text = 'Mira este post de $username\n\n$caption\n\n$imageUrl';
    Share.share(text);
  }

  void _openPostDetail(Map<String, dynamic> data, String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: postId,
          postData: data,
        ),
      ),
    );
  }

  void _openProfile(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(Uid: uid),
      ),
    );
  }

void _openEditPost({
  required String postId,
  required String caption,
  required String location,
}) async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EditPostScreen(
        postId: postId,
        initialCaption: caption,
        initialLocation: location,
      ),
    ),
  );

  if (result == true && mounted) {
    setState(() {}); // 👈 refresca Home automáticamente
  }
}

  void _showCommentBottomSheet(BuildContext context, String postId) {
    final TextEditingController commentController = TextEditingController();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF11162B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.50,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(22)),
                      color: Color(0xFF11162B),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comentarios',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalContext).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestor().getComments(postId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No se pudieron cargar los comentarios',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final comments = snapshot.data?.docs ?? [];

                        if (comments.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay comentarios aún',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.only(bottom: 8.h),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final commentDoc = comments[index];
                            final commentData =
                                commentDoc.data() as Map<String, dynamic>;

                            final commentUsername =
                                commentData['username'] ?? 'Usuario';
                            final commentText = commentData['comment'] ?? '';
                            final commentUid = commentData['uid'] ?? '';
                            final commentId = commentDoc.id;
                            final isOwnComment = currentUid == commentUid;

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16.r,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.08),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius:
                                            BorderRadius.circular(14.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            commentUsername,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            commentText,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isOwnComment)
                                    PopupMenuButton<String>(
                                      color: const Color(0xFF202744),
                                      elevation: 12,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14.r),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditCommentDialog(
                                            modalContext,
                                            postId,
                                            commentId,
                                            commentText,
                                          );
                                        } else if (value == 'delete') {
                                          _showDeleteCommentDialog(
                                            modalContext,
                                            postId,
                                            commentId,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(
                                            'Editar',
                                            style: _popupTextStyle,
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Eliminar',
                                            style: _popupTextStyle.copyWith(
                                              color: const Color(0xFFFF8E9E),
                                            ),
                                          ),
                                        ),
                                      ],
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18.sp,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11162B),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Agrega un comentario...',
                              hintStyle:
                                  const TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.06),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          onPressed: () async {
                            final comment = commentController.text.trim();
                            if (comment.isEmpty) return;

                            try {
                              await FirebaseFirestor().addComment(
                                postId: postId,
                                comment: comment,
                              );
                              commentController.clear();
                            } catch (e) {
                              _showErrorMessage(
                                e,
                                fallback: 'Error al agregar comentario',
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF6E76FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showEditCommentDialog(
    BuildContext context,
    String postId,
    String commentId,
    String currentComment,
  ) {
    final TextEditingController editController =
        TextEditingController(text: currentComment);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: const Text(
            'Editar comentario',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: editController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Edita tu comentario...',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF6E76FF)),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newComment = editController.text.trim();

                if (newComment.isEmpty || newComment == currentComment) {
                  Navigator.of(dialogContext).pop();
                  return;
                }

                try {
                  await FirebaseFirestor().updateComment(
                    postId: postId,
                    commentId: commentId,
                    newComment: newComment,
                  );

                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentario actualizado')),
                  );
                } catch (e) {
                  _showErrorMessage(
                    e,
                    fallback: 'Error al actualizar comentario',
                  );
                }
              },
              child: Text(
                'Actualizar',
                style: TextStyle(
                  color: const Color(0xFF7B8CFF),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCommentDialog(
    BuildContext context,
    String postId,
    String commentId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: const Text(
            'Eliminar comentario',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro de que quieres eliminar este comentario?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestor().deleteComment(
                    postId: postId,
                    commentId: commentId,
                  );

                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentario eliminado')),
                  );
                } catch (e) {
                  _showErrorMessage(
                    e,
                    fallback: 'Error al eliminar comentario',
                  );
                }
              },
              child: Text(
                'Eliminar',
                style: TextStyle(
                  color: const Color(0xFFFF6B7A),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePostDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: const Text(
            'Eliminar publicación',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta publicación?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestor().deletePost(postId: postId);

                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicación eliminada')),
                  );
                } catch (e) {
                  _showErrorMessage(
                    e,
                    fallback: 'Error al eliminar publicación',
                  );
                }
              },
              child: Text(
                'Eliminar',
                style: TextStyle(
                  color: const Color(0xFFFF6B7A),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStory(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final avatar = (data['profile'] ?? '') as String;
    final username = (data['username'] ?? '') as String;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
      child: GestureDetector(
        onTap: () => _openProfile(uid),
        child: SizedBox(
          width: 76.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68.w,
                height: 68.h,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5B5CFF),
                      Color(0xFFD86DFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B6CFF).withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF11152A),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 58.w,
                      height: 58.h,
                      child: avatar.isEmpty
                          ? Image.asset(
                              'images/person.png',
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: avatar,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Image.asset(
                                'images/person.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                username.isEmpty ? 'Usuario' : username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.88),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot postDoc) {
    final data = postDoc.data() as Map<String, dynamic>;
    final imageUrl = (data['postImage'] ?? '') as String;
    final username = (data['username'] ?? 'user') as String;
    final caption = (data['caption'] ?? '') as String;
    final location = (data['location'] ?? '') as String;
    final profileImage = (data['profileImage'] ?? '') as String;
    final postId = postDoc.id;
    final likes = List.from(data['likes'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = currentUid != null && likes.contains(currentUid);
    final postUid = (data['uid'] ?? '') as String;
    final isOwnPost = currentUid == postUid;
    final postTime = formatPostTime(data['time']);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12172C),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openProfile(postUid),
                    child: Container(
                      width: 44.w,
                      height: 44.h,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5B5CFF),
                            Color(0xFFD86DFF),
                          ],
                        ),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 40.w,
                          height: 40.h,
                          child: profileImage.isEmpty
                              ? Image.asset(
                                  'images/person.png',
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: profileImage,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    'images/person.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openProfile(postUid),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            location.isNotEmpty ? location : postTime,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
if (!isOwnPost && postUid.isNotEmpty)
  StreamBuilder<bool>(
    key: ValueKey(postUid),
    stream: FirebaseFirestor().isFollowingUserStream(postUid),
    builder: (context, snapshot) {
      final isLoading =
          snapshot.connectionState == ConnectionState.waiting;
      final isFollowing = followingLocal.contains(postUid) || (snapshot.data ?? false);

      return Container(
        height: 34.h,
        margin: EdgeInsets.only(right: 6.w),
        child: OutlinedButton(
          onPressed: isLoading
              ? null
              : () async {
                  try {
                    setState(() {
                      if (isFollowing) {
                        followingLocal.remove(postUid);
                      } else {
                        followingLocal.add(postUid);
                      }
                    });

                    if (isFollowing) {
                      await FirebaseFirestor().unfollowUser(targetUid: postUid);
                    } else {
                      await FirebaseFirestor().followUser(targetUid: postUid);
                    }
                  } catch (e) {}
                },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: const Color(0xFF4E63FF).withOpacity(0.75),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
          child: Text(
            isLoading
                ? '...'
                : (isFollowing ? 'Siguiendo' : 'Seguir'),
            style: TextStyle(
              color: const Color(0xFF7B8CFF),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    },
  ),

                  PopupMenuButton<String>(
                    color: const Color(0xFF202744),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    onSelected: (value) {
                      if (value == 'detail') {
                        _openPostDetail(data, postId);
                      } else if (value == 'edit') {
                        _openEditPost(
                          postId: postId,
                          caption: caption,
                          location: location,
                        );
                      } else if (value == 'delete') {
                        _showDeletePostDialog(context, postId);
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[
                        PopupMenuItem(
                          value: 'detail',
                          child: Text(
                            'Ver detalle',
                            style: _popupTextStyle,
                          ),
                        ),
                      ];

                      if (isOwnPost) {
                        items.addAll([
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Editar publicación',
                              style: _popupTextStyle,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Eliminar publicación',
                              style: _popupTextStyle.copyWith(
                                color: const Color(0xFFFF8E9E),
                              ),
                            ),
                          ),
                        ]);
                      }

                      return items;
                    },
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openPostDetail(data, postId),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: SizedBox(
                  width: double.infinity,
                  height: 360.h,
                  child: imageUrl.isEmpty
                      ? Container(
                          color: Colors.white.withOpacity(0.04),
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.white.withOpacity(0.04),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white.withOpacity(0.04),
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 4.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestor().toggleLike(postId: postId);
                      } catch (e) {
                        _showErrorMessage(
                          e,
                          fallback: 'Error al actualizar like',
                        );
                      }
                    },
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color:
                          isLiked ? const Color(0xFFFF5C8A) : Colors.white,
                    ),
                  ),
                  Text(
                    '${likes.length}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.90),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCommentBottomSheet(context, postId),
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                      color: Colors.white,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestor().getComments(postId),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => _sharePost(imageUrl, caption, username),
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$username ',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: caption,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.84),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUploadedImages() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final imageUrl = _uploadedImages[index];

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12172C),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250.h,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250.h,
                    color: Colors.white.withOpacity(0.04),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: _uploadedImages.length,
      ),
    );
  }

  Widget _buildStoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6.h),
          SizedBox(
            height: 118.h,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox.shrink();
                }

                final docs = snap.data!.docs;

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
                      child: SizedBox(
                        width: 76.w,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _openCamera,
                              child: Container(
                                width: 68.w,
                                height: 68.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.03),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white.withOpacity(0.82),
                                  size: 28.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Publicar',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...docs.map((doc) => _buildUserStory(doc)),
                  ],
                );
              },
            ),
          ),
          _buildSectionTitle('PARA TI'),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Error cargando posts',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay publicaciones todavía',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPostCard(docs[index]),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(88.h),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF070B1F),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'MINGLE',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildStoriesSection(),
            if (_uploadedImages.isNotEmpty) _buildPendingUploadedImages(),
            _buildPostsSection(),
            SliverToBoxAdapter(
              child: SizedBox(height: 120.h),
            ),
          ],
        ),
      ),
    );
  }
}