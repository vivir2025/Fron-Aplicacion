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
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ IMPORT PARA LOCALIZACIÓN

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
      
      // ✅ Migrar UUIDs antiguos con prefijo 'vis_' a UUIDs estándar
      try {
        await DatabaseHelper.instance.migrarUUIDsAntiguos();
      } catch (e) {
        debugPrint('⚠️ Error al migrar UUIDs antiguos: $e');
      }

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

  // ✅ FUNCIÓN DE LOGOUT CON NAVEGACIÓN DIRECTA
  Future<void> _handleLogout() async {
    try {
      debugPrint('🔘 main.dart: Iniciando logout...');
      
      // Ejecutar logout en el AuthProvider
      await _authProvider.logout();
      
      debugPrint('✅ main.dart: Logout completado, navegando directamente...');
      
      // ✅ NAVEGAR DIRECTAMENTE AL LOGIN (bypasea el Consumer problemático)
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {
                debugPrint('✅ Login exitoso - navegando a home');
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
          ),
          (route) => false, // Remover todas las rutas anteriores
        );
        debugPrint('🚀 Navegación directa al LoginScreen completada');
      } else {
        debugPrint('❌ NavigatorKey.currentContext es null');
      }
      
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ MyApp build()');
    
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
        
        // ✅ CONFIGURACIÓN DE LOCALIZACIÓN EN ESPAÑOL
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español (principal)
          Locale('en', 'US'), // Inglés (respaldo)
        ],
        locale: const Locale('es', 'ES'), // ✅ IDIOMA POR DEFECTO: ESPAÑOL
        
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            debugPrint('🔍 Consumer rebuild - Auth: ${auth.isReallyAuthenticated}');
            
            // Mostrar splash mientras inicializa
            if (!_isInitialized || (_showSplash && !_hasShownSplash)) {
              debugPrint('📱 Mostrando SplashScreen');
              return SplashScreen();
            }
            
            // ✅ USAR isReallyAuthenticated
            if (auth.isReallyAuthenticated) {
              debugPrint('✅ Usuario autenticado, mostrando HomeScreen');
              return HomeScreen(onLogout: _handleLogout);
            }
            
            debugPrint('❌ Usuario no autenticado, mostrando LoginScreen');
            return LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {
                debugPrint('✅ Login exitoso');
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
