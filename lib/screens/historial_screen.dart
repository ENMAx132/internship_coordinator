import 'package:flutter/material.dart';

import '../data/inventario_data.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../models/registro_revision.dart';
import '../widgets/icono_widget.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  int _vista = 0;

  Espacio _espacioDe(String id) {
    return espaciosIniciales.firstWhere(
      (e) => e.id == id,
      orElse: () => Espacio(
        id: '',
        nombre: 'Sin espacio',
        descripcion: '',
        emoji: '📍',
        apartadoId: '',
      ),
    );
  }

  ObjetoInventario? _objetoDe(String id) {
    for (final objeto in objetosIniciales) {
      if (objeto.id == id) return objeto;
    }
    return null;
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: inventarioVersion,
      builder: (context, _, __) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Historial',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _vista == 0
                    ? 'Objetos que han pasado por revisión'
                    : 'Objetos agregados y su fecha de registro',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _construirChip(
                      'Revisiones',
                      _vista == 0,
                      () => setState(() => _vista = 0),
                    ),
                    const SizedBox(width: 8),
                    _construirChip(
                      'Registros',
                      _vista == 1,
                      () => setState(() => _vista = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _vista == 0
                    ? _construirRevisiones()
                    : _construirRegistros(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirChip(String texto, bool seleccionado, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _construirRevisiones() {
    final revisiones = [...historialRevisiones]
      ..sort((a, b) => b.fechaEntrada.compareTo(a.fechaEntrada));

    if (revisiones.isEmpty) {
      return _construirVacio(
        '🛠️',
        'Aún no hay objetos que hayan pasado por revisión',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: revisiones.length,
      itemBuilder: (context, index) {
        return _construirRegistroRevision(revisiones[index]);
      },
    );
  }

  Widget _construirRegistroRevision(RegistroRevision registro) {
    final objeto = _objetoDe(registro.objetoId);
    final espacio = _espacioDe(objeto?.espacioId ?? registro.espacioId);
    final nombre = objeto?.nombre ?? registro.nombre;
    final placa = objeto?.placa ?? registro.placa;
    final activo = registro.enRevision;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconoWidget(
              imagePath: objeto?.imagePath ?? registro.imagePath,
              emoji: espacio.emoji,
              fontSize: 20,
              size: 42,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activo
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activo ? 'En revisión' : 'Finalizada',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: activo
                              ? const Color(0xFFB45309)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$placa · ${espacio.nombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.login,
                      size: 12,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Ingresó ${_formatearFecha(registro.fechaEntrada)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                if (registro.fechaSalida != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Salió ${_formatearFecha(registro.fechaSalida!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (registro.motivoSalida != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Motivo: ${registro.motivoSalida}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRegistros() {
    final objetos = [...objetosIniciales]
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

    if (objetos.isEmpty) {
      return _construirVacio('🕘', 'Aún no hay objetos registrados');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: objetos.length,
      itemBuilder: (context, index) {
        final objeto = objetos[index];
        return _construirRegistroObjeto(objeto);
      },
    );
  }

  Widget _construirRegistroObjeto(ObjetoInventario objeto) {
    final espacio = _espacioDe(objeto.espacioId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconoWidget(
              imagePath: objeto.imagePath ?? espacio.imagePath,
              emoji: espacio.emoji,
              fontSize: 20,
              size: 42,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objeto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${objeto.placa} · ${espacio.nombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearFecha(objeto.fechaRegistro),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVacio(String emoji, String mensaje) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
