import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/widgets/post_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          const Icon(
            Icons.favorite_border_outlined,
            color: Colors.black,
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return PostWidget();
              },
              childCount: 5,
            ),
          ),
        ],
      ),
    );
  }
}