import 'package:flutter/material.dart';

class PasoTutorial {
  final GlobalKey objetivo;
  final String emoji;
  final String titulo;
  final String descripcion;
  final List<String> detalles;

  const PasoTutorial({
    required this.objetivo,
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    this.detalles = const [],
  });
}

class TutorialCoachMarks extends StatefulWidget {
  final List<PasoTutorial> pasos;
  final VoidCallback onFinalizar;
  final ValueChanged<int>? onPasoCambiado;

  const TutorialCoachMarks({
    super.key,
    required this.pasos,
    required this.onFinalizar,
    this.onPasoCambiado,
  });

  @override
  State<TutorialCoachMarks> createState() => _TutorialCoachMarksState();
}

class _TutorialCoachMarksState extends State<TutorialCoachMarks> {
  final GlobalKey _overlayKey = GlobalKey();
  int _indice = 0;
  int? _ultimoPasoNotificado;
  Rect? _rectObjetivo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificarPaso();
      _actualizarRect();
    });
  }

  @override
  void didUpdateWidget(covariant TutorialCoachMarks oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _actualizarRect());
  }

  void _notificarPaso() {
    if (_ultimoPasoNotificado == _indice) return;
    _ultimoPasoNotificado = _indice;
    widget.onPasoCambiado?.call(_indice);
  }

  void _actualizarRect() {
    if (!mounted) return;
    final paso = widget.pasos[_indice];
    final objetivoCtx = paso.objetivo.currentContext;
    final overlayCtx = _overlayKey.currentContext;
    if (objetivoCtx == null || overlayCtx == null) return;

    final objetivoBox = objetivoCtx.findRenderObject();
    final overlayBox = overlayCtx.findRenderObject();
    if (objetivoBox is! RenderBox ||
        overlayBox is! RenderBox ||
        !objetivoBox.hasSize ||
        !overlayBox.hasSize) {
      return;
    }

    final topLeft =
        overlayBox.globalToLocal(objetivoBox.localToGlobal(Offset.zero));
    setState(() => _rectObjetivo = topLeft & objetivoBox.size);
  }

  void _irA(int indice) {
    setState(() {
      _indice = indice;
      _rectObjetivo = null;
    });
    _notificarPaso();
    WidgetsBinding.instance.addPostFrameCallback((_) => _actualizarRect());
  }

  void _siguiente() {
    if (_indice >= widget.pasos.length - 1) {
      widget.onFinalizar();
      return;
    }
    _irA(_indice + 1);
  }

  @override
  Widget build(BuildContext context) {
    final paso = widget.pasos[_indice];
    final rect = _rectObjetivo;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Stack(
            key: _overlayKey,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScrimPainter(rect),
                ),
              ),
              _construirTarjeta(paso, rect),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTarjeta(PasoTutorial paso, Rect? rect) {
    final pantalla = MediaQuery.sizeOf(context);
    final ancho = (pantalla.width - 40).clamp(240.0, 340.0);

    final tarjeta = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(paso.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  paso.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            paso.descripcion,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Color(0xFF64748B),
            ),
          ),
          if (paso.detalles.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...paso.detalles.map(
              (detalle) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detalle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Paso ${_indice + 1} de ${widget.pasos.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onFinalizar,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Omitir'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (_indice > 0)
                OutlinedButton(
                  onPressed: () => _irA(_indice - 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    minimumSize: const Size(0, 38),
                  ),
                  child: const Text('Anterior'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _siguiente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                ),
                child: Text(
                  _indice >= widget.pasos.length - 1 ? 'Listo' : 'Siguiente',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (rect == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ancho),
            child: tarjeta,
          ),
        ),
      );
    }

    final izquierda = (rect.center.dx - ancho / 2)
        .clamp(16.0, pantalla.width - ancho - 16.0);
    final mostrarArriba = rect.top > 240;

    if (mostrarArriba) {
      return Positioned(
        left: izquierda,
        width: ancho,
        bottom: pantalla.height - rect.top + 16,
        child: tarjeta,
      );
    }
    return Positioned(
      left: izquierda,
      width: ancho,
      top: rect.bottom + 16,
      child: tarjeta,
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect? objetivo;

  _ScrimPainter(this.objetivo);

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Path()..addRect(Offset.zero & size);
    final relleno = Paint()..color = const Color(0xCC0F172A);

    if (objetivo == null) {
      canvas.drawPath(fondo, relleno);
      return;
    }

    final recorte = RRect.fromRectAndRadius(
      objetivo!.inflate(8),
      const Radius.circular(18),
    );
    final caminoRecorte = Path()..addRRect(recorte);
    final camino =
        Path.combine(PathOperation.difference, fondo, caminoRecorte);
    canvas.drawPath(camino, relleno);
    canvas.drawRRect(
      recorte,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF6366F1),
    );
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) =>
      oldDelegate.objetivo != objetivo;
}
