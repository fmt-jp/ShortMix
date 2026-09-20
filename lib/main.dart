import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

void main() {
  runApp(const ShortMixApp());
}

class ShortMixApp extends StatelessWidget {
  const ShortMixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShortMix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
