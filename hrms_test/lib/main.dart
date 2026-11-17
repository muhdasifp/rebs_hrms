import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/theme/app_theme.dart';
import 'package:hrms_test/data/const/app_constant.dart';
import 'package:hrms_test/features/root/view/root_screen.dart';
import 'package:hrms_test/features/setup/base_url_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = await AppConstant.isConfigured();
  runApp(ProviderScope(child: MyApp(configured: configured)));
}

class MyApp extends StatelessWidget {
  final bool configured;
  const MyApp({super.key, this.configured = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REBS HRMS',
      theme: AppTheme.appTheme,
      home: configured ? const RootScreen() : const BaseUrlScreen(),
    );
  }
}
