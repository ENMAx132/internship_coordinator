import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/inventario_data.dart';
import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../models/registro_revision.dart';
import '../widgets/apartado_card.dart';
import '../widgets/dialogos/crear_apartado_dialog.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import '../widgets/dialogos/editar_apartado_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/sector_card.dart';
import '../widgets/tutorial_coach_marks.dart';
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

  final GlobalKey _keyInicio = GlobalKey();
  final GlobalKey _keyApartados = GlobalKey();
  final GlobalKey _keyAgregar = GlobalKey();
  final GlobalKey _keyHistorial = GlobalKey();
  final GlobalKey _keyMetricas = GlobalKey();
  final GlobalKey _keyDemoApartado = GlobalKey();

  static const String _idDemoApartado = 'demo_tutorial_apartado';
  static const String _idDemoEspacio = 'demo_tutorial_espacio';
  static const String _idDemoObjeto = 'demo_tutorial_objeto';

  bool _mostrarTutorial = false;
  String? _demoApartadoId;
  String? _demoEspacioId;
  String? _demoObjetoId;

  List<Apartado> get _apartados => widget.apartados;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!tutorialCompletado.value) {
        _limpiarDatosTutorial();
        setState(() => _mostrarTutorial = true);
      }
    });
  }

  void _finalizarTutorial() {
    _limpiarDatosTutorial();
    marcarTutorialCompletado();
    setState(() {
      _mostrarTutorial = false;
      _paginaActual = 0;
    });
  }

  void _prepararPaso(int indice) {
    if (!mounted) return;
    switch (indice) {
      case 0:
      case 8:
        setState(() => _paginaActual = 0);
        break;
      case 1:
      case 2:
        setState(() => _paginaActual = 1);
        break;
      case 3:
        _crearDemoApartado();
        break;
      case 4:
        _crearDemoEspacio();
        break;
      case 5:
        _crearDemoObjeto();
        break;
      case 6:
        setState(() => _paginaActual = 2);
        break;
      case 7:
        setState(() => _paginaActual = 3);
        break;
      default:
        break;
    }
  }

  void _crearDemoApartado() {
    if (_demoApartadoId != null) return;
    _demoApartadoId = _idDemoApartado;
    widget.apartados.add(
      Apartado(
        id: _demoApartadoId!,
        nombre: 'Apartado de ejemplo',
        icono: '🏢',
        descripcion: 'Creado por el tutorial',
      ),
    );
    setState(() => _paginaActual = 1);
  }

  void _crearDemoEspacio() {
    if (_demoApartadoId == null || _demoEspacioId != null) return;
    _demoEspacioId = _idDemoEspacio;
    espaciosIniciales.add(
      Espacio(
        id: _demoEspacioId!,
        nombre: 'Espacio de ejemplo',
        descripcion: 'Creado por el tutorial',
        emoji: '💻',
        apartadoId: _demoApartadoId!,
      ),
    );
    setState(() => _paginaActual = 1);
  }

  void _crearDemoObjeto() {
    if (_demoEspacioId == null || _demoObjetoId != null) return;
    _demoObjetoId = _idDemoObjeto;
    objetosIniciales.add(
      ObjetoInventario(
        id: _demoObjetoId!,
        placa: 'DEMO-001',
        nombre: 'Objeto de ejemplo',
        espacioId: _demoEspacioId!,
        categoria: 'General',
        estado: 'En revisión',
        valor: 100,
        responsable: 'Tutorial',
        marca: 'Demo',
      ),
    );
    historialRevisiones.add(
      RegistroRevision(
        id: 'demo_tutorial_revision',
        objetoId: _idDemoObjeto,
        nombre: 'Objeto de ejemplo',
        placa: 'DEMO-001',
        espacioId: _idDemoEspacio,
        fechaEntrada: DateTime.now(),
      ),
    );
    inventarioVersion.value++;
    setState(() => _paginaActual = 1);
  }

  void _limpiarDatosTutorial() {
    objetosIniciales.removeWhere(
      (o) => o.id == _idDemoObjeto || o.espacioId == _idDemoEspacio,
    );
    espaciosIniciales.removeWhere(
      (e) => e.id == _idDemoEspacio || e.apartadoId == _idDemoApartado,
    );
    widget.apartados.removeWhere((a) => a.id == _idDemoApartado);
    historialRevisiones.removeWhere((r) => r.objetoId == _idDemoObjeto);
    _demoObjetoId = null;
    _demoEspacioId = null;
    _demoApartadoId = null;
    inventarioVersion.value++;
    if (mounted) setState(() {});
  }

  List<PasoTutorial> _pasosTutorial() {
    return [
      PasoTutorial(
        objetivo: _keyInicio,
        emoji: '🏠',
        titulo: 'Inicio',
        descripcion:
            'Aquí ves tus apartados y sus espacios. Desliza a los lados para '
            'cambiar entre apartados.',
      ),
      PasoTutorial(
        objetivo: _keyApartados,
        emoji: '🗂️',
        titulo: 'Apartados',
        descripcion:
            'En esta sección se organiza todo. Primero se crea un apartado, '
            'luego un espacio dentro de él y finalmente los objetos.',
      ),
      PasoTutorial(
        objetivo: _keyAgregar,
        emoji: '➕',
        titulo: 'Agregar',
        descripcion:
            'Al tocar este botón se abren tres opciones. Vamos a crear un '
            'ejemplo de cada una para que veas cómo funciona:',
        detalles: [
          '🏢 Nuevo Apartado: agrupa espacios y objetos.',
          '💻 Nuevo Espacio: crea un área dentro de un apartado.',
          '📦 Nuevo Objeto: registra un activo o equipo.',
        ],
      ),
      PasoTutorial(
        objetivo: _keyDemoApartado,
        emoji: '🏢',
        titulo: 'Creamos un apartado',
        descripcion:
            'Este es el "Apartado de ejemplo". Un apartado agrupa espacios y '
            'objetos. Aparece en la lista de Apartados y también en Inicio.',
      ),
      PasoTutorial(
        objetivo: _keyDemoApartado,
        emoji: '💻',
        titulo: 'Creamos un espacio',
        descripcion:
            'Dentro del apartado creamos el "Espacio de ejemplo". Observa cómo '
            'aumenta el contador de espacios en la tarjeta.',
      ),
      PasoTutorial(
        objetivo: _keyDemoApartado,
        emoji: '📦',
        titulo: 'Creamos un objeto',
        descripcion:
            'Por último, dentro del espacio creamos el "Objeto de ejemplo". '
            'Ahora el contador de objetos también aumentó.',
      ),
      PasoTutorial(
        objetivo: _keyHistorial,
        emoji: '🕘',
        titulo: 'Historial',
        descripcion:
            'Aquí se guarda la actividad del inventario. Tiene dos vistas:',
        detalles: [
          '🛠️ Revisiones: objetos que han pasado por revisión, con fecha de '
              'entrada y, si ya salieron, fecha de salida.',
          '🕘 Registros: todos los objetos agregados y su fecha de registro.',
          'Cada tarjeta muestra el nombre, la placa, el espacio y el estado '
              'del objeto.',
        ],
      ),
      PasoTutorial(
        objetivo: _keyMetricas,
        emoji: '📊',
        titulo: 'Métricas',
        descripcion: 'Es el resumen general y por apartado. Incluye:',
        detalles: [
          'Filtros por apartado en la parte superior.',
          'Tarjetas de Espacios, Objetos, Valor total y En revisión.',
          'Toca "Objetos" para ver todos los objetos y "En revisión" para '
              'abrir la lista de revisión.',
          'Detalle por apartado: arrastra una tarjeta para cambiar su orden '
              'en Inicio.',
        ],
      ),
      PasoTutorial(
        objetivo: _keyInicio,
        emoji: '✨',
        titulo: '¡Todo listo!',
        descripcion:
            'Al terminar el tutorial, el apartado, el espacio y el objeto de '
            'ejemplo se eliminarán automáticamente. Tú podrás crear los tuyos '
            'con el botón Agregar.',
      ),
    ];
  }

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
        placaInicial: generarPlacaUnica(),
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
          String? imagenAnterior;
          setState(() {
            final index = _apartados.indexWhere((item) => item.id == a.id);
            if (index != -1) {
              imagenAnterior = _apartados[index].imagePath;
              _apartados[index] = a;
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
          final objetos =
              objetosIniciales.where((o) => ids.contains(o.espacioId)).toList();
          final imagenes = <String?>[
            a.imagePath,
            ...espacios.map((e) => e.imagePath),
            ...objetos.map((o) => o.imagePath),
          ];
          setState(() {
            registrarEliminacionEnHistorial(objetos.map((o) => o.id).toSet());
            _apartados.removeWhere((item) => item.id == a.id);
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
    return Stack(
      children: [
        Scaffold(
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
        ),
        if (_mostrarTutorial)
          TutorialCoachMarks(
            pasos: _pasosTutorial(),
            onFinalizar: _finalizarTutorial,
            onPasoCambiado: _prepararPaso,
          ),
      ],
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
                        key: apartado.id == _demoApartadoId
                            ? _keyDemoApartado
                            : null,
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
              clave: _keyInicio,
              icono: Icons.home_outlined,
              iconoActivo: Icons.home_rounded,
              etiqueta: 'Inicio',
              pagina: 0,
            ),
            _construirItemNav(
              clave: _keyApartados,
              icono: Icons.grid_view_outlined,
              iconoActivo: Icons.grid_view_rounded,
              etiqueta: 'Apartados',
              pagina: 1,
            ),
            _construirBotonAgregar(),
            _construirItemNav(
              clave: _keyHistorial,
              icono: Icons.chat_bubble_outline,
              iconoActivo: Icons.chat_bubble,
              etiqueta: 'Historial',
              pagina: 2,
            ),
            _construirItemNav(
              clave: _keyMetricas,
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
    required GlobalKey clave,
    required IconData icono,
    required IconData iconoActivo,
    required String etiqueta,
    required int pagina,
  }) {
    final seleccionado = _paginaActual == pagina;
    return Expanded(
      child: GestureDetector(
        key: clave,
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
        key: _keyAgregar,
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
