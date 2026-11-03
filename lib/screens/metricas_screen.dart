import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import 'ajustes_screen.dart';
import 'ver_todos_objetos_screen.dart';

class MetricasScreen extends StatefulWidget {
  final List<Apartado> apartados;

  const MetricasScreen({super.key, required this.apartados});

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  String? _apartadoSeleccionadoId;

  List<Espacio> get _espacios {
    if (_apartadoSeleccionadoId == null) return espaciosIniciales;
    return espaciosIniciales
        .where((e) => e.apartadoId == _apartadoSeleccionadoId)
        .toList();
  }

  List<ObjetoInventario> get _objetos {
    final ids = _espacios.map((e) => e.id).toSet();
    return objetosIniciales.where((o) => ids.contains(o.espacioId)).toList();
  }

  double get _valorTotal {
    return _objetos.fold(0.0, (total, objeto) => total + objeto.valor);
  }

  int get _objetosEnRevision {
    return _objetos
        .where((o) => o.estado.toLowerCase() == 'mantenimiento')
        .length;
  }

  List<Espacio> _espaciosDe(Apartado apartado) {
    return espaciosIniciales.where((e) => e.apartadoId == apartado.id).toList();
  }

  List<ObjetoInventario> _objetosDe(Apartado apartado) {
    final ids = _espaciosDe(apartado).map((e) => e.id).toSet();
    return objetosIniciales.where((o) => ids.contains(o.espacioId)).toList();
  }

  double _valorDe(Apartado apartado) {
    return _objetosDe(apartado)
        .fold(0.0, (total, objeto) => total + objeto.valor);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Métricas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Resumen general y por apartado',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF6366F1),
                ),
                tooltip: 'Ajustes',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AjustesScreen(apartados: widget.apartados),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _construirChip('Todos', _apartadoSeleccionadoId == null, () {
                setState(() => _apartadoSeleccionadoId = null);
              }),
              const SizedBox(width: 8),
              ...widget.apartados.map(
                    (apartado) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _construirChip(
                    '${apartado.icono} ${apartado.nombre}',
                    _apartadoSeleccionadoId == apartado.id,
                        () {
                      setState(() => _apartadoSeleccionadoId = apartado.id);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _construirMetrica(
                icono: Icons.grid_view_rounded,
                etiqueta: 'Espacios',
                valor: '${_espacios.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _construirMetrica(
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Objetos',
                valor: '${_objetos.length}',
                onTap: () async {
                  // Navega a la pantalla de todos los objetos y actualiza al volver
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerTodosObjetosScreen(),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _construirMetrica(
                icono: Icons.attach_money,
                etiqueta: 'Valor total',
                valor: '\$${_valorTotal.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _construirMetrica(
                icono: Icons.build_outlined,
                etiqueta: 'En revisión',
                valor: '$_objetosEnRevision',
              ),
            ),
          ],
        ),
        if (_apartadoSeleccionadoId == null) ...[
          const SizedBox(height: 24),
          const Text(
            'Detalle por apartado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...widget.apartados.map(_construirApartado),
        ],
      ],
    );
  }

  Widget _construirChip(String texto, bool seleccionado, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _construirMetrica({
    required IconData icono,
    required String etiqueta,
    required String valor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 20, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirApartado(Apartado apartado) {
    final espacios = _espaciosDe(apartado);
    final objetos = _objetosDe(apartado);
    return GestureDetector(
      onTap: () {
        setState(() => _apartadoSeleccionadoId = apartado.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(apartado.icono, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    apartado.nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child:
                  _construirMiniMetrica('${espacios.length}', 'Espacios'),
                ),
                Expanded(
                  child: _construirMiniMetrica('${objetos.length}', 'Objetos'),
                ),
                Expanded(
                  child: _construirMiniMetrica(
                    '\$${_valorDe(apartado).toStringAsFixed(0)}',
                    'Valor',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirMiniMetrica(String valor, String etiqueta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}