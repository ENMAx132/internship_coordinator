import 'package:flutter/material.dart';
import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import '../widgets/dialogos/editar_espacio_dialog.dart';
import '../widgets/dialogos/editar_objeto_dialog.dart';
import '../widgets/dialogos/transferir_dialog.dart';
import '../widgets/dialogos/ver_objetos_dialog.dart';
import '../widgets/sector_card.dart';
import '../widgets/item_tile.dart';


class HomeScreen extends StatefulWidget {
  final List<Apartado> apartados;

  const HomeScreen({super.key, required this.apartados});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Espacio> _espacios = espaciosIniciales;
  final List<ObjetoInventario> _objetos = objetosIniciales;
  List<Apartado> get _apartados => widget.apartados;

  late TabController _tabController;
  int _indiceApartadoActual = 0;
  String _filtroTexto = '';
  String? _espacioSeleccionadoId;
  bool _mostrarTodosObjetos = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _apartados.length, vsync: this);
    _tabController.addListener(() { setState(() { _indiceApartadoActual = _tabController.index; }); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  Apartado get _espacioActual => _apartados[_indiceApartadoActual];

  List<Espacio> get _espaciosDelApartado {
    return _espacios.where((e) => e.apartadoId == _espacioActual.id).toList();
  }

  List<ObjetoInventario> get _objetosDelApartado {
    return _objetos.where((o) {
      if (o.espacioId.isEmpty) return false;
      final espacio = _espacios.firstWhere(
        (e) => e.id == o.espacioId,
        orElse: () => Espacio(
          id: '',
          nombre: 'Desconocido',
          descripcion: '',
          emoji: '📍',
          apartadoId: '',
        ),
      );
      return espacio.apartadoId == _espacioActual.id;
    }).toList();
  }

  List<ObjetoInventario> get _objetosFiltrados {
    var lista = _objetosDelApartado;
    if (_espacioSeleccionadoId != null) {
      lista = lista.where((item) => item.espacioId == _espacioSeleccionadoId).toList();
    }
    if (_filtroTexto.trim().isNotEmpty) {
      final query = _filtroTexto.toLowerCase();
      lista = lista
          .where((item) =>
              item.nombre.toLowerCase().contains(query) ||
              item.placa.toLowerCase().contains(query) ||
              item.responsable.toLowerCase().contains(query))
          .toList();
    }
    return lista;
  }

  int _conteoPorEspacio(String espacioId) {
    return _objetos.where((item) => item.espacioId == espacioId).length;
  }

  double get _valorTotalObjetos {
    return _objetosDelApartado.fold(0.0, (total, objeto) => total + objeto.valor);
  }

  int get _conteoRevision {
    return _objetosDelApartado
        .where((objeto) => objeto.estado.toLowerCase() == 'mantenimiento')
        .length;
  }

  int get _conteoEnUso {
    return _objetosDelApartado.where((objeto) => objeto.espacioId.isNotEmpty).length;
  }

  int get _conteoAreasActivas {
    final idsConObjetos = _objetosDelApartado
        .map((objeto) => objeto.espacioId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return _espacios
        .where((espacio) =>
            espacio.apartadoId == _espacioActual.id && idsConObjetos.contains(espacio.id))
        .length;
  }

  Widget _construirResumen({required String etiqueta, required String valor}) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventario',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  InkWell(
                    onTap: _mostrarMenuAgregar,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _filtroTexto = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar objeto...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _construirResumen(
                      etiqueta: 'Precio total',
                      valor: '${_valorTotalObjetos.toStringAsFixed(2)}',
                    ),
                    _construirResumen(
                      etiqueta: 'En uso',
                      valor: '${_conteoEnUso} objetos',
                    ),
                    _construirResumen(
                      etiqueta: 'Por revisión',
                      valor: '${_conteoRevision} objetos',
                    ),
                    _construirResumen(
                      etiqueta: 'Total',
                      valor: '${_objetosDelApartado.length} objetos',
                    ),
                    _construirResumen(
                      etiqueta: 'Áreas activas',
                      valor: '${_conteoAreasActivas} espacios',
                    ),
                  ],
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _apartados.map((a) => Tab(text: '${a.icono} ${a.nombre}')).toList(),
            ),
            Expanded(
              child: _construirContenido(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
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
          sliver: _espaciosDelApartado.isEmpty
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
                      final espacio = _espaciosDelApartado[index];
                      final conteo = _conteoPorEspacio(espacio.id);
                      final isSelected = _espacioSeleccionadoId == espacio.id;

                      return SectorCard(
                        espacio: espacio,
                        conteo: conteo,
                        isSelected: isSelected,
                        onTap: () => _dialogoVerObjetos(espacio),
                        onLongPress: () => _dialogoEditarEspacio(espacio),
                      );
                    },
                    childCount: _espaciosDelApartado.length,
                  ),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _mostrarTodosObjetos = !_mostrarTodosObjetos;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Todos los Objetos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_objetosFiltrados.length} encontrados',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _mostrarTodosObjetos
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_mostrarTodosObjetos)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: _objetosFiltrados.isEmpty
                ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'No se encontraron objetos en este espacio',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
                : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final obj = _objetosFiltrados[index];
                      final espacioAsoc = _espacios.firstWhere(
                        (e) => e.id == obj.espacioId,
                        orElse: () => Espacio(
                          id: '',
                          nombre: 'Desconocido',
                          descripcion: '',
                          emoji: '📍',
                          apartadoId: '',
                        ),
                      );

                      return ItemTile(
                        objeto: obj,
                        espacioAsoc: espacioAsoc,
                        onTransferir: () => _dialogoTransferir(obj),
                        onLongPress: () => _dialogoEditarObjeto(obj),
                      );
                    },
                    childCount: _objetosFiltrados.length,
                  ),
                ),
          ),
      ],
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

  void _mostrarMenuAgregar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.inventory_2, color: Color(0xFF6366F1)),
                  ),
                  title: const Text('Nuevo Objeto', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Registrar un activo o equipo de oficina'),
                  onTap: () {
                    Navigator.pop(context);
                    _dialogoCrearObjeto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dialogoCrearObjeto() {
    showDialog(
      context: context,
      builder: (ctx) => CrearObjetoDialog(
        espacios: _espaciosDelApartado.isNotEmpty ? _espaciosDelApartado : _espacios,
        placaInicial: 'ACT-00${_objetos.length - -1}',
        onGuardar: _registrarObjeto,
      ),
    );
  }

  void _registrarObjeto(ObjetoInventario obj) {
    setState(() {
      _objetos.add(obj);
    });
  }

  void _dialogoCrearEspacio() {
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        apartados: _apartados,
        onCrear: _registrarEspacio,
      ),
    );
  }

  void _registrarEspacio(Espacio espacio) {
    setState(() {
      _espacios.add(espacio);
    });
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
        apartados: _apartados,
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
            if (_espacioSeleccionadoId == e.id) {
              _espacioSeleccionadoId = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio eliminado correctamente.')),
          );
        },
      ),
    );
  }

  void _dialogoTransferir(ObjetoInventario obj) {
    showDialog(
      context: context,
      builder: (ctx) => TransferirDialog(
        objeto: obj,
        espacios: _espacios,
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
        espacios: _espacios,
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
