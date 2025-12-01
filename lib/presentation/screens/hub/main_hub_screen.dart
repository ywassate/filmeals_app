import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/presentation/screens/hub/tabs/home_tab.dart';
import 'package:filmeals_app/presentation/screens/hub/tabs/meals_tab.dart';
import 'package:filmeals_app/presentation/screens/hub/tabs/sleep_tab.dart';
import 'package:filmeals_app/presentation/screens/hub/tabs/location_tab.dart';
import 'package:filmeals_app/presentation/screens/hub/tabs/social_tab.dart';

/// Écran principal avec navigation par tabs
class MainHubScreen extends StatefulWidget {
  final LocalStorageService storageService;

  const MainHubScreen({super.key, required this.storageService});

  @override
  State<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends State<MainHubScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2; // Start on Home tab (center position)
  late PageController _pageController;
  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2); // Start on Home tab (center)
    _tabs = [
      MealsTab(storageService: widget.storageService),
      SleepTab(storageService: widget.storageService),
      HomeTab(storageService: widget.storageService),
      const LocationTab(),
      SocialTab(storageService: widget.storageService),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenu des pages
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _tabs,
          ),
          // Floating tab bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.restaurant_rounded,
                      label: 'Meals',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.bedtime_rounded,
                      label: 'Sleep',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.location_on_rounded,
                      label: 'Activity',
                      index: 3,
                    ),
                    _buildNavItem(
                      icon: Icons.people_rounded,
                      label: 'Social',
                      index: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône sans cadre
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 4),
            // Label en anglais
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
