import 'package:flutter/material.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/screens/visitas_screen.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'providers/auth_provider.dart';
import 'providers/paciente_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
// Removido ya que PacientesScreen no se usa directamente en las rutas
// import 'screens/pacientes_screen.dart'; 
import 'screens/home_screen.dart';
import 'screens/initial_sync_screen.dart'; // ✅ IMPORT AÑADIDO

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthProvider _authProvider = AuthProvider();
  late Connectivity _connectivity;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;
  bool _showSplash = true;
  bool _hasShownSplash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivity = Connectivity();
    _setupConnectivityListener();
    _initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - No reiniciar splash');
      if (_hasShownSplash && _isInitialized) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  Future<void> _initializeApp() async {
    if (_hasShownSplash && _isInitialized) {
      setState(() {
        _showSplash = false;
      });
      return;
    }

    try {
      final splashTimer = _hasShownSplash
          ? Future.value()
          : Future.delayed(const Duration(seconds: 3));

      if (!_hasShownSplash) {
        await _authProvider.clearOldSessions();
      }

      await _authProvider.autoLogin();

      if (_authProvider.isAuthenticated) {
        final connectivity = await Connectivity().checkConnectivity();
        final isOnline = connectivity != ConnectivityResult.none;

        if (isOnline) {
          try {
            final sedes = await ApiService.getSedes(_authProvider.token!);
            await DatabaseHelper.instance.saveSedes(sedes);
          } catch (e) {
            debugPrint('Error al cargar sedes: $e');
          }
        }
      }

      if (!_hasShownSplash) {
        await _authProvider.debugListUsers();
      }

      await splashTimer;

      setState(() {
        _isInitialized = true;
        _showSplash = false;
        _hasShownSplash = true;
      });

      if (_authProvider.isAuthenticated && navigatorKey.currentContext != null) {
        final pacienteProvider = Provider.of<PacienteProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        await pacienteProvider.loadPacientes();
      }
    } catch (e) {
      debugPrint('Error al inicializar app: $e');

      if (!_hasShownSplash) {
        await Future.delayed(const Duration(seconds: 3));
      }

      setState(() {
        _isInitialized = true;
        _showSplash = false;
        _hasShownSplash = true;
      });
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none && _authProvider.isAuthenticated) {
        try {
          await _authProvider.syncUserData();
          if (navigatorKey.currentContext != null) {
            await Provider.of<PacienteProvider>(
              navigatorKey.currentContext!,
              listen: false,
            ).syncData();
          }
        } catch (e) {
          debugPrint('Error en sincronización: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _authProvider),
        ChangeNotifierProvider(create: (_) => PacienteProvider(_authProvider)),
      ],
      child: MaterialApp(
        title: 'Anavie 1.0',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        navigatorKey: navigatorKey,
        
        // ✅ LÓGICA DE NAVEGACIÓN ACTUALIZADA
        // Esta lógica es robusta para decidir la pantalla inicial.
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!_isInitialized || (_showSplash && !_hasShownSplash)) {
              return SplashScreen(); // Muestra el splash mientras inicializa.
            }
            if (auth.isAuthenticated) {
              return HomeScreen(onLogout: () => auth.logout());
            }
            // Aquí pasamos `onLoginSuccess` como un callback vacío porque
            // la navegación a la pantalla de sync o home ahora se maneja
            // dentro de la propia LoginScreen.
            return LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {},
            );
          },
        ),

        // ✅ RUTAS DEFINIDAS CLARAMENTE PARA NAVEGACIÓN NOMBRADA
        routes: {
          '/home': (context) => HomeScreen(onLogout: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              }),
          '/profile': (context) => ProfileScreen(
                authProvider: _authProvider,
                onLogout: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
          '/visitas': (context) => VisitasScreen(onLogout: () {}),
          '/initial-sync': (context) => const InitialSyncScreen(),
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // No es necesario drenar el stream de esta manera, el `listen` se cancela solo.
    // _connectivity.onConnectivityChanged.drain(); 
    super.dispose();
  }
}