import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/model/usermodel.dart';
import 'package:app/screen/edit_profile_screen.dart';
import 'package:app/screen/settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatefulWidget {
  final String? Uid;
  const ProfileScreen({super.key, this.Uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isOwnProfile = false;
  bool follow = false;
  late Future<Usermodel> _userFuture;

  String? get _viewUid => widget.Uid ?? _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _refreshProfileState();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.Uid != widget.Uid) {
      _refreshProfileState();
    }
  }

  void _refreshProfileState() {
    final currentUid = _auth.currentUser?.uid;
    final viewUid = _viewUid;

    isOwnProfile = (viewUid != null && currentUid != null && viewUid == currentUid);
    _userFuture = _fetchUserModel();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final viewUid = _viewUid;
    final currentUid = _auth.currentUser?.uid;

    if (viewUid == null || currentUid == null || viewUid == currentUid) {
      if (!mounted) return;
      setState(() {
        follow = false;
      });
      return;
    }

    try {
      final isFollowing = await FirebaseFirestor().isFollowingUser(viewUid);
      if (!mounted) return;
      setState(() {
        follow = isFollowing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        follow = false;
      });
    }
  }

  Future<Usermodel> _fetchUserModel() async {
    final viewUid = _viewUid;
    if (viewUid == null || viewUid.isEmpty) {
      throw Exception('No user id available');
    }

    if (viewUid == _auth.currentUser?.uid) {
      return FirebaseFirestor().getUser();
    }

    return FirebaseFirestor().getUserById(viewUid);
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
    } else if (errorText.contains('not found')) {
      message = 'Usuario no encontrado';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleMainButton(Usermodel user) async {
    if (isOwnProfile) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: user),
        ),
      );

      if (!mounted) return;
      setState(() {
        _refreshProfileState();
      });
      return;
    }

    final viewUid = _viewUid;
    if (viewUid == null || viewUid.isEmpty) return;

    try {
      if (follow) {
        await FirebaseFirestor().unfollowUser(targetUid: viewUid);
      } else {
        await FirebaseFirestor().followUser(targetUid: viewUid);
      }

      await _checkIfFollowing();

      if (!mounted) return;
      setState(() {
        _userFuture = _fetchUserModel();
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openEdit(Usermodel user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user),
      ),
    );

    if (!mounted) return;
    setState(() {
      _refreshProfileState();
    });
  }

  void _showSettingsSheet(Usermodel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(user: user),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFFF6B7A) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTop(Usermodel user) {
    final initials =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF070B1F),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 210.h,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF19114A),
                      Color(0xFF070B1F),
                    ],
                  ),
                ),
                child: user.coverImage.isEmpty
                    ? const SizedBox.shrink()
                    : CachedNetworkImage(
                        imageUrl: user.coverImage,
                        fit: BoxFit.cover,
                        errorWidget: (c, s, e) => const SizedBox.shrink(),
                      ),
              ),
              Positioned(
                top: 14.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: isOwnProfile ? () => _showSettingsSheet(user) : null,
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 19.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: Offset(0, -36.h),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 82.w,
                            height: 82.h,
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF4D56FF),
                                  Color(0xFF8F63FF),
                                ],
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0C1328),
                              ),
                              child: ClipOval(
                                child: user.profile.isEmpty
                                    ? Center(
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: user.profile,
                                        fit: BoxFit.cover,
                                        placeholder: (c, s) => Container(
                                          color: Colors.white.withOpacity(0.05),
                                        ),
                                        errorWidget: (c, s, e) => Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF44D88D),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF070B1F),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 42.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username.isEmpty ? 'Usuario' : user.username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                user.email.isEmpty
                                    ? '@usuario'
                                    : '@${user.email.split('@').first}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.60),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Padding(
                        padding: EdgeInsets.only(top: 42.h),
                        child: SizedBox(
                          height: 36.h,
                          child: OutlinedButton(
                            onPressed: () => _handleMainButton(user),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                            ),
                            child: Text(
                              isOwnProfile
                                  ? 'Editar perfil'
                                  : (follow ? 'Siguiendo' : 'Seguir'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user.bio.isEmpty ? 'Sin biografía' : user.bio,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: const [
                        _ProfileTag(text: '#memes'),
                        _ProfileTag(text: '#gatos'),
                        _ProfileTag(text: '#nocturno'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Usermodel user, String? viewUid) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141A31),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: viewUid == null
                  ? null
                  : _firebaseFirestore
                      .collection('posts')
                      .where('uid', isEqualTo: viewUid)
                      .snapshots(),
              builder: (context, snapshot) {
                final postLength = snapshot.data?.docs.length ?? 0;
                return _StatItem(
                  value: postLength.toString(),
                  label: 'Posts',
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: 56.h,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: _StatItem(
              value: user.followers.length.toString(),
              label: 'Seguidores',
            ),
          ),
          Container(
            width: 1,
            height: 56.h,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: _StatItem(
              value: user.following.length.toString(),
              label: 'Siguiendo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 52.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141A31),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Icon(
                Icons.grid_view_rounded,
                color: Colors.white.withOpacity(0.50),
                size: 22.sp,
              ),
            ),
          ),
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: Center(
              child: Icon(
                Icons.favorite_border,
                color: Colors.white.withOpacity(0.50),
                size: 22.sp,
              ),
            ),
          ),
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4E63FF),
                    Color(0xFF6D7BFF),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.bookmark_border,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(String? viewUid) {
    if (viewUid == null || viewUid.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseFirestore
          .collection('posts')
          .where('uid', isEqualTo: viewUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Error al cargar publicaciones',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No hay publicaciones todavía',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 22.h),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final snap = docs[index];
                final data = snap.data() as Map<String, dynamic>;
                final imageUrl = (data['postImage'] ?? '') as String;

                return GestureDetector(
                  onTap: () {
                    if (imageUrl.isEmpty) return;

                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22.r),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, s) => Container(
                              height: 260.h,
                              color: const Color(0xFF12172C),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (c, s, e) => Container(
                              height: 260.h,
                              color: const Color(0xFF12172C),
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: imageUrl.isEmpty
                        ? Container(
                            color: const Color(0xFF12172C),
                            child: const Icon(Icons.error, color: Colors.white),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, s) => Container(
                              color: const Color(0xFF12172C),
                            ),
                            errorWidget: (c, s, e) => Container(
                              color: const Color(0xFF12172C),
                              child: const Icon(Icons.error, color: Colors.white),
                            ),
                          ),
                  ),
                );
              },
              childCount: docs.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 4.h,
              childAspectRatio: 0.88,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewUid = _viewUid;

    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<Usermodel>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 300.h,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return SizedBox(
                      height: 300.h,
                      child: const Center(
                        child: Text(
                          'No se pudo cargar el perfil',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  final user = snapshot.data!;

                  return Column(
                    children: [
                      _buildProfileTop(user),
                      SizedBox(height: 4.h),
                      _buildStatsCard(user, viewUid),
                      SizedBox(height: 12.h),
                      _buildTabSelector(),
                    ],
                  );
                },
              ),
            ),
            _buildPostsGrid(viewUid),
          ],
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  final String text;
  const _ProfileTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2450),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF3C56D6).withOpacity(0.40),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8FA2FF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}