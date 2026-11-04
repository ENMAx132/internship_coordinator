import 'package:flutter/material.dart';

import '../../models/apartado.dart';

class CrearApartadoDialog extends StatefulWidget {
  final ValueChanged<Apartado> onCrear;

  const CrearApartadoDialog({super.key, required this.onCrear});

  @override
  State<CrearApartadoDialog> createState() => _CrearApartadoDialogState();
}

class _CrearApartadoDialogState extends State<CrearApartadoDialog> {
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String emojiSelec = '🏢';
  final emojis = [
    '🏢',
    '💻',
    '📊',
    '📦',
    '🤝',
    '☕',
    '🔬',
    '🛋️',
    '🏠',
    '🎮',
    '📚',
    '🔥',
  ];

  int _paso = 0;

  static const List<String> _ayudas = [
    'Elige un ícono para el apartado',
    '¿Cómo se llama el apartado?',
    'Descripción breve (opcional)',
  ];

  int get _totalPasos => _ayudas.length;

  bool get _esUltimoPaso => _paso == _totalPasos - 1;

  @override
  void dispose() {
    nombreCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _avanzar() {
    if (_esUltimoPaso) {
      _crear();
      return;
    }
    setState(() => _paso++);
  }

  void _atras() {
    if (_paso > 0) {
      setState(() => _paso--);
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
        break;
      case 1:
        nombreCtrl.clear();
        break;
      default:
        descCtrl.clear();
        break;
    }
  }

  void _crear() {
    widget.onCrear(
      Apartado(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: nombreCtrl.text.trim().isEmpty
            ? 'Sin nombre'
            : nombreCtrl.text.trim(),
        icono: emojiSelec,
        descripcion: descCtrl.text.trim().isEmpty
            ? 'Nuevo apartado'
            : descCtrl.text.trim(),
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
        'Nuevo Apartado',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                key: ValueKey(_paso),
                height: _paso == 0 ? 150 : 96,
                child: Column(
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
                    Expanded(child: _construirCampo()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _paso == 0 ? null : _atras,
          child: const Text('Atrás'),
        ),
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
        return SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: emojis.map((e) {
              return ChoiceChip(
                label: Text(e, style: const TextStyle(fontSize: 18)),
                selected: emojiSelec == e,
                onSelected: (sel) {
                  if (sel) setState(() => emojiSelec = e);
                },
              );
            }).toList(),
          ),
        );
      case 1:
        return TextField(
          controller: nombreCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre del apartado'),
          onSubmitted: (_) => _avanzar(),
        );
      default:
        return TextField(
          controller: descCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Descripción breve'),
          onSubmitted: (_) => _avanzar(),
        );
    }
  }
}
