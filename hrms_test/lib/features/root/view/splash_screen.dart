import 'package:flutter/material.dart';
import 'package:hrms_test/features/root/view/root_screen.dart';

class SplashScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    _redirect();
    super.initState();
  }

  void _redirect() async {
    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RootScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(Icons.co_present_rounded, size: 35),
            SizedBox(height: 20),
            Text('HRMS', style: TextStyle(fontSize: 22, fontWeight: .bold)),
          ],
        ),
      ),
    );
  }
}
