import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:app/util/time_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  void _openProfile(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(Uid: uid),
      ),
    );
  }

  void _showCommentBottomSheet() {
    final TextEditingController commentController = TextEditingController();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11162B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.70,
          minChildSize: 0.50,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestor().getComments(widget.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white70),
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
                                  backgroundColor: Colors.white.withOpacity(0.08),
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
                                    color: const Color(0xFF1A2038),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditCommentDialog(
                                          commentId,
                                          commentText,
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteCommentDialog(commentId);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
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
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 8.h,
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).viewPadding.bottom +
                        8.h,
                  ),
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
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
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

                          if (comment.isNotEmpty) {
                            try {
                              await FirebaseFirestor().addComment(
                                postId: widget.postId,
                                comment: comment,
                              );
                              commentController.clear();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al agregar comentario: $e',
                                  ),
                                ),
                              );
                            }
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
        );
      },
    );
  }

  void _showEditCommentDialog(String commentId, String currentComment) {
    final TextEditingController editController =
        TextEditingController(text: currentComment);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final newComment = editController.text.trim();

                if (newComment.isNotEmpty && newComment != currentComment) {
                  try {
                    await FirebaseFirestor().updateComment(
                      postId: widget.postId,
                      commentId: commentId,
                      newComment: newComment,
                    );

                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comentario actualizado')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al actualizar comentario: $e',
                        ),
                      ),
                    );
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

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestor().deleteComment(
                    postId: widget.postId,
                    commentId: commentId,
                  );

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentario eliminado')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al eliminar comentario: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Color(0xFFFF6B7A)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatPill(IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.postData;
    final imageUrl = (data['postImage'] ?? '') as String;
    final username = (data['username'] ?? 'user') as String;
    final caption = (data['caption'] ?? '') as String;
    final location = (data['location'] ?? '') as String;
    final profileImage = (data['profileImage'] ?? '') as String;
    final postUid = (data['uid'] ?? '') as String;
    final likes = List.from(data['likes'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = currentUid != null && likes.contains(currentUid);
    final postTime = formatPostTime(data['time']);

    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Post',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 20.h),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12172C),
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
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
                        width: 46.w,
                        height: 46.h,
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
                            width: 42.w,
                            height: 42.h,
                            child: profileImage.isEmpty
                                ? Image.asset(
                                    'images/person.png',
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: profileImage,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Image.asset(
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
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: SizedBox(
                  width: double.infinity,
                  height: 390.h,
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
                          placeholder: (_, __) => Container(
                            color: Colors.white.withOpacity(0.04),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white.withOpacity(0.04),
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 4.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          await FirebaseFirestor().toggleLike(
                            postId: widget.postId,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al actualizar like: $e',
                              ),
                            ),
                          );
                        }
                      },
                      child: _buildStatPill(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        '${likes.length}',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: _showCommentBottomSheet,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestor().getComments(widget.postId),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return _buildStatPill(
                            Icons.mode_comment_outlined,
                            '$count',
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<bool>(
                      stream: FirebaseFirestor().isPostSaved(widget.postId),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;

                        return IconButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestor().toggleSavePost(
                                postId: widget.postId,
                                postData: widget.postData,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar: $e'),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (caption.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$username ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: caption,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.84),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 18.h),
                child: Text(
                  postTime,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}