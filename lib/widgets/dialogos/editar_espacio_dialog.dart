import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/drafts.dart';
import '../../models/section.dart';
import '../../models/space.dart';
import '../../widgets/seleccionar_imagen_icono.dart';
import 'selectores_inventario.dart';

class EditarEspacioDialog extends StatefulWidget {
  final Space space;
  final ValueChanged<SpaceDraft> onActualizar;
  final VoidCallback onEliminar;
  final List<Section> sections;
  final List<Space> spaces;
  final List<String> emojis;
  final List<Account> accounts;
  final bool canAssignUsers;

  const EditarEspacioDialog({
    super.key,
    required this.space,
    required this.onActualizar,
    required this.onEliminar,
    required this.sections,
    this.spaces = const [],
    this.emojis = const ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️'],
    this.accounts = const [],
    this.canAssignUsers = false,
  });

  @override
  State<EditarEspacioDialog> createState() => _EditarEspacioDialogState();
}

class _EditarEspacioDialogState extends State<EditarEspacioDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController descCtrl;
  late String emojiSelec;
  String? localImagePath;
  late int sectionIdSelec;
  late int parentSpaceIdSelec;
  late Set<int> _assignedIds;

  List<String> get _emojis =>
      widget.emojis.isEmpty ? const ['🏢', '💻', '📊', '📦'] : widget.emojis;

  List<Space> get _parentOptions {
    final descendants = Space.descendantIdsOf(
      widget.space.id,
      widget.spaces,
    );
    final options = widget.spaces
        .where(
          (space) =>
              space.sectionId == sectionIdSelec &&
              space.id != widget.space.id &&
              !descendants.contains(space.id),
        )
        .toList();
    options.sort(
      (a, b) => a.pathLabel(widget.spaces).compareTo(
            b.pathLabel(widget.spaces),
          ),
    );
    return options;
  }

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.space.name);
    descCtrl = TextEditingController(text: widget.space.description);
    emojiSelec = widget.space.emoji;
    sectionIdSelec = widget.space.sectionId;
    parentSpaceIdSelec = widget.space.parentSpaceId ?? 0;
    _assignedIds = widget.space.assignedUsers.map((user) => user.id).toSet();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarEliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar espacio'),
        content: Text(
          '¿Seguro que quieres eliminar "${widget.space.name}"? '
          'También se eliminarán sus subespacios y todos sus objetos.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true && mounted) {
      Navigator.pop(context);
      widget.onEliminar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.space.isRoot ? 'Editar Espacio' : 'Editar Subespacio',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectorImagenIcono(
              emoji: emojiSelec,
              imageUrl: widget.space.imageUrl,
              localImagePath: localImagePath,
              emojis: _emojis,
              size: 104,
              onImagePicked: (p) => setState(() => localImagePath = p),
              onEmojiChange: (e) => setState(() => emojiSelec = e),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nombre del espacio'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción breve'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: sectionIdSelec,
              decoration: const InputDecoration(labelText: 'Apartado'),
              items: widget.sections.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.icon} ${e.name}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    sectionIdSelec = val;
                    final valido = widget.spaces.any(
                      (space) =>
                          space.id == parentSpaceIdSelec &&
                          space.sectionId == sectionIdSelec &&
                          space.id != widget.space.id,
                    );
                    if (!valido) parentSpaceIdSelec = 0;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'edit_parent_${sectionIdSelec}_$parentSpaceIdSelec',
              ),
              initialValue: _parentOptions.any(
                (space) => space.id == parentSpaceIdSelec,
              )
                  ? parentSpaceIdSelec
                  : 0,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Espacio padre (opcional)',
              ),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Sin espacio padre (raíz)'),
                ),
                ..._parentOptions.map((space) {
                  return DropdownMenuItem(
                    value: space.id,
                    child: Text(
                      '${space.emoji} ${space.pathLabel(widget.spaces)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => parentSpaceIdSelec = val);
                }
              },
            ),
            if (widget.canAssignUsers) ...[
              const SizedBox(height: 14),
              const Text(
                'Usuarios asignados',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              UsuariosAsignadosSelector(
                accounts: widget.accounts,
                selectedIds: _assignedIds,
                onChanged: (ids) => setState(() {
                  _assignedIds
                    ..clear()
                    ..addAll(ids);
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _confirmarEliminar,
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (nombreCtrl.text.trim().isNotEmpty) {
              widget.onActualizar(
                SpaceDraft(
                  sectionId: sectionIdSelec,
                  name: nombreCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? 'Área de trabajo'
                      : descCtrl.text.trim(),
                  emoji: emojiSelec,
                  parentSpaceId:
                      parentSpaceIdSelec == 0 ? null : parentSpaceIdSelec,
                  imageUrl: widget.space.imageUrl,
                  localImagePath: localImagePath,
                  assignedUserIds: _assignedIds.toList(),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
