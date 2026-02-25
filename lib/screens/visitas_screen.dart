import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/sincronizacion_service.dart';
import '../api/api_service.dart';
import 'visitas_list_screen.dart';
import 'visitas_form_screen.dart';

class VisitasScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const VisitasScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen> {
  bool _isLoading = false;

  ThemeData get customTheme => ThemeData(
    primarySwatch: Colors.green,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    textTheme: GoogleFonts.robotoTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF1B5E20)),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        elevation: MaterialStateProperty.all(0),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 15)
        ),
        minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.15), width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
  );

  // screens/visitas_screen.dart - MÉTODO CORREGIDO PARA SINCRONIZAR SOLO VISITAS
Future<void> _sincronizarManualmente() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final token = authProvider.token;
  
  if (token == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autenticación requerida')),
      );
    }
    return;
  }

  setState(() => _isLoading = true);
  
  try {
    debugPrint('🔄 Verificando disponibilidad del servidor...');
    final serverAvailable = await ApiService.verificarSaludServidor();
    
    if (!serverAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar con el servidor'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 🆕 SOLO SINCRONIZAR VISITAS (no todo)
    debugPrint('🔄 Sincronizando solo visitas pendientes...');
    final resultado = await SincronizacionService.sincronizarVisitasPendientes(token)
        .timeout(const Duration(seconds: 60));

    if (mounted) {
      final visitasSync = resultado['exitosas'] ?? 0;
      final visitasFallidas = resultado['fallidas'] ?? 0;
      final totalVisitas = resultado['total'] ?? 0;
      
      String mensaje = '';
      Color backgroundColor = Colors.green;
      
      if (visitasSync > 0) {
        mensaje = '✅ $visitasSync de $totalVisitas visitas sincronizadas';
        backgroundColor = Colors.green;
      } else if (totalVisitas == 0) {
        mensaje = 'ℹ️ No hay visitas pendientes por sincronizar';
        backgroundColor = Colors.blue;
      } else {
        mensaje = '⚠️ No se pudieron sincronizar las $totalVisitas visitas';
        backgroundColor = Colors.orange;
      }
      
      if (visitasFallidas > 0) {
        mensaje += '\n❌ $visitasFallidas visitas fallaron';
        backgroundColor = Colors.orange;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: const Duration(seconds: 5),
          backgroundColor: backgroundColor,
          action: visitasFallidas > 0 ? SnackBarAction(
            label: 'Ver errores',
            textColor: Colors.white,
            onPressed: () {
              final errores = resultado['errores'] as List<String>? ?? [];
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Errores de sincronización'),
                  content: SingleChildScrollView(
                    child: Text(errores.join('\n\n')),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ) : null,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    debugPrint('Error completo: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: customTheme,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Visitas Domiciliarias'),
            actions: [
              IconButton(
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sync),
                tooltip: 'Sincronizar manualmente',
                onPressed: _isLoading ? null : _sincronizarManualmente,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF1B5E20),
                  unselectedLabelColor: Colors.white,
                  labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, size: 20), 
                          SizedBox(width: 8), 
                          Text('Listado')
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: 20), 
                          SizedBox(width: 8), 
                          Text('Nueva Visita')
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              VisitasListScreen(theme: customTheme),
              VisitasFormScreen(theme: customTheme),
            ],
          ),
        ),
      ),
    );
  }
}