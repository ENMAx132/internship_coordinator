import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/inventory_scope.dart';
import 'core/session.dart';
import 'data/inventory_repository.dart';
import 'data/inventory_store.dart';
import 'data/local_inventory_cache.dart';
import 'data/tutorial_store.dart';
import 'screens/access_denied_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InventarioApp());
}

class InventarioApp extends StatefulWidget {
  const InventarioApp({super.key});

  @override
  State<InventarioApp> createState() => _InventarioAppState();
}

class _InventarioAppState extends State<InventarioApp> {
  final SessionStore _sessionStore = SessionStore();
  Session? _session;
  InventoryStore? _store;
  bool _restoring = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await _sessionStore.load();
    if (!mounted) return;
    setState(() {
      _session = session;
      _restoring = false;
    });
    if (session != null && session.user.canAccessInventory) {
      _createStore(session);
    }
  }

  void _createStore(Session session) {
    final client = ApiClient(token: session.token);
    final store = InventoryStore(
      repository: InventoryRepository(client),
      cache: LocalInventoryCache(userId: session.user.id),
      session: session,
      sessionStore: _sessionStore,
      tutorialStore: TutorialStore(),
      onUnauthorized: _logout,
    );
    _store?.dispose();
    if (mounted) {
      setState(() => _store = store);
    } else {
      _store = store;
    }
    store.bootstrap();
  }

  Future<void> _handleLogin(Session session) async {
    await _sessionStore.save(session);
    if (!mounted) return;
    setState(() => _session = session);
    if (session.user.canAccessInventory) {
      _createStore(session);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    await _sessionStore.clear();
    _store?.dispose();
    if (!mounted) {
      _loggingOut = false;
      return;
    }
    setState(() {
      _session = null;
      _store = null;
    });
    _loggingOut = false;
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFBFBFE),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        primary: const Color(0xFF6366F1),
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
    );

    final materialApp = MaterialApp(
      title: 'Inventario',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.copyWith(
          bodyLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF6366F1),
          selectionColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
          selectionHandleColor: const Color(0xFF6366F1),
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          backgroundColor: const Color(0xFFF8FAFC),
          selectedColor: const Color(0xFFEEF2FF),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6366F1),
          ),
          hintStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF6366F1),
              width: 1.4,
            ),
          ),
        ),
      ),
      home: _buildHome(),
    );

    final store = _store;
    if (store == null) return materialApp;
    return InventoryScope(store: store, child: materialApp);
  }

  Widget _buildHome() {
    if (_restoring) {
      return const _FullScreenLoader(message: 'Iniciando sesión…');
    }

    final session = _session;
    if (session == null) {
      return LoginScreen(onLogin: _handleLogin);
    }

    if (!session.user.canAccessInventory) {
      return AccessDeniedScreen(user: session.user, onLogout: _logout);
    }

    final store = _store;
    if (store == null) {
      return const _FullScreenLoader(message: 'Cargando inventario…');
    }

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.initialized && store.loading) {
          return _FullScreenLoader(message: store.loadingMessage);
        }
        if (!store.initialized && store.lastError != null) {
          return _ErrorScreen(
            message: store.lastError!,
            onRetry: store.retryConnection,
            onLogout: _logout,
          );
        }
        return HomeScreen(onLogout: _logout);
      },
    );
  }
}

class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📡', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo cargar el inventario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: onLogout,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
