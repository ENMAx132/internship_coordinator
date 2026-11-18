import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/catalog.dart';
import '../models/inventory_item.dart';
import '../models/section.dart';
import '../models/space.dart';
import '../models/tutorial_pending.dart';
import '../widgets/apartado_card.dart';
import '../widgets/dialogos/crear_apartado_dialog.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import '../widgets/dialogos/editar_apartado_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sector_card.dart';
import '../widgets/tutorial_coach_marks.dart';
import '../widgets/tutorial_pending_banner.dart';
import 'apartado_screen.dart';
import 'espacio_screen.dart';
import 'historial_screen.dart';
import 'metricas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

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

  bool _mostrarTutorial = false;
  bool _tutorialBusy = false;
  Section? _demoSection;
  Space? _demoSpace;
  InventoryItem? _demoItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = InventoryScope.of(context);
      if (!store.settings.tutorialCompleted &&
          !store.localTutorialCompleted &&
          store.pendingTutorial == null &&
          store.canWrite) {
        _limpiarDatosTutorial();
        setState(() => _mostrarTutorial = true);
      }
    });
  }

  InventoryStore get _store => InventoryScope.of(context);

  List<Section> _sections(InventoryStore store) => [
        ...store.sections,
        if (_demoSection != null) _demoSection!,
        if (store.tutorialSection != null) store.tutorialSection!,
      ];

  List<Space> _spacesOf(InventoryStore store, int sectionId) => [
        ...store.rootSpacesForSection(sectionId),
        if (_demoSpace != null && _demoSpace!.sectionId == sectionId)
          _demoSpace!,
        if (store.tutorialSpace != null &&
            store.tutorialSpace!.sectionId == sectionId)
          store.tutorialSpace!,
      ];

  List<InventoryItem> _itemsOfSection(
    InventoryStore store,
    int sectionId,
  ) =>
      [
        ...store.itemsForSection(sectionId),
        if (_demoItem != null && _demoItem!.sectionId == sectionId) _demoItem!,
        if (store.tutorialItem != null &&
            store.tutorialItem!.sectionId == sectionId)
          store.tutorialItem!,
      ];

  List<InventoryItem> _itemsOfSpace(InventoryStore store, int spaceId) => [
        ...store.itemsForSpace(spaceId),
        if (_demoItem != null && _demoItem!.spaceId == spaceId) _demoItem!,
        if (store.tutorialItem != null &&
            store.tutorialItem!.spaceId == spaceId)
          store.tutorialItem!,
      ];

  Future<void> _finalizarTutorial() async {
    if (_tutorialBusy) return;
    final keep = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Datos de ejemplo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Qué quieres hacer con el apartado, el espacio y el objeto de '
          'ejemplo del tutorial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mantener'),
          ),
        ],
      ),
    );

    if (keep == null || !mounted) return;

    _tutorialBusy = true;
    _mostrarAviso(
      keep
          ? 'Guardando datos del tutorial…'
          : 'Eliminando datos del tutorial…',
    );

    final store = _store;
    final pending = _buildTutorialPending(keep: keep);
    TutorialFinishResult result;
    try {
      result = await store.finishTutorial(pending);
    } catch (_) {
      if (mounted) {
        setState(() => _tutorialBusy = false);
        _mostrarAviso('No se pudieron guardar los datos del tutorial.');
      }
      return;
    }

    _limpiarDatosTutorial();
    if (!mounted) return;
    setState(() {
      _mostrarTutorial = false;
      _paginaActual = 0;
      _tutorialBusy = false;
    });

    switch (result) {
      case TutorialFinishResult.deleted:
        _mostrarAviso('Datos del tutorial eliminados.');
        break;
      case TutorialFinishResult.synced:
        _mostrarAviso('Datos del tutorial guardados en el inventario.');
        break;
      case TutorialFinishResult.pending:
        _mostrarAviso(
          'Datos del tutorial guardados localmente. Se sincronizarán cuando '
          'haya conexión.',
        );
        break;
    }
  }

  TutorialPending _buildTutorialPending({required bool keep}) {
    final store = _store;
    final section = _demoSection;
    final space = _demoSpace;
    final item = _demoItem;
    final category = item?.category ??
        (store.catalogs.categories.isNotEmpty
            ? store.catalogs.categories.first
            : const CatalogEntry(id: 0, code: 'general', name: 'General'));
    final status = item?.status ??
        (store.catalogs.statuses.isNotEmpty
            ? store.catalogs.inReviewStatus
            : const CatalogEntry(
                id: 0,
                code: 'in_review',
                name: 'En revisión',
                isInReview: true,
              ));

    return TutorialPending(
      sectionName: section?.name ?? 'Apartado de ejemplo',
      sectionDescription:
          section?.description ?? 'Creado por el tutorial',
      sectionIcon: section?.icon ?? '🏢',
      spaceName: space?.name ?? 'Espacio de ejemplo',
      spaceDescription: space?.description ?? 'Creado por el tutorial',
      spaceEmoji: space?.emoji ?? '💻',
      itemName: item?.name ?? 'Objeto de ejemplo',
      itemCode: TutorialPending.fixedItemCode,
      categoryCode: category.code,
      statusCode: status.code,
      value: item?.value ?? 100,
      responsible: item?.responsible ?? 'Tutorial',
      brand: item?.brand ?? 'Demo',
      createdAt: DateTime.now(),
      decision: keep ? TutorialDecision.keep : TutorialDecision.delete,
    );
  }

  Future<void> _confirmDiscardPendingTutorial() async {
    final store = _store;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Descartar datos del tutorial'),
        content: const Text(
          'Se eliminarán los datos locales. Si parte ya se subió a la API, '
          'también se eliminará cuando haya conexión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.discardPendingTutorial();
    if (!mounted) return;
    _mostrarAviso('Datos del tutorial descartados.');
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

  CatalogEntry _demoCategory(InventoryStore store) {
    if (store.catalogs.categories.isNotEmpty) {
      return store.catalogs.categories.first;
    }
    return const CatalogEntry(id: 0, code: 'general', name: 'General');
  }

  CatalogEntry _demoStatus(InventoryStore store) {
    if (store.catalogs.statuses.isNotEmpty) {
      return store.catalogs.inReviewStatus;
    }
    return const CatalogEntry(
      id: 0,
      code: 'in_review',
      name: 'En revisión',
      isInReview: true,
    );
  }

  void _crearDemoApartado() {
    if (_demoSection != null) return;
    setState(() {
      _demoSection = const Section(
        id: TutorialPending.localSectionId,
        name: 'Apartado de ejemplo',
        icon: '🏢',
        description: 'Creado por el tutorial',
        sortOrder: 0,
        spaceCount: 0,
        itemCount: 0,
        totalValue: 0,
      );
      _paginaActual = 1;
    });
  }

  void _crearDemoEspacio() {
    if (_demoSection == null || _demoSpace != null) return;
    setState(() {
      _demoSpace = const Space(
        id: TutorialPending.localSpaceId,
        sectionId: TutorialPending.localSectionId,
        name: 'Espacio de ejemplo',
        description: 'Creado por el tutorial',
        emoji: '💻',
        itemCount: 0,
      );
      _paginaActual = 1;
    });
  }

  void _crearDemoObjeto() {
    if (_demoSpace == null || _demoItem != null) return;
    final store = _store;
    final now = DateTime.now();
    setState(() {
      _demoItem = InventoryItem(
        id: TutorialPending.localItemId,
        code: TutorialPending.fixedItemCode,
        name: 'Objeto de ejemplo',
        spaceId: TutorialPending.localSpaceId,
        spaceName: 'Espacio de ejemplo',
        spaceEmoji: '💻',
        sectionId: TutorialPending.localSectionId,
        sectionName: 'Apartado de ejemplo',
        sectionIcon: '🏢',
        category: _demoCategory(store),
        status: _demoStatus(store),
        value: 100,
        responsible: 'Tutorial',
        brand: 'Demo',
        registeredAt: now,
        inReviewAt: now,
      );
      _paginaActual = 1;
    });
  }

  void _limpiarDatosTutorial() {
    _demoSection = null;
    _demoSpace = null;
    _demoItem = null;
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
            'Al terminar, podrás decidir si mantienes o eliminas el apartado, '
            'el espacio y el objeto de ejemplo. Tú podrás crear los tuyos con '
            'el botón Agregar.',
      ),
    ];
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? success,
  }) async {
    final store = _store;
    try {
      await action();
      if (success != null) _mostrarAviso(success);
    } on ApiException catch (error) {
      store.handleError(error);
      _mostrarAviso(messageForApiError(error));
    } catch (_) {
      _mostrarAviso('Ocurrió un error inesperado.');
    }
  }

  void _crearApartado() {
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => CrearApartadoDialog(
        emojis: store.catalogs.sectionEmojis,
        onCrear: (draft) {
          _run(
            () => store.createSection(draft),
            success: 'Apartado creado correctamente.',
          );
        },
      ),
    );
  }

  void _crearEspacio() {
    final store = _store;
    if (store.sections.isEmpty) {
      _mostrarAviso('Crea primero un apartado.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        sections: store.sections,
        spaces: store.spaces,
        emojis: store.catalogs.spaceEmojis,
        onCrear: (draft) {
          _run(
            () => store.createSpace(draft),
            success: 'Espacio creado correctamente.',
          );
        },
      ),
    );
  }

  Future<void> _crearObjeto() async {
    final store = _store;
    if (store.spaces.isEmpty) {
      _mostrarAviso('Crea primero un espacio.');
      return;
    }

    var placa = '';
    try {
      placa = await store.nextCode();
    } catch (_) {
      placa = '';
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => CrearObjetoDialog(
        spaces: store.spaces,
        catalogs: store.catalogs,
        placaInicial: placa,
        onGuardar: (draft) {
          _run(
            () => store.createItem(draft),
            success: 'Objeto agregado correctamente.',
          );
        },
      ),
    );
  }

  void _mostrarAviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  bool _esApartadoPendiente(Section section) {
    final pending = _store.pendingTutorial;
    if (pending == null) return false;
    if (section.id == TutorialPending.localSectionId) return true;
    if (pending.remoteSectionId != null &&
        section.id == pending.remoteSectionId) {
      return _store.sectionById(section.id) == null;
    }
    return false;
  }

  bool _esEspacioPendiente(Space space) {
    final pending = _store.pendingTutorial;
    if (pending == null) return false;
    if (space.id == TutorialPending.localSpaceId) return true;
    if (pending.remoteSpaceId != null &&
        space.id == pending.remoteSpaceId) {
      return _store.spaceById(space.id) == null;
    }
    return false;
  }

  void _abrirApartado(Section section) {
    if (_esApartadoPendiente(section)) {
      _mostrarAviso(
        'Este apartado se sincronizará cuando haya conexión.',
      );
      return;
    }
    if (section.id < 0) {
      _mostrarAviso('Este apartado es solo un ejemplo del tutorial.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartadoScreen(section: section),
      ),
    );
  }

  void _abrirEspacio(Space space) {
    if (_esEspacioPendiente(space)) {
      _mostrarAviso(
        'Este espacio se sincronizará cuando haya conexión.',
      );
      return;
    }
    if (space.id < 0) {
      _mostrarAviso('Este espacio es solo un ejemplo del tutorial.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EspacioScreen(space: space),
      ),
    );
  }

  void _dialogoEditarApartado(Section section) {
    if (section.id < 0) return;
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => EditarApartadoDialog(
        section: section,
        emojis: store.catalogs.sectionEmojis,
        onActualizar: (draft) {
          _run(
            () => store.updateSection(section.id, draft),
            success: 'Apartado actualizado con éxito.',
          );
        },
        onEliminar: () {
          _run(
            () => store.deleteSection(section.id),
            success: 'Apartado eliminado correctamente.',
          );
        },
      ),
    );
  }

  void _mostrarMenuAgregar() {
    final store = _store;
    if (!store.canWrite || store.offline) {
      _mostrarAviso('No puedes crear elementos en este momento.');
      return;
    }
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
    final store = _store;
    final canWrite = store.canWrite && !store.offline;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (store.offline)
                  OfflineBanner(
                    message:
                        'Sin conexión. Mostrando datos guardados. Los cambios '
                        'están deshabilitados.',
                    onRetry: store.retryConnection,
                  ),
                if (store.pendingTutorial != null)
                  TutorialPendingBanner(
                    pending: store.pendingTutorial!,
                    syncing: store.tutorialSyncing,
                    error: store.tutorialSyncError,
                    onRetry: () async {
                      await store.syncPendingTutorial();
                    },
                    onDiscard: store.pendingTutorial!.isKeep
                        ? _confirmDiscardPendingTutorial
                        : null,
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _paginaActual,
                    children: [
                      _construirInicio(store, canWrite),
                      _construirApartados(store, canWrite),
                      HistorialScreen(onLogout: widget.onLogout),
                      MetricasScreen(onLogout: widget.onLogout),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _construirBarraNavegacion(store, canWrite),
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

  Widget _construirInicio(InventoryStore store, bool canWrite) {
    final sections = _sections(store);
    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _construirApartadoVacio(canWrite),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Desliza para cambiar de apartado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onLogout,
                tooltip: 'Cerrar sesión',
                icon: const Icon(
                  Icons.logout,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _InicioApartados(
              sections: sections,
              apartadoInicialId: store.settings.startSectionId,
              spacesOf: (sectionId) => _spacesOf(store, sectionId),
              itemsOfSection: (sectionId) =>
                  _itemsOfSection(store, sectionId),
              itemsOfSpace: (spaceId) => _itemsOfSpace(store, spaceId),
              onOpenSection: _abrirApartado,
              onOpenSpace: _abrirEspacio,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirApartados(InventoryStore store, bool canWrite) {
    final sections = _sections(store);
    final totalSpaces = sections.fold<int>(
      0,
      (total, section) => total + _spacesOf(store, section.id).length,
    );
    final totalItems = sections.fold<int>(
      0,
      (total, section) => total + _itemsOfSection(store, section.id).length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apartados',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Selecciona un apartado para ver sus espacios',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onLogout,
                tooltip: 'Cerrar sesión',
                icon: const Icon(
                  Icons.logout,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _construirResumen(
                  etiqueta: 'Apartados',
                  valor: '${sections.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _construirResumen(
                  etiqueta: 'Espacios',
                  valor: '$totalSpaces',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _construirResumen(
                  etiqueta: 'Objetos',
                  valor: '$totalItems',
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
                '${sections.length} en total',
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
            child: sections.isEmpty
                ? _construirApartadoVacio(canWrite)
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
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return GestureDetector(
                        key: section.id == TutorialPending.localSectionId
                            ? _keyDemoApartado
                            : null,
                        onLongPress: canWrite &&
                                section.id >= 0 &&
                                !_esApartadoPendiente(section)
                            ? () => _dialogoEditarApartado(section)
                            : null,
                        child: ApartadoCard(
                          section: section,
                          spaces: _spacesOf(store, section.id).length,
                          objects: _itemsOfSection(store, section.id).length,
                          onTap: () => _abrirApartado(section),
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

  Widget _construirApartadoVacio(bool canWrite) {
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
          if (canWrite) ...[
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
        ],
      ),
    );
  }

  Widget _construirBarraNavegacion(InventoryStore store, bool canWrite) {
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
            if (canWrite) _construirBotonAgregar(),
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
  final List<Section> sections;
  final int? apartadoInicialId;
  final List<Space> Function(int sectionId) spacesOf;
  final List<InventoryItem> Function(int sectionId) itemsOfSection;
  final List<InventoryItem> Function(int spaceId) itemsOfSpace;
  final ValueChanged<Section> onOpenSection;
  final ValueChanged<Space> onOpenSpace;

  const _InicioApartados({
    required this.sections,
    required this.apartadoInicialId,
    required this.spacesOf,
    required this.itemsOfSection,
    required this.itemsOfSpace,
    required this.onOpenSection,
    required this.onOpenSpace,
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
        oldWidget.sections.length != widget.sections.length) {
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
    final indice = widget.sections.indexWhere(
      (section) => section.id == widget.apartadoInicialId,
    );
    return indice < 0 ? 0 : indice;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.sections.length,
            onPageChanged: (index) {
              setState(() => _pagina = index);
            },
            itemBuilder: (context, index) {
              return _construirPagina(widget.sections[index]);
            },
          ),
        ),
        if (widget.sections.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.sections.length, (index) {
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

  Widget _construirPagina(Section section) {
    final store = InventoryScope.of(context);
    final spaces = widget.spacesOf(section.id);
    final totalItems = widget.itemsOfSection(section.id).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => widget.onOpenSection(section),
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
                    imageUrl: section.imageUrl,
                    emoji: section.icon,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${spaces.length} espacios • $totalItems objetos',
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
              '${spaces.length} en este apartado',
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
          child: spaces.isEmpty
              ? _construirVacio(section)
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    return SectorCard(
                      space: space,
                      count: widget.itemsOfSpace(space.id).length,
                      subspaces: store.subspacesOf(space.id).length,
                      isSelected: false,
                      onTap: () => widget.onOpenSpace(space),
                      onLongPress: () => widget.onOpenSection(section),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _construirVacio(Section section) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            '${section.name} aún no tiene espacios',
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
            onPressed: () => widget.onOpenSection(section),
            child: const Text('Abrir apartado'),
          ),
        ],
      ),
    );
  }
}
