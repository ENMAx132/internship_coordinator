import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';

final List<Apartado> apartadosIniciales = [
  Apartado(
    id: 'oficina',
    nombre: 'Oficina',
    icono: '\u{1F3E2}',
    descripcion: 'A\u00C1reas de la oficina',
  ),
  Apartado(
    id: 'hogar',
    nombre: 'Hogar',
    icono: '\u{1F3E0}',
    descripcion: 'Espacios del hogar',
  ),
];

final List<Espacio> espaciosIniciales = [
  Espacio(
    id: 'recepcion',
    nombre: 'Recepci\u00F3n',
    descripcion: 'Entrada principal y atenci\u00F3n...',
    emoji: '\u{1F3E2}',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'sistemas',
    nombre: 'Sala de Sistemas',
    descripcion: 'Servidores, respaldos y...',
    emoji: '\u{1F4BB}',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'gerencia',
    nombre: 'Gerencia',
    descripcion: 'Oficina directiva y de pl...',
    emoji: '\u{1F4CA}',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'almacen',
    nombre: 'Almac\u00E9n / Archivo',
    descripcion: 'Papeleri\u00EDa, suministros ...',
    emoji: '\u{1F4E6}',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'juntas',
    nombre: 'Sala de Juntas',
    descripcion: 'Espacio para conferen...',
    emoji: '\u{1F91D}',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'micuarto',
    nombre: 'Mi Cuarto',
    descripcion: 'Espacio personal',
    emoji: '\u{1F6CB}',
    apartadoId: 'hogar',
  ),
];

final List<ObjetoInventario> objetosIniciales = [
  ObjetoInventario(
    id: '1',
    placa: 'ACT-IT-001',
    nombre: 'Servidor Rack Dell PowerEdge R650',
    espacioId: 'sistemas',
    categoria: 'C\u00F3mputo & IT',
    estado: 'Operativo',
    valor: 3450.0,
    responsable: 'Carlos Ruiz',
    marca: 'Dell',
    fechaRegistro: DateTime(2026, 10, 24, 9, 15),
  ),
  ObjetoInventario(
    id: '2',
    placa: 'ACT-MOB-002',
    nombre: 'Silla Ergon\u00F3mica Herman Miller',
    espacioId: 'gerencia',
    categoria: 'Mobiliario',
    estado: 'Excelente',
    valor: 1250.0,
    responsable: 'Dra. Patricia Silva',
    marca: 'Herman Miller',
    fechaRegistro: DateTime(2026, 10, 25, 11, 40),
  ),
  ObjetoInventario(
    id: '3',
    placa: 'ACT-ALM-003',
    nombre: 'Kit T\u00F3ner & Repuestos HP LaserJet',
    espacioId: 'almacen',
    categoria: 'Suministros',
    estado: 'Operativo',
    valor: 320.0,
    responsable: 'Roberto G\u00F3mez',
    marca: 'HP',
    fechaRegistro: DateTime(2026, 10, 27, 15, 5),
  ),
  ObjetoInventario(
    id: '4',
    placa: 'ACT-AV-004',
    nombre: 'Sistema Videoconferencia Logitech Rally',
    espacioId: 'juntas',
    categoria: 'Audiovisual',
    estado: 'Excelente',
    valor: 2100.0,
    responsable: 'Recepci\u00F3n / General',
    marca: 'Logitech',
    fechaRegistro: DateTime(2026, 10, 29, 8, 30),
  ),
  ObjetoInventario(
    id: '5',
    placa: 'ACT-HO-005',
    nombre: 'Laptop Personal Dell XPS 15',
    espacioId: 'micuarto',
    categoria: 'Electr\u00F3nica',
    estado: 'Excelente',
    valor: 1800.0,
    responsable: 'Bernardo',
    marca: 'Dell',
    fechaRegistro: DateTime(2026, 10, 31, 19, 20),
  ),
];