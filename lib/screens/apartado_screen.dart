import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../widgets/dialogos/editar_espacio_dialog.dart';
import '../widgets/dialogos/ver_objetos_dialog.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/sector_card.dart';
import '../screens/espacio_screen.dart';
import 'home_screen.dart';

class ApartadoScreen extends StatefulWidget {
  final Apartado apartado;
  final List<Apartado> apartados;

  const ApartadoScreen({super.key, required this.apartado, required this.apartados});

  @override
  State<ApartadoScreen> createState() => _ApartadoScreenState();
}

class _ApartadoScreenState extends State<ApartadoScreen> {
  late final List<Espacio> _espacios;
  late final List<ObjetoInventario> _objetos;

  @override
  void initState() {
    super.initState();
    _espacios = espaciosIniciales.where((e) => e.apartadoId == widget.apartado.id).toList();
    _objetos = objetosIniciales
        .where((o) => _espacios.any((e) => e.id == o.espacioId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Sobrescribimos el botón de atrás para que vaya directo a HomeScreen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(apartados: widget.apartados), // Le pasas la lista actual de apartados
              ),
                  (route) => false, // Borra el historial anterior para que no dé error
            );
          },
        ),
        title: Text(widget.apartado.nombre),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          widget.apartado.icono,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.apartado.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.apartado.descripcion,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Espacios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: _dialogoCrearEspacio,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _espacios.isEmpty
                  ? SliverToBoxAdapter(
                      child: _construirEspacioVacio(),
                    )
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final espacio = _espacios[index];
                          final conteo = _objetos
                              .where((o) => o.espacioId == espacio.id)
                              .length;
                          return SectorCard(
                            espacio: espacio,
                            conteo: conteo,
                            isSelected: false,
                            onTap: () => _dialogoVerObjetos(espacio),
                            onLongPress: () => _dialogoEditarEspacio(espacio),
                          );
                        },
                        childCount: _espacios.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _construirEspacioVacio() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text(
            '🗂️',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aún no hay espacios en este apartado',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: _dialogoCrearEspacio,
            child: const Text('Agregar espacio'),
          ),
        ],
      ),
    );
  }

  void _dialogoCrearEspacio() {
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        apartados: [widget.apartado],
        onCrear: (espacio) {
          final esPrimer = _espacios.isEmpty;
          setState(() {
            _espacios.add(espacio);
          });
          if (esPrimer) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EspacioScreen(
                  espacio: espacio,
                  apartados: widget.apartados,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _dialogoVerObjetos(Espacio espacio) {
    final objetos = _objetos.where((o) => o.espacioId == espacio.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => VerObjetosDialog(
        espacio: espacio,
        objetos: objetos,
      ),
    );
  }

  void _dialogoEditarEspacio(Espacio espacio) {
    showDialog(
      context: context,
      builder: (ctx) => EditarEspacioDialog(
        espacio: espacio,
        apartados: widget.apartados,
        onActualizar: (e) {
          setState(() {
            final index = _espacios.indexWhere((item) => item.id == e.id);
            if (index != -1) {
              _espacios[index] = e;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio actualizado con éxito.')),
          );
        },
        onEliminar: (e) {
          setState(() {
            _espacios.removeWhere((item) => item.id == e.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio eliminado correctamente.')),
          );
        },
      ),
    );
  }
}
