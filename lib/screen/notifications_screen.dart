import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int selectedFilter = 0;

  final List<String> filters = [
    'Todo',
    'Me gusta',
    'Comentarios',
    'Nuevos seguidores',
  ];

  void _openProfile(String uid) {
    if (uid.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(Uid: uid),
      ),
    );
  }

  bool _matchesFilter(String type) {
    if (selectedFilter == 0) return true;
    if (selectedFilter == 1) return type == 'like';
    if (selectedFilter == 2) return type == 'comment';
    if (selectedFilter == 3) return type == 'follow';
    return true;
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'Ahora';
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }

  void _showError(Object e) {
    if (!mounted) return;

    String message = 'Ocurrió un error';
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

  Widget _buildFilterChip(String text, int index) {
    final isSelected = selectedFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected
              ? const Color(0xFF4F63FF)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6A7CFF)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.70),
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String profileImage, String username, String type) {
    String reaction = '❤️';
    if (type == 'comment') reaction = '💬';
    if (type == 'follow') reaction = '🟢';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46.w,
          height: 46.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: ClipOval(
            child: profileImage.isEmpty
                ? Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: profileImage,
                    fit: BoxFit.cover,
                    errorWidget: (c, s, e) => Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18.w,
            height: 18.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4F63FF),
              border: Border.all(
                color: const Color(0xFF070B1F),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                reaction,
                style: TextStyle(fontSize: 8.sp),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(Map<String, dynamic> item) {
    final type = (item['type'] ?? '') as String;
    final postImage = (item['postImage'] ?? '') as String;
    final fromUid = (item['fromUid'] ?? '') as String;

    if (type == 'follow') {
      if (fromUid.isEmpty) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<bool>(
        future: FirebaseFirestor().isFollowingUser(fromUid),
        builder: (context, snapshot) {
          final isFollowing = snapshot.data ?? false;

          return GestureDetector(
            onTap: () async {
              try {
                if (isFollowing) {
                  await FirebaseFirestor().unfollowUser(targetUid: fromUid);
                } else {
                  await FirebaseFirestor().followUser(targetUid: fromUid);
                }
                if (mounted) setState(() {});
              } catch (e) {
                _showError(e);
              }
            },
            child: Container(
              height: 34.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4D5FFF),
                    Color(0xFF6F7DFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D70FF).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isFollowing ? 'Siguiendo' : 'Seguir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: 46.w,
      height: 46.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: postImage.isEmpty
            ? Center(
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.white54,
                  size: 20.sp,
                ),
              )
            : CachedNetworkImage(
                imageUrl: postImage,
                fit: BoxFit.cover,
                errorWidget: (c, s, e) => Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white54,
                    size: 20.sp,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot doc) {
    final item = doc.data() as Map<String, dynamic>;

    final type = (item['type'] ?? '') as String;
    final username = (item['fromUsername'] ?? 'Usuario') as String;
    final profileImage = (item['fromProfileImage'] ?? '') as String;
    final fromUid = (item['fromUid'] ?? '') as String;
    final commentText = (item['commentText'] ?? '') as String;
    final createdAt = item['createdAt'] as Timestamp?;
    final isRead = (item['isRead'] ?? false) as bool;

    String text = '';
    if (type == 'like') {
      text = 'le dio me gusta a tu publicación';
    } else if (type == 'comment') {
      text = commentText.isEmpty
          ? 'comentó en tu publicación'
          : 'comentó: "$commentText"';
    } else if (type == 'follow') {
      text = 'comenzó a seguirte';
    } else {
      text = 'interactuó contigo';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openProfile(fromUid),
            child: _buildAvatar(profileImage, username, type),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(fromUid),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$username ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          _buildTrailing(item),
          SizedBox(width: 8.w),
          if (!isRead)
            Container(
              width: 8.w,
              height: 8.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4F63FF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h, bottom: 10.h),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 13.sp,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 38.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    return _buildFilterChip(filters[index], index);
                  },
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestor().getNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error cargando notificaciones',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = (data['type'] ?? '') as String;
                      return _matchesFilter(type);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay notificaciones',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }

                    return ListView(
                      children: [
                        _buildSectionTitle('AVISOS'),
                        ...filteredDocs.map(_buildNotificationItem),
                        SizedBox(height: 30.h),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}