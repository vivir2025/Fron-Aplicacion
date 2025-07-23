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
import 'screens/pacientes_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver { // ✅ AGREGADO
  final AuthProvider _authProvider = AuthProvider();
  late Connectivity _connectivity;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;
  bool _showSplash = true;
  bool _hasShownSplash = false; // ✅ NUEVO: Recordar si ya se mostró el splash

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ AGREGADO
    _connectivity = Connectivity();
    _setupConnectivityListener();
    _initializeApp();
  }

  // ✅ NUEVO: Detectar cuando la app vuelve del background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // La app volvió del background (ej: después de tomar foto)
      debugPrint('App resumed - No reiniciar splash');
      
      // Si ya se había inicializado antes, no mostrar splash de nuevo
      if (_hasShownSplash && _isInitialized) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  // ✅ MÉTODO MEJORADO: Inicializar la aplicación
  Future<void> _initializeApp() async {
    // Si ya se inicializó antes, no hacerlo de nuevo
    if (_hasShownSplash && _isInitialized) {
      setState(() {
        _showSplash = false;
      });
      return;
    }

    try {
      // Solo mostrar splash la primera vez
      final splashTimer = _hasShownSplash 
          ? Future.value() // No esperar si ya se mostró
          : Future.delayed(Duration(seconds: 3)); // ✅ Reducido a 3 segundos
      
      // Limpiar sesiones anteriores solo la primera vez
      if (!_hasShownSplash) {
        await _authProvider.clearOldSessions();
      }
      
      // Intentar auto-login
      await _authProvider.autoLogin();
      
      // Si está autenticado, cargar datos iniciales
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
      
      // Debug solo la primera vez
      if (!_hasShownSplash) {
        await _authProvider.debugListUsers();
      }
      
      // Esperar splash solo si es necesario
      await splashTimer;
      
      setState(() {
        _isInitialized = true;
        _showSplash = false;
        _hasShownSplash = true; // ✅ Marcar que ya se mostró
      });
      
      // Cargar pacientes después del splash
      if (_authProvider.isAuthenticated && navigatorKey.currentContext != null) {
        final pacienteProvider = Provider.of<PacienteProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        await pacienteProvider.loadPacientes();
      }
      
    } catch (e) {
      debugPrint('Error al inicializar app: $e');
      
      // Esperar solo si es la primera vez
      if (!_hasShownSplash) {
        await Future.delayed(Duration(seconds: 3));
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
        // ✅ LÓGICA MEJORADA PARA MOSTRAR SCREENS
        home: Builder(
          builder: (context) {
            // Si debe mostrar splash Y no se ha mostrado antes
            if (_showSplash && !_hasShownSplash) {
              return SplashScreen();
            }
            
            // Si no está inicializado, mostrar loading
            if (!_isInitialized) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Si ya está todo listo, mostrar la app normal
            return Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isAuthenticated) {
                  // Cargar pacientes solo una vez
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final pacienteProvider = Provider.of<PacienteProvider>(context, listen: false);
                    if (!pacienteProvider.isLoaded) { // ✅ Solo si no están cargados
                      pacienteProvider.loadPacientes();
                    }
                  });
                  
                  return HomeScreen(
                    onLogout: () {
                      auth.logout();
                    },
                  );
                } else {
                  return LoginScreen(
                    authProvider: _authProvider,
                    onLoginSuccess: () {
                      // El Consumer manejará el cambio
                    },
                  );
                }
              },
            );
          },
        ),
        routes: {
          '/profile': (context) => ProfileScreen(
                authProvider: _authProvider,
                onLogout: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
          '/visitas': (context) => VisitasScreen(onLogout: () {}),
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ AGREGADO
    _connectivity.onConnectivityChanged.drain();
    super.dispose();
  }
}
