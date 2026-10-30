import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../screens/celebration_screen.dart';
import '../widgets/dialogos/editar_objeto_dialog.dart';
import '../widgets/dialogos/transferir_dialog.dart';
import '../widgets/item_tile.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';

class EspacioScreen extends StatefulWidget {
  final Espacio espacio;
  final List<Apartado> apartados;

  const EspacioScreen({super.key, required this.espacio, required this.apartados});

  @override
  State<EspacioScreen> createState() => _EspacioScreenState();
}

class _EspacioScreenState extends State<EspacioScreen> {
  late final List<ObjetoInventario> _objetos;

  @override
  void initState() {
    super.initState();
    _objetos = objetosIniciales.where((o) => o.espacioId == widget.espacio.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.espacio.emoji} ${widget.espacio.nombre}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
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
                        widget.espacio.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.espacio.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.espacio.descripcion,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Objetos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_objetos.length} en este espacio',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _objetos.isEmpty
                  ? _construirListaVacia()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _objetos.length,
                      itemBuilder: (context, index) {
                        final obj = _objetos[index];
                        return ItemTile(
                          objeto: obj,
                          espacioAsoc: widget.espacio,
                          onTransferir: () => _dialogoTransferir(obj),
                          onLongPress: () => _dialogoEditarObjeto(obj),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirListaVacia() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text(
            '📦',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aún no hay objetos en este espacio',
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
            onPressed: _dialogoCrearObjeto,
            child: const Text('Agregar primer objeto'),
          ),
        ],
      ),
    );
  }

  void _dialogoCrearObjeto() {
    showDialog(
      context: context,
      builder: (ctx) => CrearObjetoDialog(
        espacios: [widget.espacio],
        placaInicial: 'ACT-00${_objetos.length + 1}',
        onGuardar: (obj) {
          final esPrimer = _objetos.isEmpty;
          setState(() {
            _objetos.add(obj);
          });
          if (esPrimer) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CelebrationScreen(
                  objeto: obj,
                  apartados: widget.apartados,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _dialogoTransferir(ObjetoInventario obj) {
    showDialog(
      context: context,
      builder: (ctx) => TransferirDialog(
        objeto: obj,
        espacios: [widget.espacio],
        onTransferir: (nuevoEspacioId) {
          setState(() {
            obj.espacioId = nuevoEspacioId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activo transferido exitosamente.')),
          );
        },
      ),
    );
  }

  void _dialogoEditarObjeto(ObjetoInventario obj) {
    showDialog(
      context: context,
      builder: (ctx) => EditarObjetoDialog(
        objeto: obj,
        espacios: [widget.espacio],
        onActualizar: (o) {
          setState(() {
            final index = _objetos.indexWhere((item) => item.id == o.id);
            if (index != -1) {
              _objetos[index] = o;
            }
          });
        },
      ),
    );
  }
}
