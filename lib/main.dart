import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(const OfficeInventoryApp());
}

class OfficeInventoryApp extends StatelessWidget {
  const OfficeInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario de Oficina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Tono Índigo Moderno
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}