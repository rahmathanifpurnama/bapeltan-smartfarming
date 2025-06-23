// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/screens/home_screen.dart';
import 'package:smartfarming_bapeltan/screens/sensor_dashboard.dart';
import 'package:smartfarming_bapeltan/screens/scheduling_screen.dart';
import 'package:smartfarming_bapeltan/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    SensorDashboard(),
    SchedulingScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'Sensor Dashboard',
    'Scheduling',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Montserrat',
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.hijau2,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _titles[_currentIndex],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppColor.hijau1,
          unselectedItemColor: AppColor.abu,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Sensors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.hijau2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.agriculture,
                      size: 40,
                      color: AppColor.hijau1,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Smart Farming',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bapeltan System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Home',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Sensor Dashboard',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.schedule,
                    title: 'Scheduling',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    index: 3,
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.settings, color: AppColor.hijau1),
                    title: Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to settings
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: AppColor.hijau1),
                    title: Text('Help & Support'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to help
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColor.red),
                    title: Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    bool isSelected = _currentIndex == index;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppColor.hijau3 : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColor.hijau1 : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColor.hijau1 : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
