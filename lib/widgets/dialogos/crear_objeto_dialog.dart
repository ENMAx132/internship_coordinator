import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/catalog.dart';
import '../../models/drafts.dart';
import '../../models/space.dart';
import '../../widgets/seleccionar_imagen_icono.dart';
import 'selectores_inventario.dart';

class CrearObjetoDialog extends StatefulWidget {
  final List<Space> spaces;
  final Catalogs catalogs;
  final String placaInicial;
  final ValueChanged<ItemDraft> onGuardar;
  final List<Account> accounts;
  final bool canAssignUsers;
  final bool canPickResponsible;
  final int? currentUserId;
  final String? currentUserName;

  const CrearObjetoDialog({
    super.key,
    required this.spaces,
    required this.catalogs,
    required this.placaInicial,
    required this.onGuardar,
    this.accounts = const [],
    this.canAssignUsers = false,
    this.canPickResponsible = false,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  State<CrearObjetoDialog> createState() => _CrearObjetoDialogState();
}

class _CrearObjetoDialogState extends State<CrearObjetoDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController placaCtrl;
  late final TextEditingController marcaCtrl;
  late final TextEditingController respCtrl;
  late final TextEditingController valorCtrl;
  late int spaceIdSelec;
  late String categoryCodeSelec;
  late String statusCodeSelec;
  int? responsibleUserIdSelec;
  final Set<int> _assignedIds = {};
  String? localImagePath;
  bool _nombreInvalido = false;
  bool _valorInvalido = false;

  List<CatalogEntry> get _categories => widget.catalogs.categories.isEmpty
      ? const [CatalogEntry(id: 0, code: 'general', name: 'General')]
      : widget.catalogs.categories;

  List<CatalogEntry> get _statuses => widget.catalogs.statuses.isEmpty
      ? const [
          CatalogEntry(id: 0, code: 'excellent', name: 'Excelente'),
        ]
      : widget.catalogs.statuses;

  int _paso = 0;

  static const List<String> _ayudasBase = [
    'Agrega una foto para el objeto (opcional)',
    '¿Cómo se llama el objeto?',
    'Identificador o placa del activo',
    'Fabricante o marca (opcional)',
    'Persona responsable (opcional)',
    'Valor estimado (opcional)',
    'Categoría del objeto',
    'Estado actual del objeto',
    'Dónde se encuentra el objeto',
  ];

  List<String> get _ayudas => [
        ..._ayudasBase,
        if (widget.canAssignUsers) 'Usuarios asignados (opcional)',
      ];

  int get _totalPasos => _ayudas.length;

  bool get _esUltimoPaso => _paso == _totalPasos - 1;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController();
    placaCtrl = TextEditingController(text: widget.placaInicial);
    marcaCtrl = TextEditingController();
    respCtrl = TextEditingController(
      text: widget.canPickResponsible ? '' : widget.currentUserName ?? '',
    );
    valorCtrl = TextEditingController(text: '0');
    spaceIdSelec = widget.spaces.isNotEmpty ? widget.spaces.first.id : 0;
    categoryCodeSelec = _categories.first.code;
    statusCodeSelec = _statuses.first.code;
    if (!widget.canPickResponsible) {
      responsibleUserIdSelec = widget.currentUserId;
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    placaCtrl.dispose();
    marcaCtrl.dispose();
    respCtrl.dispose();
    valorCtrl.dispose();
    super.dispose();
  }

  void _avanzar({bool omitir = false}) {
    if (!omitir && _paso == 1 && nombreCtrl.text.trim().isEmpty) {
      setState(() => _nombreInvalido = true);
      return;
    }
    if (!omitir && _paso == 5) {
      final texto = valorCtrl.text.trim();
      if (texto.isNotEmpty) {
        final valor = double.tryParse(texto.replaceAll(',', '.'));
        if (valor == null || valor < 0) {
          setState(() => _valorInvalido = true);
          return;
        }
      }
    }
    if (_esUltimoPaso) {
      _guardar();
      return;
    }
    setState(() {
      _nombreInvalido = false;
      _valorInvalido = false;
      _paso++;
    });
  }

  void _atras() {
    if (_paso > 0) {
      setState(() => _paso--);
    }
  }

  void _omitir() {
    _limpiarPasoActual();
    _avanzar(omitir: true);
  }

  void _limpiarPasoActual() {
    switch (_paso) {
      case 0:
        localImagePath = null;
        break;
      case 1:
        nombreCtrl.clear();
        break;
      case 2:
        placaCtrl.clear();
        break;
      case 3:
        marcaCtrl.clear();
        break;
      case 4:
        respCtrl.clear();
        if (widget.canPickResponsible) responsibleUserIdSelec = null;
        break;
      case 5:
        valorCtrl.clear();
        break;
      case 6:
        categoryCodeSelec = _categories.first.code;
        break;
      case 7:
        statusCodeSelec = _statuses.first.code;
        break;
      case 8:
        if (widget.spaces.isNotEmpty) {
          spaceIdSelec = widget.spaces.first.id;
        }
        break;
      default:
        _assignedIds.clear();
        break;
    }
  }

  void _guardar() {
    widget.onGuardar(
      ItemDraft(
        spaceId: spaceIdSelec,
        name: nombreCtrl.text.trim().isEmpty
            ? 'Sin nombre'
            : nombreCtrl.text.trim(),
        code: placaCtrl.text.trim(),
        categoryCode: categoryCodeSelec,
        statusCode: statusCodeSelec,
        value: double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0,
        responsible:
            respCtrl.text.trim().isEmpty ? 'Sin asignar' : respCtrl.text.trim(),
        brand: marcaCtrl.text.trim(),
        responsibleUserId:
            widget.canPickResponsible ? responsibleUserIdSelec : null,
        localImagePath: localImagePath,
        assignedUserIds: _assignedIds.toList(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Registrar Objeto',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paso ${_paso + 1} de $_totalPasos',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  Text(
                    '${((_paso + 1) / _totalPasos * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_paso + 1) / _totalPasos,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEEF2FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Column(
                  key: ValueKey(_paso),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _ayudas[_paso],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _construirCampo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_paso > 0)
          TextButton(
            onPressed: _atras,
            child: const Text('Atrás'),
          ),
        if (_paso != 1)
          TextButton(
            onPressed: _omitir,
            child: const Text('Omitir'),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          onPressed: _avanzar,
          child: Text(_esUltimoPaso ? 'Guardar' : 'Siguiente'),
        ),
      ],
    );
  }

  Widget _construirCampo() {
    switch (_paso) {
      case 0:
        return SelectorImagenIcono(
          emoji: widget.spaces.isNotEmpty ? widget.spaces.first.emoji : '📦',
          localImagePath: localImagePath,
          onImagePicked: (p) => setState(() => localImagePath = p),
        );
      case 1:
        return TextField(
          controller: nombreCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) {
            if (_nombreInvalido && value.trim().isNotEmpty) {
              setState(() => _nombreInvalido = false);
            }
          },
          decoration: InputDecoration(
            labelText: 'Nombre del objeto',
            errorText: _nombreInvalido ? 'El nombre es obligatorio' : null,
          ),
          onSubmitted: (_) => _avanzar(),
        );
      case 2:
        return TextField(
          controller: placaCtrl,
          decoration: const InputDecoration(
            labelText: 'Código / Placa',
            hintText: 'Vacío = el servidor genera ACT-###',
          ),
          onSubmitted: (_) => _avanzar(),
        );
      case 3:
        return TextField(
          controller: marcaCtrl,
          decoration: const InputDecoration(labelText: 'Marca'),
          onSubmitted: (_) => _avanzar(),
        );
      case 4:
        return ResponsableUsuarioSelector(
          accounts: widget.accounts,
          selectedId: responsibleUserIdSelec,
          enabled: widget.canPickResponsible,
          lockedName: widget.currentUserName,
          onChanged: (id) {
            setState(() {
              responsibleUserIdSelec = id;
              final matches =
                  widget.accounts.where((item) => item.id == id).toList();
              if (matches.isNotEmpty) {
                respCtrl.text = matches.first.name;
              } else if (id == null) {
                respCtrl.clear();
              }
            });
          },
        );
      case 5:
        return TextField(
          controller: valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            if (_valorInvalido) {
              setState(() => _valorInvalido = false);
            }
          },
          decoration: InputDecoration(
            labelText: 'Precio',
            errorText: _valorInvalido
                ? 'Ingresa un valor válido (mayor o igual a 0)'
                : null,
          ),
          onSubmitted: (_) => _avanzar(),
        );
      case 6:
        return DropdownButtonFormField<String>(
          initialValue: categoryCodeSelec,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: _categories.map((c) {
            return DropdownMenuItem(
              value: c.code,
              child: Text(c.name),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => categoryCodeSelec = val);
          },
        );
      case 7:
        return DropdownButtonFormField<String>(
          initialValue: statusCodeSelec,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: _statuses.map((e) {
            return DropdownMenuItem(
              value: e.code,
              child: Text(e.name),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => statusCodeSelec = val);
          },
        );
      case 8:
        return DropdownButtonFormField<int>(
          initialValue: spaceIdSelec,
          decoration: const InputDecoration(labelText: 'Espacio / Sala'),
          items: widget.spaces.map((e) {
            return DropdownMenuItem(
              value: e.id,
              child: Text(
                '${e.emoji} ${e.pathLabel(widget.spaces)}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => spaceIdSelec = val);
          },
        );
      default:
        if (!widget.canAssignUsers) return const SizedBox.shrink();
        return UsuariosAsignadosSelector(
          accounts: widget.accounts,
          selectedIds: _assignedIds,
          onChanged: (ids) => setState(() {
            _assignedIds
              ..clear()
              ..addAll(ids);
          }),
        );
    }
  }
}
