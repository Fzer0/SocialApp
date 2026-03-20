import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/model/usermodel.dart';
import 'package:app/screen/edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/screen/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? Uid;
  const ProfileScreen({super.key, this.Uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int postLenght = 0;
  bool isOwnProfile = false;
  bool follow = false;
  late Future<Usermodel> _userFuture;

  @override
  void initState() {
    super.initState();
    final currentUid = _auth.currentUser?.uid;
    final viewUid = widget.Uid ?? currentUid;
    isOwnProfile = (viewUid != null && viewUid == currentUid);
    _userFuture = _fetchUserModel();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final viewUid = widget.Uid ?? _auth.currentUser?.uid;
    final currentUid = _auth.currentUser?.uid;
    if (viewUid == null || currentUid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(viewUid).get();
      final data = doc.data();
      final followers = (data?['followers'] ?? []) as List;

      if (!mounted) return;
      setState(() {
        follow = followers.contains(currentUid);
      });
    } catch (e) {
      print('checkIfFollowing failed: $e');
    }
  }

  Future<Usermodel> _fetchUserModel() async {
    final viewUid = widget.Uid ?? _auth.currentUser?.uid;
    if (viewUid == null) {
      throw Exception('No user id available');
    }

    if (viewUid == _auth.currentUser?.uid) {
      try {
        final user = await FirebaseFirestor().getUser();
        return user;
      } catch (e) {
        print('FirebaseFirestor.getUser() failed: $e');
      }
    }

    try {
      final doc = await _firebaseFirestore.collection('users').doc(viewUid).get();
      final data = doc.data();
      if (data != null) {
        return Usermodel(
          email: (data['email'] ?? '') as String,
          username: (data['username'] ?? '') as String,
          bio: (data['bio'] ?? '') as String,
          profile: (data['profile'] ?? '') as String,
          coverImage: (data['coverImage'] ?? '') as String,
          followers: (data['followers'] ?? []) as List,
          following: (data['following'] ?? []) as List,
        );
      }
    } catch (e) {
      print('read users collection failed: $e');
    }

    try {
      final doc = await _firebaseFirestore.collection('user').doc(viewUid).get();
      final data = doc.data();
      if (data != null) {
        return Usermodel(
          email: (data['email'] ?? '') as String,
          username: (data['username'] ?? '') as String,
          bio: (data['bio'] ?? '') as String,
          profile: (data['profile'] ?? '') as String,
          coverImage: (data['coverImage'] ?? '') as String,
          followers: (data['followers'] ?? []) as List,
          following: (data['following'] ?? []) as List,
        );
      }
    } catch (e) {
      print('read user collection failed: $e');
    }

    throw Exception('User not found');
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
        _userFuture = _fetchUserModel();
      });
      return;
    }

    try {
      final viewUid = widget.Uid ?? _auth.currentUser?.uid;
      if (viewUid == null) return;

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
      print('Follow/unfollow failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
      _userFuture = _fetchUserModel();
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
    final initials = user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';

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
                height: 120.h,
                color: const Color(0xFF070B1F),
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

  Widget _buildStatsCard(Usermodel user) {
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
            child: _StatItem(
              value: postLenght.toString(),
              label: 'Posts',
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

  Widget _buildPostsGrid(String? viewUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseFirestore
          .collection('posts')
          .where('uid', isEqualTo: viewUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        postLenght = docs.length;

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
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
                final imageUrl = snap['postImage'];

                return GestureDetector(
                  onTap: () {
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
                    child: CachedNetworkImage(
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
    final viewUid = widget.Uid ?? _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<Usermodel>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: 300.h,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final user = snapshot.data!;

                  return Column(
                    children: [
                      _buildProfileTop(user),
                      SizedBox(height: 4.h),
                      _buildStatsCard(user),
                      SizedBox(height: 12.h),
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