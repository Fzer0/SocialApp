import 'package:app/screen/post_detail_screen.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentSnapshot> _filterUsers(List<DocumentSnapshot> docs) {
    if (_query.trim().isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final username = (data['username'] ?? '').toString().toLowerCase();
      return username.contains(_query.toLowerCase());
    }).toList();
  }

  List<DocumentSnapshot> _filterPosts(List<DocumentSnapshot> docs) {
    if (_query.trim().isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final username = (data['username'] ?? '').toString().toLowerCase();
      final caption = (data['caption'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();

      return username.contains(_query.toLowerCase()) ||
          caption.contains(_query.toLowerCase()) ||
          location.contains(_query.toLowerCase());
    }).toList();
  }

  void _openProfile(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(Uid: uid),
      ),
    );
  }

  void _openPost(String postId, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: postId,
          postData: data,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _filter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? const Color(0xFF4F63FF)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected
                ? const Color(0xFF6A7CFF)
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5D70FF).withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.70),
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.50),
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required String uid,
    required String username,
    required String profile,
  }) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () => _openProfile(uid),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
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
                  child: profile.isEmpty
                      ? Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: profile,
                          fit: BoxFit.cover,
                          errorWidget: (c, s, e) => Center(
                            child: Text(
                              initial,
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
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.35),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.58),
          fontSize: 13.sp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showUsers = _filter == 'all' || _filter == 'users';
    final showPosts = _filter == 'all' || _filter == 'posts';

    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Explorar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar usuarios o publicaciones...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.55),
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF6E76FF),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 38.h,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'Todo'),
                _buildFilterChip('users', 'Usuarios'),
                _buildFilterChip('posts', 'Posts'),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 120.h),
              children: [
                if (showUsers) ...[
                  _buildSectionTitle('USUARIOS'),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final docs = _filterUsers(snapshot.data!.docs);

                      if (docs.isEmpty) {
                        return _buildEmptyText('No se encontraron usuarios');
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final uid = doc.id;
                            final username = (data['username'] ?? '') as String;
                            final profile = (data['profile'] ?? '') as String;

                            return _buildUserCard(
                              uid: uid,
                              username: username.isEmpty ? 'Usuario' : username,
                              profile: profile,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
                if (showPosts) ...[
                  _buildSectionTitle('PUBLICACIONES'),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance.collection('posts').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final docs = _filterPosts(snapshot.data!.docs);

                      if (docs.isEmpty) {
                        return _buildEmptyText('No se encontraron publicaciones');
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: docs.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6.w,
                          mainAxisSpacing: 6.h,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final imageUrl = (data['postImage'] ?? '') as String;

                          return GestureDetector(
                            onTap: () => _openPost(doc.id, data),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: imageUrl.isEmpty
                                  ? Container(
                                      color: Colors.white.withOpacity(0.05),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white.withOpacity(0.45),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (c, s) => Container(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                      errorWidget: (c, s, e) => Container(
                                        color: Colors.white.withOpacity(0.05),
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white.withOpacity(0.45),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}