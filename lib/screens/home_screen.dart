import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../widgets/apartado_card.dart';
import '../widgets/dialogos/crear_apartado_dialog.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import '../widgets/dialogos/editar_apartado_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/sector_card.dart';
import 'apartado_screen.dart';
import 'espacio_screen.dart';
import 'historial_screen.dart';
import 'metricas_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Apartado> apartados;

  const HomeScreen({super.key, required this.apartados});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _paginaActual = 0;

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
            notificarCambioInventario();
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
            notificarCambioInventario();
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
            notificarCambioInventario();
          });
          _mostrarAviso('Objeto agregado correctamente.');
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

  void _dialogoEditarApartado(Apartado apartado) {
    showDialog(
      context: context,
      builder: (ctx) => EditarApartadoDialog(
        apartado: apartado,
        onActualizar: (a) {
          setState(() {
            final index = _apartados.indexWhere((item) => item.id == a.id);
            if (index != -1) {
              _apartados[index] = a;
              notificarCambioInventario();
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apartado actualizado con éxito.')),
          );
        },
        onEliminar: (a) {
          setState(() {
            _apartados.removeWhere((item) => item.id == a.id);
            final ids = espaciosIniciales
                .where((e) => e.apartadoId == a.id)
                .map((e) => e.id)
                .toSet();
            espaciosIniciales.removeWhere((e) => e.apartadoId == a.id);
            objetosIniciales.removeWhere((o) => ids.contains(o.espacioId));
            notificarCambioInventario();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apartado eliminado correctamente.'),
            ),
          );
        },
      ),
    );
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
            _construirInicio(),
            _construirApartados(),
            const HistorialScreen(),
            MetricasScreen(apartados: _apartados),
          ],
        ),
      ),
      bottomNavigationBar: _construirBarraNavegacion(),
    );
  }

  Widget _construirInicio() {
    if (_apartados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _construirApartadoVacio(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Inicio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Desliza para cambiar de apartado',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                apartadoInicioId,
                apartadosOrdenVersion,
              ]),
              builder: (context, _) {
                return _InicioApartados(
                  apartados: _apartados,
                  apartadoInicialId: apartadoInicioId.value,
                  ordenVersion: apartadosOrdenVersion.value,
                  onRefresh: () {
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
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
                return GestureDetector(
                  onLongPress: () => _dialogoEditarApartado(apartado),
                  child: ApartadoCard(
                    apartado: apartado,
                    espacios: _espaciosDe(apartado),
                    objetos: _objetosDe(apartado),
                    onTap: () => _abrirApartado(apartado),
                  ),
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
            color: Colors.black.withValues(alpha: 0.03),
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
              color: Colors.black.withValues(alpha: 0.08),
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
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
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

class _InicioApartados extends StatefulWidget {
  final List<Apartado> apartados;
  final String apartadoInicialId;
  final int ordenVersion;
  final VoidCallback onRefresh;

  const _InicioApartados({
    required this.apartados,
    required this.apartadoInicialId,
    required this.ordenVersion,
    required this.onRefresh,
  });

  @override
  State<_InicioApartados> createState() => _InicioApartadosState();
}

class _InicioApartadosState extends State<_InicioApartados> {
  late final PageController _controller;
  late int _pagina;

  @override
  void initState() {
    super.initState();
    _pagina = _indiceInicial();
    _controller = PageController(initialPage: _pagina);
  }

  @override
  void didUpdateWidget(covariant _InicioApartados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apartadoInicialId != widget.apartadoInicialId ||
        oldWidget.ordenVersion != widget.ordenVersion) {
      final nuevoIndice = _indiceInicial();
      if (nuevoIndice != _pagina) {
        setState(() => _pagina = nuevoIndice);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) {
            _controller.jumpToPage(nuevoIndice);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indiceInicial() {
    final indice = widget.apartados.indexWhere(
          (a) => a.id == widget.apartadoInicialId,
    );
    return indice < 0 ? 0 : indice;
  }

  void _abrirApartado(Apartado apartado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartadoScreen(
          apartado: apartado,
          apartados: widget.apartados,
        ),
      ),
    ).then((_) => widget.onRefresh());
  }

  void _abrirEspacio(Espacio espacio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EspacioScreen(espacio: espacio),
      ),
    ).then((_) => widget.onRefresh());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.apartados.length,
            onPageChanged: (index) {
              setState(() => _pagina = index);
            },
            itemBuilder: (context, index) {
              final apartado = widget.apartados[index];
              return _construirPagina(apartado);
            },
          ),
        ),
        if (widget.apartados.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.apartados.length, (index) {
                final activo = index == _pagina;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: activo ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: activo
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _construirPagina(Apartado apartado) {
    final espacios =
    espaciosIniciales.where((e) => e.apartadoId == apartado.id).toList();
    final ids = espacios.map((e) => e.id).toSet();
    final totalObjetos =
        objetosIniciales.where((o) => ids.contains(o.espacioId)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _abrirApartado(apartado),
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
                    imagePath: apartado.imagePath,
                    emoji: apartado.icono,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apartado.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apartado.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${espacios.length} espacios • $totalObjetos objetos',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
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
            Text(
              '${espacios.length} en este apartado',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: espacios.isEmpty
              ? _construirVacio(apartado)
              : GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
            ),
            itemCount: espacios.length,
            itemBuilder: (context, index) {
              final espacio = espacios[index];
              final conteo = objetosIniciales
                  .where((o) => o.espacioId == espacio.id)
                  .length;
              return SectorCard(
                espacio: espacio,
                conteo: conteo,
                isSelected: false,
                onTap: () => _abrirEspacio(espacio),
                onLongPress: () => _abrirApartado(apartado),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _construirVacio(Apartado apartado) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            '${apartado.nombre} aún no tiene espacios',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            onPressed: () => _abrirApartado(apartado),
            child: const Text('Abrir apartado'),
          ),
        ],
      ),
    );
  }
}