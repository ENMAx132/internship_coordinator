import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../widgets/apartado_card.dart';
import '../widgets/dialogos/crear_apartado_dialog.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import 'apartado_screen.dart';
import 'historial_screen.dart';
import 'metricas_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Apartado> apartados;

  const HomeScreen({super.key, required this.apartados});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _paginaActual = 1;

  List<Apartado> get _apartados => widget.apartados;

  int _espaciosDe(Apartado apartado) {
    return espaciosIniciales.where((e) => e.apartadoId == apartado.id).length;
  }

  int _objetosDe(Apartado apartado) {
    final ids = espaciosIniciales
        .where((e) => e.apartadoId == apartado.id)
        .map((e) => e.id)
        .toSet();
    return objetosIniciales.where((o) => ids.contains(o.espacioId)).length;
  }

  int get _totalEspacios => espaciosIniciales.length;

  int get _totalObjetos => objetosIniciales.length;

  void _crearApartado() {
    showDialog(
      context: context,
      builder: (ctx) => CrearApartadoDialog(
        onCrear: (apartado) {
          setState(() {
            _apartados.add(apartado);
          });
        },
      ),
    );
  }

  void _crearEspacio() {
    if (_apartados.isEmpty) {
      _mostrarAviso('Crea primero un apartado.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        apartados: _apartados,
        onCrear: (espacio) {
          setState(() {
            espaciosIniciales.add(espacio);
          });
        },
      ),
    );
  }

  void _crearObjeto() {
    if (espaciosIniciales.isEmpty) {
      _mostrarAviso('Crea primero un espacio.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CrearObjetoDialog(
        espacios: espaciosIniciales,
        placaInicial: 'ACT-00${objetosIniciales.length + 1}',
        onGuardar: (objeto) {
          setState(() {
            objetosIniciales.add(objeto);
          });
        },
      ),
    );
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _abrirApartado(Apartado apartado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartadoScreen(
          apartado: apartado,
          apartados: _apartados,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _mostrarMenuAgregar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.apartment, color: Color(0xFF6366F1)),
                  ),
                  title: const Text(
                    'Nuevo Apartado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Agrupa espacios y objetos'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _crearApartado();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child:
                        Icon(Icons.grid_view_rounded, color: Color(0xFF6366F1)),
                  ),
                  title: const Text(
                    'Nuevo Espacio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Crea un espacio dentro de un apartado'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _crearEspacio();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.inventory_2, color: Color(0xFF6366F1)),
                  ),
                  title: const Text(
                    'Nuevo Objeto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Registra un activo o equipo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _crearObjeto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _paginaActual,
          children: [
            const SizedBox.expand(),
            _construirApartados(),
            HistorialScreen(),
            MetricasScreen(apartados: _apartados),
          ],
        ),
      ),
      bottomNavigationBar: _construirBarraNavegacion(),
    );
  }

  Widget _construirApartados() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Apartados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Selecciona un apartado para ver sus espacios',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _construirResumen(
                  etiqueta: 'Apartados',
                  valor: '${_apartados.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _construirResumen(
                  etiqueta: 'Espacios',
                  valor: '$_totalEspacios',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _construirResumen(
                  etiqueta: 'Objetos',
                  valor: '$_totalObjetos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Todos los apartados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${_apartados.length} en total',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _apartados.isEmpty
                ? _construirApartadoVacio()
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _apartados.length,
                    itemBuilder: (context, index) {
                      final apartado = _apartados[index];
                      return ApartadoCard(
                        apartado: apartado,
                        espacios: _espaciosDe(apartado),
                        objetos: _objetosDe(apartado),
                        onTap: () => _abrirApartado(apartado),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirResumen({required String etiqueta, required String valor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirApartadoVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          const Text(
            'Aún no hay apartados',
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
            onPressed: _crearApartado,
            child: const Text('Crear apartado'),
          ),
        ],
      ),
    );
  }

  Widget _construirBarraNavegacion() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _construirItemNav(
              icono: Icons.home_outlined,
              iconoActivo: Icons.home_rounded,
              etiqueta: 'Inicio',
              pagina: 0,
            ),
            _construirItemNav(
              icono: Icons.grid_view_outlined,
              iconoActivo: Icons.grid_view_rounded,
              etiqueta: 'Apartados',
              pagina: 1,
            ),
            _construirBotonAgregar(),
            _construirItemNav(
              icono: Icons.chat_bubble_outline,
              iconoActivo: Icons.chat_bubble,
              etiqueta: 'Historial',
              pagina: 2,
            ),
            _construirItemNav(
              icono: Icons.person_outline,
              iconoActivo: Icons.person,
              etiqueta: 'Métricas',
              pagina: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirItemNav({
    required IconData icono,
    required IconData iconoActivo,
    required String etiqueta,
    required int pagina,
  }) {
    final seleccionado = _paginaActual == pagina;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paginaActual = pagina;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: seleccionado ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                seleccionado ? iconoActivo : icono,
                size: 22,
                color: seleccionado
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: seleccionado
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBotonAgregar() {
    return Expanded(
      child: GestureDetector(
        onTap: _mostrarMenuAgregar,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 2),
            const Text(
              'Agregar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
