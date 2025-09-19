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
import 'screens/home_screen.dart';
import 'screens/initial_sync_screen.dart';

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

  // ✅ MÉTODO DE LOGOUT MEJORADO CON NAVEGACIÓN FORZADA
  Future<void> _handleLogout() async {
    try {
      debugPrint('🔘 main.dart: Iniciando logout...');
      
      // Ejecutar logout en el AuthProvider
      await _authProvider.logout();
      
      debugPrint('✅ main.dart: Logout completado, AuthProvider actualizado');
      
      // ✅ FORZAR NAVEGACIÓN AL LOGIN INMEDIATAMENTE
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          debugPrint('🔄 Forzando navegación al LoginScreen...');
          
          // Opción 1: Usar Navigator.pushAndRemoveUntil
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                authProvider: _authProvider,
                onLoginSuccess: () {},
              ),
            ),
            (route) => false, // Remover todas las rutas anteriores
          );
          
          debugPrint('✅ Navegación forzada completada');
        }
      });
      
    } catch (e) {
      debugPrint('❌ main.dart: Error en logout: $e');
      
      // Aún así, forzar logout local por seguridad
      try {
        await _authProvider.forceLogout();
        debugPrint('✅ main.dart: Logout forzado completado');
        
        // También forzar navegación en caso de error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => LoginScreen(
                  authProvider: _authProvider,
                  onLoginSuccess: () {},
                ),
              ),
              (route) => false,
            );
          }
        });
        
      } catch (forceError) {
        debugPrint('❌ main.dart: Error en logout forzado: $forceError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => PacienteProvider(_authProvider)),
      ],
      child: MaterialApp(
        title: 'Anavie 1.0',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        navigatorKey: navigatorKey,
        
        // ✅ CONSUMER CON LOGS MEJORADOS Y DETECCIÓN DE CAMBIOS
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // ✅ LOG DETALLADO DEL ESTADO ACTUAL
            debugPrint('🔍 Consumer rebuild - Auth: ${auth.isAuthenticated}, Token: ${auth.token != null ? "presente" : "null"}, User: ${auth.user != null ? auth.user!['nombre'] : "null"}, Initialized: $_isInitialized, ShowSplash: $_showSplash');
            
            // Mostrar splash mientras inicializa
            if (!_isInitialized || (_showSplash && !_hasShownSplash)) {
              debugPrint('📱 Mostrando SplashScreen');
              return SplashScreen();
            }
            
            // ✅ VERIFICACIÓN MÁS ESTRICTA DE AUTENTICACIÓN
            if (auth.isAuthenticated && auth.token != null && auth.user != null) {
              debugPrint('✅ Usuario autenticado, mostrando HomeScreen');
              return HomeScreen(
                onLogout: _handleLogout,
              );
            }
            
            // Si no está autenticado, mostrar login
            debugPrint('❌ Usuario no autenticado, mostrando LoginScreen');
            return LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {
                debugPrint('✅ Login exitoso detectado en main.dart');
              },
            );
          },
        ),

        routes: {
          '/home': (context) => HomeScreen(
            onLogout: _handleLogout,
          ),
          '/profile': (context) => ProfileScreen(
            authProvider: _authProvider,
            onLogout: _handleLogout,
          ),
          '/visitas': (context) => VisitasScreen(
            onLogout: _handleLogout,
          ),
          '/initial-sync': (context) => const InitialSyncScreen(),
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
