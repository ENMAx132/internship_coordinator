import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../widgets/icono_widget.dart';

class VerRevisionScreen extends StatefulWidget {
  final List<ObjetoInventario> objetos;

  const VerRevisionScreen({super.key, required this.objetos});

  @override
  State<VerRevisionScreen> createState() => _VerRevisionScreenState();
}

class _VerRevisionScreenState extends State<VerRevisionScreen> {
  final TextEditingController _filtroTextoCtrl = TextEditingController();
  late List<ObjetoInventario> _ordenados;

  @override
  void initState() {
    super.initState();
    _ordenados = widget.objetos
        .where((o) => ObjetoInventario.esEstadoEnRevision(o.estado))
        .toList()
      ..sort((a, b) => b.valor.compareTo(a.valor));
  }

  List<ObjetoInventario> get _objetosEnRevision {
    final q = _filtroTextoCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return List.of(_ordenados);
    return _ordenados
        .where((o) =>
            o.nombre.toLowerCase().contains(q) ||
            o.placa.toLowerCase().contains(q) ||
            o.marca.toLowerCase().contains(q))
        .toList();
  }

  void _reordenar(int oldIndex, int newIndex) {
    final visibles = List.of(_objetosEnRevision);
    final idsVisibles = visibles.map((o) => o.id).toSet();
    final movido = visibles.removeAt(oldIndex);
    visibles.insert(newIndex, movido);

    setState(() {
      var j = 0;
      for (var i = 0; i < _ordenados.length; i++) {
        if (idsVisibles.contains(_ordenados[i].id)) {
          _ordenados[i] = visibles[j++];
        }
      }
    });
  }

  void _editarEstado(ObjetoInventario objeto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cambiar estado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ObjetoInventario.estadosDisponibles.map((estado) {
              final seleccionado = objeto.estado == estado;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  seleccionado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: seleccionado
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                ),
                title: Text(estado),
                onTap: () {
                  Navigator.pop(ctx);
                  _actualizarEstado(objeto, estado);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _actualizarEstado(ObjetoInventario objeto, String nuevoEstado) {
    if (nuevoEstado == objeto.estado) return;

    final actualizado = ObjetoInventario(
      id: objeto.id,
      placa: objeto.placa,
      nombre: objeto.nombre,
      espacioId: objeto.espacioId,
      categoria: objeto.categoria,
      estado: nuevoEstado,
      valor: objeto.valor,
      responsable: objeto.responsable,
      marca: objeto.marca,
      fechaRegistro: objeto.fechaRegistro,
      fechaEnRevision: ObjetoInventario.esEstadoEnRevision(nuevoEstado)
          ? DateTime.now()
          : objeto.fechaEnRevision,
      imagePath: objeto.imagePath,
    );

    setState(() {
      final indexGlobal =
          objetosIniciales.indexWhere((item) => item.id == objeto.id);
      if (indexGlobal != -1) {
        objetosIniciales[indexGlobal] = actualizado;
      }
      final indexLocal = _ordenados.indexWhere((item) => item.id == objeto.id);
      if (indexLocal != -1) {
        if (ObjetoInventario.esEstadoEnRevision(nuevoEstado)) {
          _ordenados[indexLocal] = actualizado;
        } else {
          _ordenados.removeAt(indexLocal);
        }
      }
    });
    notificarCambioInventario();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estado actualizado correctamente.')),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  Espacio _espacioDe(String id) {
    for (final e in espaciosIniciales) {
      if (e.id == id) return e;
    }
    return Espacio(
      id: '',
      nombre: 'Sin espacio',
      descripcion: '',
      emoji: 'X',
      apartadoId: '',
    );
  }

  @override
  void dispose() {
    _filtroTextoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objetos = _objetosEnRevision;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'En Revisión',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _filtroTextoCtrl,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, placa o marca...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_outlined,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${objetos.length} objeto${objetos.length == 1 ? '' : 's'} en revisión • Arrastra para ordenar por importancia',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: objetos.isEmpty
                  ? const Center(
                      child: Text('No hay objetos en revisión'),
                    )
                  : ReorderableListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: objetos.length,
                      buildDefaultDragHandles: false,
                      onReorderItem: _reordenar,
                      itemBuilder: (context, index) {
                        return _construirItem(objetos[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirItem(ObjetoInventario o, int index) {
    final espacio = _espacioDe(o.espacioId);
    final prioridad = _ordenados.indexWhere((x) => x.id == o.id) + 1;
    return GestureDetector(
      key: ValueKey(o.id),
      onLongPress: () => _editarEstado(o),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$prioridad',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: IconoWidget(
                imagePath:
                    (o.imagePath != null && o.imagePath!.trim().isNotEmpty)
                        ? o.imagePath
                        : espacio.imagePath,
                emoji: espacio.emoji,
                fontSize: 20,
                size: 42,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${o.categoria} • ${o.marca}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    espacio.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatearFecha(o.fechaEnRevision),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${o.valor.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    o.estado,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 36,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.drag_indicator,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
