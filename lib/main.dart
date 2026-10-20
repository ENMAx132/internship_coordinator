import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario de Pasantes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// MODELO DE DATOS Y BASE DE DATOS LOCAL
// ==========================================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventario_pasantes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabla de Ubicaciones (Estantes/Zonas)
    await db.execute('''
      CREATE TABLE ubicaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_qr TEXT UNIQUE,
        nombre TEXT
      )
    ''');

    // Tabla de Productos / Equipos
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        categoria TEXT,
        cantidad INTEGER,
        estado TEXT,
        ubicacion_codigo TEXT
      )
    ''');

    // Datos de ejemplo iniciales
    await db.insert('ubicaciones', {'codigo_qr': 'ESTANTE-A1', 'nombre': 'Estante Principal de Redes'});
    await db.insert('productos', {
      'nombre': 'Switch Cisco 24 Puertos',
      'categoria': 'Redes',
      'cantidad': 2,
      'estado': 'Operativo',
      'ubicacion_codigo': 'ESTANTE-A1'
    });
  }

  Future<List<Map<String, dynamic>>> getProductosPorUbicacion(String codigoQr) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'ubicacion_codigo = ?',
      whereArgs: [codigoQr],
    );
  }

  Future<List<Map<String, dynamic>>> getAllProductos() async {
    final db = await database;
    return await db.query('productos');
  }
}

// ==========================================
// PANTALLA PRINCIPAL
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _productosList;

  @override
  void initState() {
    super.initState();
    _actualizarLista();
  }

  void _actualizarLista() {
    setState(() {
      _productosList = DatabaseHelper.instance.getAllProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario y Control de Pasantes'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productosList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay productos registrados. ¡Escanea un código QR!'));
          }

          final productos = snapshot.data!;
          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final prod = productos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.devices, color: Colors.blueAccent),
                  title: Text(prod['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Ubicación: ${prod['ubicacion_codigo']} | Estado: ${prod['estado']}'),
                  trailing: Text('Cant: ${prod['cantidad']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Abrir la pantalla de escaneo QR
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScanScreen()),
          );
          if (resultado != null) {
            _actualizarLista();
          }
        },
        label: const Text('Escanear QR'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE ESCANEO QR
// ==========================================
class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Ubicación QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? codigoScaneado = barcode.rawValue;
            if (codigoScaneado != null) {
              // Regresa a la pantalla anterior con el código detectado
              Navigator.pop(context, codigoScaneado);
              break;
            }
          }
        },
      ),
    );
  }
}