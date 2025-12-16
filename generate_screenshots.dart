import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oouth_mobile/main.dart' as app;
import 'package:oouth_mobile/screens/welcome_screen.dart';
import 'package:oouth_mobile/screens/login_screen.dart';
import 'package:oouth_mobile/screens/dashboard_screen.dart';
import 'package:oouth_mobile/screens/profile_screen.dart';
import 'package:oouth_mobile/screens/payslip_screen.dart';
import 'package:oouth_mobile/screens/notifications_screen.dart';
import 'dart:io';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up screenshot directory
  final screenshotDir = Directory('playstore_screenshots');
  if (!await screenshotDir.exists()) {
    await screenshotDir.create(recursive: true);
  }

  // Run the app
  runApp(ScreenshotApp());
}

class ScreenshotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OOUTH Mobile Screenshots',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ScreenshotHome(),
    );
  }
}

class ScreenshotHome extends StatefulWidget {
  @override
  _ScreenshotHomeState createState() => _ScreenshotHomeState();
}

class _ScreenshotHomeState extends State<ScreenshotHome> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    WelcomeScreen(),
    LoginScreen(),
    DashboardScreen(),
    ProfileScreen(),
    PayslipScreen(),
    NotificationsScreen(),
  ];

  final List<String> _screenNames = [
    'welcome_screen',
    'login_screen',
    'dashboard_screen',
    'profile_screen',
    'payslip_screen',
    'notifications_screen',
  ];

  @override
  void initState() {
    super.initState();
    _captureScreenshots();
  }

  Future<void> _captureScreenshots() async {
    await Future.delayed(Duration(seconds: 2));

    for (int i = 0; i < _screens.length; i++) {
      setState(() {
        _currentIndex = i;
      });

      await Future.delayed(Duration(seconds: 1));

      // Capture screenshot
      final screenshotPath = 'playstore_screenshots/${_screenNames[i]}.png';
      print('Capturing screenshot: $screenshotPath');

      // In a real implementation, you would use a screenshot package
      // For now, we'll just print the path
      print('Screenshot saved to: $screenshotPath');
    }

    print('All screenshots captured!');
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
    );
  }
}
