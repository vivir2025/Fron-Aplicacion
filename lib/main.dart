import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:Bornive/api/api_service.dart';
import 'package:Bornive/database/database_helper.dart';
import 'package:Bornive/screens/visitas_screen.dart';
import 'package:Bornive/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'providers/auth_provider.dart';
import 'providers/paciente_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/initial_sync_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ IMPORT PARA LOCALIZACIÓN
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Inicializar Firebase (safe - no bloquea si falla)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // La app sigue funcionando sin Firebase
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthProvider _authProvider = AuthProvider();
  final NotificationService _notificationService = NotificationService();
  final NotificationProvider _notificationProvider = NotificationProvider();
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
    _initializeNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_hasShownSplash && _isInitialized) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  /// Inicializar servicio de notificaciones (no bloquea la app)
  Future<void> _initializeNotifications() async {
    try {
      // Cargar notificaciones guardadas
      await _notificationProvider.loadNotifications();
      // Conectar provider con el servicio
      _notificationService.setNotificationProvider(_notificationProvider);
      await _notificationService.initialize();
    } catch (e) {
      // Silencioso
    }
  }

  /// Registrar token FCM después de autoLogin (cuando el usuario ya tenía sesión)
  void _registrarTokenFCMAutoLogin() {
    try {
      final user = _authProvider.user;
      final token = _authProvider.token;

      if (user == null || user['id'] == null || token == null) {
        return;
      }

      final userId = user['id'].toString();

      if (userId.isNotEmpty) {
        _notificationService.registrarTokenConUsuario(userId, token).then((_) {
        }).catchError((e) {
        });
      }
    } catch (e) {
      // Silencioso
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
        // Silencioso
      }

      if (_authProvider.isAuthenticated) {
        final connectivity = await Connectivity().checkConnectivity();
        final isOnline = connectivity != ConnectivityResult.none;

        if (isOnline) {
          try {
            final sedes = await ApiService.getSedes(_authProvider.token!);
            await DatabaseHelper.instance.saveSedes(sedes);
          } catch (e) {
            // Silencioso
          }
        }

        // ✅ Registrar token FCM después del autoLogin exitoso
        _registrarTokenFCMAutoLogin();
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
    } catch (e) {
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
          
          // ✅ Reintentar registro de token FCM pendiente
          if (_authProvider.token != null) {
            await _notificationService.reintentarRegistroPendiente(
              _authProvider.token!,
            );
          }
        } catch (e) {
          // Silencioso
        }
      }
    });
  }

  // ✅ FUNCIÓN DE LOGOUT CON NAVEGACIÓN DIRECTA
  Future<void> _handleLogout() async {
    try {
      await _notificationService.desregistrarToken(_authProvider.token);
      await _authProvider.logout();
      
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Silencioso
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => PacienteProvider(_authProvider)),
        ChangeNotifierProvider.value(value: _notificationProvider),
      ],
      child: MaterialApp(
        title: 'Anavie 1.0',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.robotoTextTheme(),
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
            if (!_isInitialized || (_showSplash && !_hasShownSplash)) {
              return SplashScreen();
            }
            
            if (auth.isReallyAuthenticated) {
              return HomeScreen(onLogout: _handleLogout);
            }
            
            return LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {
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
