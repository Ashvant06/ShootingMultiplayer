import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/home_page.dart';

class ShootingGameApp extends StatelessWidget {
  const ShootingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mythic Siege',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const ShooterHomePage(),
    );
  }
}
