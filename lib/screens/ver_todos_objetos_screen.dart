import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../widgets/icono_widget.dart';

class VerTodosObjetosScreen extends StatefulWidget {
  const VerTodosObjetosScreen({super.key});

  @override
  State<VerTodosObjetosScreen> createState() => _VerTodosObjetosScreenState();
}

class _VerTodosObjetosScreenState extends State<VerTodosObjetosScreen> {
  String _tipoSeleccionado = 'Tipo';
  String _marcaSeleccionada = 'Marca';
  String _estadoSeleccionado = 'Estado';
  final TextEditingController _precioMinCtrl = TextEditingController();
  final TextEditingController _precioMaxCtrl = TextEditingController();
  final TextEditingController _filtroTextoCtrl = TextEditingController();

  List<Espacio> get _misEspacios => espaciosIniciales;

  List<ObjetoInventario> get _todosLosObjetos {
    final lista = [...objetosIniciales]..sort((a, b) => b.valor.compareTo(a.valor));
    return lista;
  }

  List<String> get _marcasDisponibles {
    final marcas = <String>{};
    for (final o in _todosLosObjetos) {
      final m = o.marca.trim();
      if (m.isNotEmpty) marcas.add(m);
    }
    return marcas.toList()..sort();
  }

  List<ObjetoInventario> get _objetosFiltrados {
    var lista = _todosLosObjetos;
    final q = _filtroTextoCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista
          .where((o) =>
      o.nombre.toLowerCase().contains(q) ||
          o.placa.toLowerCase().contains(q) ||
          o.marca.toLowerCase().contains(q))
          .toList();
    }
    if (_tipoSeleccionado != 'Tipo') {
      lista = lista.where((o) => o.categoria == _tipoSeleccionado).toList();
    }
    if (_marcaSeleccionada != 'Marca') {
      lista = lista.where((o) => o.marca == _marcaSeleccionada).toList();
    }
    if (_estadoSeleccionado != 'Estado') {
      lista = lista.where((o) => o.estado == _estadoSeleccionado).toList();
    }
    final min = double.tryParse(_precioMinCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_precioMaxCtrl.text.replaceAll(',', '.'));
    if (min != null) {
      lista = lista.where((o) => o.valor >= min).toList();
    }
    if (max != null) {
      lista = lista.where((o) => o.valor <= max).toList();
    }
    return lista;
  }

  Espacio _espacioDe(String id) {
    for (final e in _misEspacios) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Todos los Objetos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _construirFiltro(
                      valor: _tipoSeleccionado,
                      opciones: <String>['Tipo', ...ObjetoInventario.categoriasDisponibles],
                      onCambio: (v) => setState(() => _tipoSeleccionado = v!),
                    ),
                    const SizedBox(width: 8),
                    _construirFiltro(
                      valor: _marcaSeleccionada,
                      opciones: <String>['Marca', ..._marcasDisponibles],
                      onCambio: (v) => setState(() => _marcaSeleccionada = v!),
                    ),
                    const SizedBox(width: 8),
                    _construirFiltro(
                      valor: _estadoSeleccionado,
                      opciones: <String>['Estado', ...ObjetoInventario.estadosDisponibles],
                      onCambio: (v) => setState(() => _estadoSeleccionado = v!),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _precioMinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio min',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _precioMaxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio max',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _objetosFiltrados.isEmpty
                  ? const Center(
                child: Text('No hay objetos con esos filtros'),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _objetosFiltrados.length,
                itemBuilder: (context, index) {
                  final o = _objetosFiltrados[index];
                  return _construirItem(o);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFiltro({
    required String valor,
    required List<String> opciones,
    required ValueChanged<String?> onCambio,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: false,
          items: opciones
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onCambio,
        ),
      ),
    );
  }

  Widget _construirItem(ObjetoInventario o) {
    final espacio = _espacioDe(o.espacioId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: IconoWidget(
              imagePath: o.imagePath ?? espacio.imagePath,
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
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${o.placa} • ${o.categoria} • ${o.marca}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${o.valor.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 3),
              Text(
                o.estado,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}