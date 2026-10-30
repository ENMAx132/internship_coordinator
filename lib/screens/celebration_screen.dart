import 'dart:math';

import 'package:flutter/material.dart';

import '../models/apartado.dart';
import '../models/objeto_inventario.dart';
import 'home_screen.dart';

class CelebrationScreen extends StatefulWidget {
  final ObjetoInventario objeto;
  final List<Apartado> apartados;

  const CelebrationScreen({super.key, required this.objeto, required this.apartados});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animacion;

  static const List<String> _letras = ['🎉', '✨', '⭐', '🎊', '💜', '💙', '💚', '💛', '💯', '🔥'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _animacion = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continuar() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(apartados: widget.apartados),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _Confeti(animation: _animacion),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _animacion,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 90),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¡Felicidades!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Creaste tu primer objeto',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.objeto.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _continuar,
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _letras.length; i++) ...[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 700 + (i * 90)),

                      builder: (context, opacidad, _) => Opacity(
                        opacity: opacidad,
                        child: Text(
                          _letras[i],
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                    if (i < _letras.length - 1) const SizedBox(width: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confeti extends CustomPainter {
  final Animation<double> animation;

  _Confeti({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final progreso = animation.value;
    final random = Random(7);
    const colores = <Color>[
      Color(0xFF6366F1),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFF43F5E),
    ];

    for (var i = 0; i < 80; i++) {
      final yInicial = random.nextDouble() * size.height * 0.5;
      final velocidad = 180 + random.nextDouble() * 260;
      final x = random.nextDouble() * size.width;
      final y = yInicial + velocidad * progreso;
      double alpha = 1.0;
      if (progreso > 0.75) {
        final valor = 1.0 - ((progreso - 0.75) / 0.25);
        alpha = valor < 0 ? 0.0 : (valor > 1 ? 1.0 : valor);
      }
      if (alpha <= 0) {
        continue;
      }
      final color = colores[i % colores.length];
      final rotation = progreso * 3.5 + (i % 5) * 0.6;
      canvas.save();
      canvas.translate(x + 3.5, y + 5.5);
      canvas.rotate(rotation);
      final paint = Paint()..color = color.withAlpha((alpha * 255).round());
      canvas.drawRect(const Rect.fromLTWH(-3.5, -5.5, 7, 11), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
