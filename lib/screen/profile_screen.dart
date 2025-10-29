import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/model/usermodel.dart';
import 'package:app/screen/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  // Si no se pasa Uid, mostrará el perfil del usuario actual
  final String? Uid;
  const ProfileScreen({super.key, this.Uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int post_lenght = 0;
  bool isOwnProfile = false;
  bool follow = false; // estado local si no tienes función de follow en tu Firestore class
  late Future<Usermodel> _userFuture;

  @override
  void initState() {
    super.initState();
    final currentUid = _auth.currentUser?.uid;
    final viewUid = widget.Uid ?? currentUid;
    isOwnProfile = (viewUid != null && viewUid == currentUid);
    _userFuture = _fetchUserModel();
    _checkIfFollowing();
    // No hacemos llamadas largas aquí; el FutureBuilder cargará el user y StreamBuilder las posts
  }

  Future<void> _checkIfFollowing() async {
    final viewUid = widget.Uid ?? _auth.currentUser?.uid;
    final currentUid = _auth.currentUser?.uid;
    if (viewUid == null || currentUid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(viewUid).get();
      final data = doc.data();
      final followers = (data?['followers'] ?? []) as List;
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

    // Si pedimos el perfil propio, intentamos usar la función que ya tienes
    if (viewUid == _auth.currentUser?.uid) {
      try {
        // Firebase_Firestor().getUser() devuelve el Usermodel del usuario actual
        final user = await Firebase_Firestor().getUser();
        return user;
      } catch (e) {
        // Si falla, caemos al fetch directo
        print('Firebase_Firestor.getUser() failed: $e');
      }
    }

    // Lectura directa desde Firestore: intentamos 'users' (creado por CreateUser)
    try {
      final doc = await _firebaseFirestore.collection('users').doc(viewUid).get();
      final data = doc.data();
      if (data != null) {
        return Usermodel(
          email: (data['email'] ?? '') as String,
          username: (data['username'] ?? '') as String,
          bio: (data['bio'] ?? '') as String,
          profile: (data['profile'] ?? '') as String,
          followers: (data['followers'] ?? []) as List,
          following: (data['following'] ?? []) as List,
        );
      }
    } catch (e) {
      print('read users collection failed: $e');
    }

    // Fallback a colección 'user' por compatibilidad si existe
    try {
      final doc = await _firebaseFirestore.collection('user').doc(viewUid).get();
      final data = doc.data();
      if (data != null) {
        return Usermodel(
          email: (data['email'] ?? '') as String,
          username: (data['username'] ?? '') as String,
          bio: (data['bio'] ?? '') as String,
          profile: (data['profile'] ?? '') as String,
          followers: (data['followers'] ?? []) as List,
          following: (data['following'] ?? []) as List,
        );
      }
    } catch (e) {
      print('read user collection failed: $e');
    }

    throw Exception('User not found');
  }

  @override
  Widget build(BuildContext context) {
    final viewUid = widget.Uid ?? _auth.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FutureBuilder<Usermodel>(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Head(snapshot.data!);
                  },
                ),
              ),

              // Grid de posts del usuario
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseFirestore
                    .collection('posts')
                    .where('uid', isEqualTo: viewUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SliverToBoxAdapter(
                        child:
                            const Center(child: CircularProgressIndicator()));
                  }
                  post_lenght = snapshot.data!.docs.length;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final snap = snapshot.data!.docs[index];
                      return GestureDetector(
                        onTap: () {
                          // Mostrar imagen en un dialog simple (no hay PostScreen disponible)
                          showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                    child: CachedNetworkImage(
                                      imageUrl: snap['postImage'],
                                      placeholder: (c, s) => const SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Center(
                                              child: CircularProgressIndicator())),
                                      errorWidget: (c, s, e) => const Icon(Icons.error),
                                    ),
                                  ));
                        },
                        child: CachedNetworkImage(
                          imageUrl: snap['postImage'],
                          fit: BoxFit.cover,
                          placeholder: (c, s) => Container(
                            color: Colors.grey.shade200,
                          ),
                          errorWidget: (c, s, e) => const Icon(Icons.error),
                        ),
                      );
                    }, childCount: post_lenght),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
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

  // ignore: non_constant_identifier_names
  Widget Head(Usermodel user) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
                child: ClipOval(
                  child: SizedBox(
                    width: 80.w,
                    height: 80.h,
                    child: CachedNetworkImage(
                      imageUrl: user.profile,
                      fit: BoxFit.cover,
                      placeholder: (c, s) => Container(color: Colors.grey.shade200),
                      errorWidget: (c, s, e) => const Icon(Icons.person),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 35.w),
                      Text(
                        post_lenght.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(width: 53.w),
                      Text(
                        user.followers.length.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(width: 70.w),
                      Text(
                        user.following.length.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 30.w),
                      Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 25.w),
                      Text(
                        'Followers',
                        style: TextStyle(
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 19.w),
                      Text(
                        'Following',
                        style: TextStyle(
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  user.bio,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 13.w),
            child: GestureDetector(
                      onTap: () async {
                if (isOwnProfile) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)));
                } else {
                  // Llamar a Firestore para follow/unfollow y refrescar vista
                  try {
                    final viewUid = widget.Uid ?? _auth.currentUser?.uid;
                    if (viewUid == null) return;
                    if (follow) {
                      await Firebase_Firestor().unfollowUser(targetUid: viewUid);
                    } else {
                      await Firebase_Firestor().followUser(targetUid: viewUid);
                    }
                    // actualizar estado local y recargar user model
                    await _checkIfFollowing();
                    setState(() {
                      _userFuture = _fetchUserModel();
                    });
                  } catch (e) {
                    print('Follow/unfollow failed: $e');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Container(
                alignment: Alignment.center,
                height: 30.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isOwnProfile ? Colors.white : Colors.blue,
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(color: isOwnProfile ? Colors.grey.shade400 : Colors.blue),
                ),
                child: isOwnProfile
                    ? const Text('Edit Your Profile')
                    : Text(
                        follow ? 'Following' : 'Follow',
                        style: TextStyle(color: follow ? Colors.black : Colors.white),
                      ),
              ),
            ),
          ),

          SizedBox(height: 5.h),
          SizedBox(
            width: double.infinity,
            height: 30.h,
            child: const TabBar(
              unselectedLabelColor: Colors.grey,
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              tabs: [
                Icon(Icons.grid_on),
                Icon(Icons.video_collection),
                Icon(Icons.person),
              ],
            ),
          ),
          SizedBox(
            height: 5.h,
          )
        ],
      ),
    );
  }
}