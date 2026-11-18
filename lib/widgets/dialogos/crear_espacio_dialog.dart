import 'package:flutter/material.dart';

import '../../models/drafts.dart';
import '../../models/section.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

class CrearEspacioDialog extends StatefulWidget {
  final ValueChanged<SpaceDraft> onCrear;
  final List<Section> sections;
  final List<String> emojis;

  const CrearEspacioDialog({
    super.key,
    required this.onCrear,
    required this.sections,
    this.emojis = const ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️'],
  });

  @override
  State<CrearEspacioDialog> createState() => _CrearEspacioDialogState();
}

class _CrearEspacioDialogState extends State<CrearEspacioDialog> {
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String emojiSelec = '🏢';
  String? localImagePath;
  bool _emojisVisibles = false;
  bool _nombreInvalido = false;
  late int sectionIdSelec;

  List<String> get _emojis => widget.emojis.isEmpty
      ? const ['🏢', '💻', '📊', '📦']
      : widget.emojis;

  int _paso = 0;

  static const List<String> _ayudas = [
    'Elige un ícono para el espacio',
    '¿Cómo se llama el espacio?',
    'Descripción breve (opcional)',
    '¿A qué apartado pertenece?',
  ];

  int get _totalPasos => _ayudas.length;

  bool get _esUltimoPaso => _paso == _totalPasos - 1;

  @override
  void initState() {
    super.initState();
    sectionIdSelec =
        widget.sections.isNotEmpty ? widget.sections.first.id : 0;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _avanzar() {
    if (_paso == 1 && nombreCtrl.text.trim().isEmpty) {
      setState(() => _nombreInvalido = true);
      return;
    }
    if (_esUltimoPaso) {
      _crear();
      return;
    }
    setState(() {
      _nombreInvalido = false;
      _emojisVisibles = false;
      _paso++;
    });
  }

  void _atras() {
    if (_paso > 0) {
      setState(() {
        _emojisVisibles = false;
        _paso--;
      });
    }
  }

  void _omitir() {
    _limpiarPasoActual();
    _avanzar();
  }

  void _limpiarPasoActual() {
    switch (_paso) {
      case 0:
        emojiSelec = '🏢';
        localImagePath = null;
        break;
      case 1:
        nombreCtrl.clear();
        break;
      case 2:
        descCtrl.clear();
        break;
      default:
        if (widget.sections.isNotEmpty) {
          sectionIdSelec = widget.sections.first.id;
        }
        break;
    }
  }

  void _crear() {
    widget.onCrear(
      SpaceDraft(
        sectionId: sectionIdSelec,
        name: nombreCtrl.text.trim().isEmpty
            ? 'Sin nombre'
            : nombreCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty
            ? 'Área de trabajo'
            : descCtrl.text.trim(),
        emoji: emojiSelec,
        localImagePath: localImagePath,
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
        'Nuevo Espacio',
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
      actions: _emojisVisibles
          ? null
          : [
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
                child: Text(_esUltimoPaso ? 'Crear' : 'Siguiente'),
              ),
            ],
    );
  }

  Widget _construirCampo() {
    switch (_paso) {
      case 0:
        return SelectorImagenIcono(
          emoji: emojiSelec,
          localImagePath: localImagePath,
          emojis: _emojis,
          size: 104,
          onImagePicked: (p) => setState(() => localImagePath = p),
          onEmojiChange: (e) => setState(() => emojiSelec = e),
          onEmojisVisibilityChanged: (visible) =>
              setState(() => _emojisVisibles = visible),
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
            labelText: 'Nombre del espacio',
            errorText: _nombreInvalido ? 'El nombre es obligatorio' : null,
          ),
          onSubmitted: (_) => _avanzar(),
        );
      case 2:
        return TextField(
          controller: descCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Descripción breve'),
          onSubmitted: (_) => _avanzar(),
        );
      default:
        return DropdownButtonFormField<int>(
          initialValue: sectionIdSelec,
          decoration: const InputDecoration(labelText: 'Apartado'),
          items: widget.sections.map((e) {
            return DropdownMenuItem(
              value: e.id,
              child: Text('${e.icon} ${e.name}'),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => sectionIdSelec = val);
          },
        );
    }
  }
}
