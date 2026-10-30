import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';

final List<Apartado> apartadosIniciales = [
  Apartado(
    id: 'oficina',
    nombre: 'Oficina',
    icono: '🏢',
    descripcion: 'Áreas de la oficina',
  ),
  Apartado(
    id: 'hogar',
    nombre: 'Hogar',
    icono: '🏠',
    descripcion: 'Espacios del hogar',
  ),
];

final List<Espacio> espaciosIniciales = [
  Espacio(
    id: 'recepcion',
    nombre: 'Recepción',
    descripcion: 'Entrada principal y atención...',
    emoji: '🏢',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'sistemas',
    nombre: 'Sala de Sistemas',
    descripcion: 'Servidores, respaldos y...',
    emoji: '💻',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'gerencia',
    nombre: 'Gerencia',
    descripcion: 'Oficina directiva y de pl...',
    emoji: '📊',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'almacen',
    nombre: 'Almacén / Archivo',
    descripcion: 'Papelería, suministros ...',
    emoji: '📦',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'juntas',
    nombre: 'Sala de Juntas',
    descripcion: 'Espacio para conferen...',
    emoji: '🤝',
    apartadoId: 'oficina',
  ),
  Espacio(
    id: 'micuarto',
    nombre: 'Mi Cuarto',
    descripcion: 'Espacio personal',
    emoji: '🛋️',
    apartadoId: 'hogar',
  ),
];

final List<ObjetoInventario> objetosIniciales = [
  ObjetoInventario(
    id: '1',
    placa: 'ACT-IT-001',
    nombre: 'Servidor Rack Dell PowerEdge R650',
    espacioId: 'sistemas',
    categoria: 'Cómputo & IT',
    estado: 'Operativo',
    valor: 3450.0,
    responsable: 'Carlos Ruiz',
  ),
  ObjetoInventario(
    id: '2',
    placa: 'ACT-MOB-002',
    nombre: 'Silla Ergonómica Herman Miller',
    espacioId: 'gerencia',
    categoria: 'Mobiliario',
    estado: 'Excelente',
    valor: 1250.0,
    responsable: 'Dra. Patricia Silva',
  ),
  ObjetoInventario(
    id: '3',
    placa: 'ACT-ALM-003',
    nombre: 'Kit Tóner & Repuestos HP LaserJet',
    espacioId: 'almacen',
    categoria: 'Suministros',
    estado: 'Operativo',
    valor: 320.0,
    responsable: 'Roberto Gómez',
  ),
  ObjetoInventario(
    id: '4',
    placa: 'ACT-AV-004',
    nombre: 'Sistema Videoconferencia Logitech Rally',
    espacioId: 'juntas',
    categoria: 'Audiovisual',
    estado: 'Excelente',
    valor: 2100.0,
    responsable: 'Recepción / General',
  ),
  ObjetoInventario(
    id: '5',
    placa: 'ACT-HO-005',
    nombre: 'Laptop Personal Dell XPS 15',
    espacioId: 'micuarto',
    categoria: 'Electrónica',
    estado: 'Excelente',
    valor: 1800.0,
    responsable: 'Bernardo',
  ),
];