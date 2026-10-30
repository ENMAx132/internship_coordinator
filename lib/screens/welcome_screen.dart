import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../screens/apartado_screen.dart';
import '../widgets/dialogos/crear_apartado_dialog.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final List<Apartado> _apartados = apartadosIniciales;
  bool _onboardingCompletado = false;

  void _crearPrimerApartado() async {
    Apartado? apartadoCreado;

    await showDialog<void>(
      context: context,
      builder: (ctx) => CrearApartadoDialog(
        onCrear: (apartado) {
          apartadoCreado = apartado;
        },
      ),
    );

    if (apartadoCreado == null) return;

    // Agregamos el nuevo apartado a la lista general para que no se pierda
    setState(() {
      _apartados.add(apartadoCreado!);
    });

    if (!mounted) return;

    // En lugar de hacer malabares con dos rutas, navegamos directamente
    // a la pantalla de apartados pasándole la lista actualizada de apartados.
    // De esta forma, si el usuario presiona "atrás" desde ApartadoScreen,
    // puedes programar el botón de la AppBar de ApartadoScreen para que regrese a HomeScreen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ApartadoScreen(apartado: apartadoCreado!, apartados: _apartados),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_onboardingCompletado) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 90),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Bienvenido a tu inventario!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Crea tu primer apartado para empezar a organizar tus objetos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 34),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _crearPrimerApartado,
                  child: const Text(
                    'Crear mi primer apartado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Cada apartado agrupa espacios y objetos de tu inventario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
