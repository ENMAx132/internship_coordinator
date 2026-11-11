import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

class CrearObjetoDialog extends StatefulWidget {
  final List<Espacio> espacios;
  final String placaInicial;
  final ValueChanged<ObjetoInventario> onGuardar;

  const CrearObjetoDialog({
    super.key,
    required this.espacios,
    required this.placaInicial,
    required this.onGuardar,
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
  late String espacioIdSelec;
  late String categoriaSelec;
  late String estadoSelec;
  String? imagePathSelec;
  bool _nombreInvalido = false;

  int _paso = 0;

  static const List<String> _ayudas = [
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

  int get _totalPasos => _ayudas.length;

  bool get _esUltimoPaso => _paso == _totalPasos - 1;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController();
    placaCtrl = TextEditingController(text: widget.placaInicial);
    marcaCtrl = TextEditingController();
    respCtrl = TextEditingController();
    valorCtrl = TextEditingController(text: '0');
    espacioIdSelec = widget.espacios.isNotEmpty ? widget.espacios.first.id : '';
    categoriaSelec = ObjetoInventario.categoriasDisponibles.first;
    estadoSelec = ObjetoInventario.estadosDisponibles.first;
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

  void _avanzar() {
    if (_paso == 1 && nombreCtrl.text.trim().isEmpty) {
      setState(() => _nombreInvalido = true);
      return;
    }
    if (_esUltimoPaso) {
      _guardar();
      return;
    }
    setState(() {
      _nombreInvalido = false;
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
    _avanzar();
  }

  void _limpiarPasoActual() {
    switch (_paso) {
      case 0:
        imagePathSelec = null;
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
        break;
      case 5:
        valorCtrl.clear();
        break;
      case 6:
        categoriaSelec = ObjetoInventario.categoriasDisponibles.first;
        break;
      case 7:
        estadoSelec = ObjetoInventario.estadosDisponibles.first;
        break;
      default:
        if (widget.espacios.isNotEmpty) {
          espacioIdSelec = widget.espacios.first.id;
        }
        break;
    }
  }

  void _guardar() {
    widget.onGuardar(
      ObjetoInventario(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        placa: placaCtrl.text.trim().isEmpty
            ? widget.placaInicial
            : placaCtrl.text.trim(),
        nombre: nombreCtrl.text.trim().isEmpty
            ? 'Sin nombre'
            : nombreCtrl.text.trim(),
        espacioId: espacioIdSelec,
        categoria: categoriaSelec,
        estado: estadoSelec,
        valor: double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0,
        responsable:
            respCtrl.text.trim().isEmpty ? 'Sin asignar' : respCtrl.text.trim(),
        marca: marcaCtrl.text.trim(),
        imagePath: imagePathSelec,
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
          emoji: widget.espacios.isNotEmpty ? widget.espacios.first.emoji : '📦',
          imagePath: imagePathSelec,
          onImagePicked: (p) => setState(() => imagePathSelec = p),
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
            errorText:
                _nombreInvalido ? 'El nombre es obligatorio' : null,
          ),
          onSubmitted: (_) => _avanzar(),
        );
      case 2:
        return TextField(
          controller: placaCtrl,
          decoration: const InputDecoration(labelText: 'Código / Placa'),
          onSubmitted: (_) => _avanzar(),
        );
      case 3:
        return TextField(
          controller: marcaCtrl,
          decoration: const InputDecoration(labelText: 'Marca'),
          onSubmitted: (_) => _avanzar(),
        );
      case 4:
        return TextField(
          controller: respCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Responsable'),
          onSubmitted: (_) => _avanzar(),
        );
      case 5:
        return TextField(
          controller: valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Precio'),
          onSubmitted: (_) => _avanzar(),
        );
      case 6:
        return DropdownButtonFormField<String>(
          initialValue: categoriaSelec,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: ObjetoInventario.categoriasDisponibles.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => categoriaSelec = val);
          },
        );
      case 7:
        return DropdownButtonFormField<String>(
          initialValue: estadoSelec,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: ObjetoInventario.estadosDisponibles.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => estadoSelec = val);
          },
        );
      default:
        return DropdownButtonFormField<String>(
          initialValue: espacioIdSelec,
          decoration: const InputDecoration(labelText: 'Espacio / Sala'),
          items: widget.espacios.map((e) {
            return DropdownMenuItem(
              value: e.id,
              child: Text('${e.emoji} ${e.nombre}'),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => espacioIdSelec = val);
          },
        );
    }
  }
}
