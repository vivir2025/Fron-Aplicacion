import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Color(0xFF388E3C)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
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

    debugPrint('🔄 Iniciando sincronización completa...');
    final resultado = await SincronizacionService.sincronizacionCompleta(token)
        .timeout(const Duration(seconds: 120)); // Más tiempo para medicamentos

    if (mounted) {
      final visitasSync = resultado['visitas']['exitosas'] ?? 0;
      final pacientesSync = resultado['pacientes']['exitosas'] ?? 0;
      final medicamentosSync = resultado['medicamentos']['exitosas'] ?? 0; // 🆕
      final archivosSync = resultado['archivos']['exitosas'] ?? 0;
      
      String mensaje = '';
      if (medicamentosSync > 0) {
        mensaje += 'Medicamentos: $medicamentosSync OK | ';
      }
      if (visitasSync > 0) {
        mensaje += 'Visitas: $visitasSync OK | ';
      }
      if (pacientesSync > 0) {
        mensaje += 'Pacientes: $pacientesSync OK | ';
      }
      if (archivosSync > 0) {
        mensaje += 'Archivos: $archivosSync OK';
      }
      
      if (mensaje.isEmpty) {
        mensaje = 'Todo está sincronizado';
      } else {
        mensaje = mensaje.replaceAll(RegExp(r' \| $'), ''); // Limpiar último separador
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
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
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.list), text: 'Listado'),
                Tab(icon: Icon(Icons.add), text: 'Nueva Visita'),
              ],
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