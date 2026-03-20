import 'package:flutter/material.dart';
import 'package:app/screen/add_screen.dart';
import 'package:app/screen/home.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:app/screen/search_screen.dart';
import 'package:app/screen/notifications_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;
  late final PageController pageController;

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    AddScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _currentIndex = page;
    });
  }

  void navigationTapped(int page) {
    setState(() {
      _currentIndex = page;
    });
    pageController.jumpToPage(page);
  }

  Color _itemColor(int index) {
    return _currentIndex == index
        ? const Color(0xFF5E6BFF)
        : Colors.white.withOpacity(0.45);
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => navigationTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _itemColor(index),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: _itemColor(index),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    final bool isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () => navigationTapped(2),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B5CFF),
              Color(0xFF8B6BFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A6CFF).withOpacity(0.40),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 86,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF090D21),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              label: 'Inicio',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.search,
              label: 'Explorar',
            ),
            Expanded(
              child: Center(
                child: _buildCenterAddButton(),
              ),
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.notifications_none,
              label: 'Avisos',
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.person_outline,
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      extendBody: true,
      bottomNavigationBar: _buildBottomBar(),
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
    );
  }
}