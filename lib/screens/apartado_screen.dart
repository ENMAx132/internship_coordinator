import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../widgets/dialogos/editar_espacio_dialog.dart';
import '../widgets/dialogos/editar_apartado_dialog.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/sector_card.dart';
import 'espacio_screen.dart';

class ApartadoScreen extends StatefulWidget {
  final Apartado apartado;
  final List<Apartado> apartados;

  const ApartadoScreen(
      {super.key, required this.apartado, required this.apartados});

  @override
  State<ApartadoScreen> createState() => _ApartadoScreenState();
}

class _ApartadoScreenState extends State<ApartadoScreen> {
  late Apartado _apartado;

  @override
  void initState() {
    super.initState();
    _apartado = widget.apartado;
  }

  List<Espacio> get _espacios {
    return espaciosIniciales
        .where((e) => e.apartadoId == _apartado.id)
        .toList();
  }

  List<ObjetoInventario> get _objetos {
    final ids = _espacios.map((e) => e.id).toSet();
    return objetosIniciales.where((o) => ids.contains(o.espacioId)).toList();
  }

  int _conteoPorEspacio(String espacioId) {
    return objetosIniciales.where((o) => o.espacioId == espacioId).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_apartado.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar apartado',
            onPressed: _dialogoEditarApartado,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                      child: IconoWidget(
                        imagePath: _apartado.imagePath,
                        emoji: _apartado.icono,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _apartado.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _apartado.descripcion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_espacios.length} espacios • ${_objetos.length} objetos',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _espacios.isEmpty
                  ? _construirEspacioVacio()
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: _espacios.length,
                      itemBuilder: (context, index) {
                        final espacio = _espacios[index];
                        return SectorCard(
                          espacio: espacio,
                          conteo: _conteoPorEspacio(espacio.id),
                          isSelected: false,
                          onTap: () => _abrirEspacio(espacio),
                          onLongPress: () => _dialogoEditarEspacio(espacio),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEspacioVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
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

  void _abrirEspacio(Espacio espacio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EspacioScreen(espacio: espacio),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _dialogoEditarApartado() {
    showDialog(
      context: context,
      builder: (ctx) => EditarApartadoDialog(
        apartado: _apartado,
        onActualizar: (a) {
          String? imagenAnterior;
          setState(() {
            imagenAnterior = _apartado.imagePath;
            _apartado = a;
            final index =
                widget.apartados.indexWhere((item) => item.id == a.id);
            if (index != -1) {
              widget.apartados[index] = a;
              notificarCambioInventario();
            }
          });
          eliminarImagenHuerfana(imagenAnterior);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apartado actualizado con éxito.')),
          );
        },
        onEliminar: (a) {
          final espacios =
              espaciosIniciales.where((e) => e.apartadoId == a.id).toList();
          final ids = espacios.map((e) => e.id).toSet();
          final objetos = objetosIniciales
              .where((o) => ids.contains(o.espacioId))
              .toList();
          final imagenes = <String?>[
            a.imagePath,
            ...espacios.map((e) => e.imagePath),
            ...objetos.map((o) => o.imagePath),
          ];
          setState(() {
            registrarEliminacionEnHistorial(objetos.map((o) => o.id).toSet());
            widget.apartados.removeWhere((item) => item.id == a.id);
            espaciosIniciales.removeWhere((e) => e.apartadoId == a.id);
            objetosIniciales.removeWhere((o) => ids.contains(o.espacioId));
            notificarCambioInventario();
          });
          Future<void>.delayed(const Duration(seconds: 5), () {
            eliminarImagenesHuerfanas(imagenes);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apartado eliminado correctamente.'),
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _dialogoCrearEspacio() {
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        apartados: [_apartado],
        onCrear: (espacio) {
          setState(() {
            espaciosIniciales.add(espacio);
            notificarCambioInventario();
          });
        },
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
          String? imagenAnterior;
          setState(() {
            final index =
                espaciosIniciales.indexWhere((item) => item.id == e.id);
            if (index != -1) {
              imagenAnterior = espaciosIniciales[index].imagePath;
              espaciosIniciales[index] = e;
              notificarCambioInventario();
            }
          });
          eliminarImagenHuerfana(imagenAnterior);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio actualizado con éxito.')),
          );
        },
        onEliminar: (e) {
          final objetos =
              objetosIniciales.where((o) => o.espacioId == e.id).toList();
          final imagenes = <String?>[
            e.imagePath,
            ...objetos.map((o) => o.imagePath),
          ];
          setState(() {
            registrarEliminacionEnHistorial(objetos.map((o) => o.id).toSet());
            espaciosIniciales.removeWhere((item) => item.id == e.id);
            objetosIniciales.removeWhere((item) => item.espacioId == e.id);
            notificarCambioInventario();
          });
          Future<void>.delayed(const Duration(seconds: 5), () {
            eliminarImagenesHuerfanas(imagenes);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio eliminado correctamente.')),
          );
        },
      ),
    );
  }
}
