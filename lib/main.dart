import 'package:flutter/material.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/screens/visitas_screen.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'providers/auth_provider.dart';
import 'providers/paciente_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pacientes_screen.dart';
import 'screens/pacientes_screen.dart';
import 'screens/home_screen.dart'; // NUEVO IMPORT

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthProvider _authProvider = AuthProvider();
  late Connectivity _connectivity;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _setupConnectivityListener();
    _initializeApp();
  }

  // MÉTODO NUEVO: Inicializar la aplicación
Future<void> _initializeApp() async {
  try {
    // Limpiar sesiones anteriores
    await _authProvider.clearOldSessions();
    
    // Intentar auto-login
    await _authProvider.autoLogin();
    
    // Si está autenticado, cargar datos iniciales
    if (_authProvider.isAuthenticated) {
      // Verificar conexión
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;
      
      if (isOnline) {
        // Sincronizar datos
        await _authProvider.syncUserData();
        
        // Cargar y guardar sedes
        try {
          final sedes = await ApiService.getSedes(_authProvider.token!);
          await DatabaseHelper.instance.saveSedes(sedes);
        } catch (e) {
          debugPrint('Error al cargar sedes: $e');
        }
      }
      
      // Cargar pacientes (usará los locales si está offline)
      final pacienteProvider = Provider.of<PacienteProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await pacienteProvider.loadPacientes();
    }
    
    // Debug: Mostrar usuarios en la base de datos
    await _authProvider.debugListUsers();
    
    setState(() {
      _isInitialized = true;
    });
  } catch (e) {
    debugPrint('Error al inicializar app: $e');
    setState(() {
      _isInitialized = true;
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
        title: 'FNPVI App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        navigatorKey: navigatorKey,
        home: _isInitialized 
            ? Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (auth.isAuthenticated) {
                    // Si está autenticado, cargar pacientes y mostrar HomeScreen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Provider.of<PacienteProvider>(context, listen: false).loadPacientes();
                    });
                    return HomeScreen( // CAMBIO: Usar HomeScreen en lugar de PacientesScreen
                      onLogout: () {
                        auth.logout();
                        // No necesitamos navegar porque el Consumer reconstruirá la UI
                      },
                    );
                  } else {
                    // Si no está autenticado, mostrar LoginScreen
                    return LoginScreen(
                      authProvider: _authProvider,
                      onLoginSuccess: () {
                        // El Consumer ya manejará el cambio de estado
                      },
                    );
                  }
                },
              )
            : const Center(child: CircularProgressIndicator()), // Mostrar loading mientras inicializa
        routes: {
          '/profile': (context) => ProfileScreen(
                authProvider: _authProvider,
                onLogout: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
              '/visitas': (context) => VisitasScreen(onLogout: () {  },), // <-- Agrega esta línea
        },
      ),
    );
  }

  @override
  void dispose() {
    _connectivity.onConnectivityChanged.drain();
    super.dispose();
  }
}