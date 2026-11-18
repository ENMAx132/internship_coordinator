import 'package:flutter/material.dart';

import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/inventory_item.dart';
import '../widgets/icono_widget.dart';
import '../widgets/offline_banner.dart';

class VerTodosObjetosScreen extends StatefulWidget {
  final int? sectionId;

  const VerTodosObjetosScreen({super.key, this.sectionId});

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

  InventoryStore get _store => InventoryScope.of(context);

  List<InventoryItem> _todos(InventoryStore store) {
    final sectionId = widget.sectionId;
    final lista = sectionId == null
        ? [...store.items]
        : store.itemsForSection(sectionId);
    lista.sort((a, b) => b.value.compareTo(a.value));
    return lista;
  }

  List<String> _marcasDisponibles(List<InventoryItem> items) {
    final marcas = <String>{};
    for (final item in items) {
      final marca = item.brand.trim();
      if (marca.isNotEmpty) marcas.add(marca);
    }
    return marcas.toList()..sort();
  }

  List<InventoryItem> _filtrados(InventoryStore store) {
    var lista = _todos(store);
    final q = _filtroTextoCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista
          .where(
            (item) =>
                item.name.toLowerCase().contains(q) ||
                item.code.toLowerCase().contains(q) ||
                item.brand.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_tipoSeleccionado != 'Tipo') {
      lista = lista
          .where((item) => item.category.name == _tipoSeleccionado)
          .toList();
    }
    if (_marcaSeleccionada != 'Marca') {
      lista = lista
          .where((item) => item.brand == _marcaSeleccionada)
          .toList();
    }
    if (_estadoSeleccionado != 'Estado') {
      lista = lista
          .where((item) => item.status.name == _estadoSeleccionado)
          .toList();
    }
    final min = double.tryParse(_precioMinCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_precioMaxCtrl.text.replaceAll(',', '.'));
    if (min != null) {
      lista = lista.where((item) => item.value >= min).toList();
    }
    if (max != null) {
      lista = lista.where((item) => item.value <= max).toList();
    }
    return lista;
  }

  @override
  void dispose() {
    _precioMinCtrl.dispose();
    _precioMaxCtrl.dispose();
    _filtroTextoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final todos = _todos(store);
    final objetos = _filtrados(store);
    final marcas = _marcasDisponibles(todos);

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
          'Todos los Objetos',
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
            if (store.offline)
              OfflineBanner(
                message: 'Sin conexión. Mostrando objetos guardados.',
                onRetry: store.retryConnection,
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _construirFiltro(
                      valor: _tipoSeleccionado,
                      opciones: <String>[
                        'Tipo',
                        ...store.catalogs.categories.map((e) => e.name),
                      ],
                      onCambio: (v) => setState(() => _tipoSeleccionado = v!),
                    ),
                    const SizedBox(width: 8),
                    _construirFiltro(
                      valor: _marcaSeleccionada,
                      opciones: <String>['Marca', ...marcas],
                      onCambio: (v) => setState(() => _marcaSeleccionada = v!),
                    ),
                    const SizedBox(width: 8),
                    _construirFiltro(
                      valor: _estadoSeleccionado,
                      opciones: <String>[
                        'Estado',
                        ...store.catalogs.statuses.map((e) => e.name),
                      ],
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
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
              child: objetos.isEmpty
                  ? const Center(
                      child: Text('No hay objetos con esos filtros'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: objetos.length,
                      itemBuilder: (context, index) {
                        return _construirItem(store, objetos[index]);
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

  Widget _construirItem(InventoryStore store, InventoryItem item) {
    final space = store.spaceById(item.spaceId);
    return Container(
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
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: IconoWidget(
              imageUrl: item.imageUrl ?? space?.imageUrl,
              emoji: space?.emoji ?? item.spaceEmoji,
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
                  item.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.code} • ${item.category.name} • ${item.brand}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.value.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.status.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
