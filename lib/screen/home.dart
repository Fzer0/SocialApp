import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:app/widgets/post_widget.dart';
import 'package:app/util/upload_bus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:app/data/firebase_service/firestor.dart';

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
          onPressed: () {},
          icon: Image.asset('images/camera.jpg'),
        ),
        actions: [
          IconButton(
            tooltip: 'Debug posts',
            icon: const Icon(Icons.bug_report, color: Colors.black),
            onPressed: () async {
              try {
                final snapshot = await FirebaseFirestore.instance.collection('posts').orderBy('time', descending: true).get();
                final docs = snapshot.docs;
                print('🔎 Debug fetch posts: count=${docs.length}');
                final sample = docs.take(5).map((d) => d.data()).toList();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Debug posts'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Found ${docs.length} documents in posts collection.'),
                          const SizedBox(height: 8),
                          Text('Sample (up to 5):'),
                          const SizedBox(height: 8),
                          for (var item in sample) Text(item.toString()),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                    ],
                  ),
                );
              } catch (e) {
                print('🔎 Debug fetch posts error: $e');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
              }
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          IconButton(
            onPressed: () {},
            icon: Image.asset('images/send.jpg'),
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
                            trailing: const Icon(Icons.more_horiz),
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
                          // Actions row (like etc.)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await Firebase_Firestor().toggleLike(postId: postId);
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
                              ],
                            ),
                          ),

                          // Caption
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                            child: Row(
                              children: [
                                Text(username + ', ', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
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