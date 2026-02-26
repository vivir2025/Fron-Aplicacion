import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/brigada_model.dart';
import '../services/brigada_service.dart';
import '../providers/auth_provider.dart';
import 'crear_brigada_screen.dart';
import 'crear_brigada_mejorada_screen.dart'; // 🆕 Nueva pantalla mejorada
import 'detalle_brigada_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF1B5E20);

class BrigadasScreen extends StatefulWidget {
  const BrigadasScreen({Key? key}) : super(key: key);

  @override
  State<BrigadasScreen> createState() => _BrigadasScreenState();
}

class _BrigadasScreenState extends State<BrigadasScreen> {
  List<Brigada> _brigadas = [];
  bool _isLoading = false;
  bool _isSyncing = false; // 🆕 Estado del botón de sincronización
  bool _hasError = false;
  String _errorMessage = '';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 BrigadasScreen: initState llamado');
    _cargarBrigadas();
  }

  Future<void> _cargarBrigadas() async {
    debugPrint('📊 _cargarBrigadas: Iniciando carga...');
    
    if (_isLoading) {
      debugPrint('⚠️ _cargarBrigadas: Ya está cargando, saliendo...');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      debugPrint('🔍 _cargarBrigadas: Llamando a _dbHelper.getAllBrigadas()');
      
      // Cargar brigadas locales
      final brigadas = await _dbHelper.getAllBrigadas();
      
      debugPrint('📦 _cargarBrigadas: Brigadas obtenidas: ${brigadas.length}');
      
      // Imprimir detalles de cada brigada
      for (int i = 0; i < brigadas.length; i++) {
        final brigada = brigadas[i];
        debugPrint('   Brigada $i: ID=${brigada.id}, Tema="${brigada.tema}", Lugar="${brigada.lugarEvento}"');
      }
      
      setState(() {
        _brigadas = brigadas;
        _isLoading = false;
      });
      
      debugPrint('✅ _cargarBrigadas: Estado actualizado - ${brigadas.length} brigadas cargadas');
      
      // Auto-sincronizar al cargar si hay brigadas pendientes
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.token != null) {
        final pendientes = brigadas.where((b) => b.syncStatus == 0).length;
        if (pendientes > 0) {
          _sincronizarBrigadas(); // Con feedback visible
        }
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ _cargarBrigadas: Error capturado: $e');
      debugPrint('📍 _cargarBrigadas: StackTrace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar brigadas: $e';
      });
    }
  }

  // 🆕 Método de sincronización con feedback visible al usuario
  Future<void> _sincronizarBrigadas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) return;
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final resultado = await BrigadaService.sincronizarBrigadasPendientes(
        authProvider.token!
      );

      // Recargar brigadas locales tras sincronizar
      final brigadas = await _dbHelper.getAllBrigadas();

      if (mounted) {
        setState(() {
          _brigadas = brigadas;
          _isSyncing = false;
        });

        final exitosas = resultado['exitosas'] ?? 0;
        final fallidas = resultado['fallidas'] ?? 0;
        final errores = resultado['errores'] as List? ?? [];

        String mensaje;
        Color color;

        if (exitosas > 0) {
          mensaje = '✅ $exitosas brigada(s) sincronizada(s) correctamente';
          color = Colors.green.shade700;
        } else if (fallidas > 0) {
          final primerError = errores.isNotEmpty ? errores.first.toString() : 'Error desconocido';
          mensaje = '⚠️ Error al sincronizar: $primerError';
          color = Colors.orange.shade700;
        } else {
          mensaje = 'ℹ️ No hay brigadas pendientes por sincronizar';
          color = Colors.blue.shade700;
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mensaje, style: const TextStyle(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Error de sincronización: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  Future<void> _eliminarBrigada(Brigada brigada) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de que desea eliminar la brigada "${brigada.tema}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        debugPrint('🗑️ _eliminarBrigada: Eliminando brigada ID: ${brigada.id}');
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await BrigadaService.eliminarBrigada(
          brigada.id,
          token: authProvider.token,
        );

        if (success) {
          debugPrint('✅ _eliminarBrigada: Brigada eliminada exitosamente');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Brigada eliminada exitosamente',
                style: GoogleFonts.roboto(color: Colors.white),
              ),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          _cargarBrigadas();
        } else {
          debugPrint('❌ _eliminarBrigada: Error al eliminar la brigada');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la brigada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ _eliminarBrigada: Excepción: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 build: Construyendo UI - isLoading: $_isLoading, hasError: $_hasError, brigadas: ${_brigadas.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.medical_services, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Brigadas',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Mostrar contador en el AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_brigadas.length}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // 🆕 Botón de sincronización con servidor
          IconButton(
            onPressed: _isSyncing ? null : _sincronizarBrigadas,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_sync),
            tooltip: 'Sincronizar con servidor',
          ),
          // Botón de actualización local
          IconButton(
            onPressed: _isLoading ? null : _cargarBrigadas,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  primaryColor,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          debugPrint('➕ FAB: Navegando a CrearBrigadaMejoradaScreen');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearBrigadaMejoradaScreen(), // 🆕 Nueva pantalla
            ),
          );
          
          if (result == true) {
            debugPrint('✅ FAB: Regresó con resultado true, recargando brigadas');
            _cargarBrigadas();
          } else {
            debugPrint('ℹ️ FAB: Regresó con resultado: $result');
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Brigada'),
      ),
    );
  }

  Widget _buildBody() {
    debugPrint('🏗️ _buildBody: isLoading=$_isLoading, hasError=$_hasError, brigadas=${_brigadas.length}');
    
    if (_isLoading && _brigadas.isEmpty) {
      debugPrint('⏳ _buildBody: Mostrando estado de carga');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Cargando brigadas...',
              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      debugPrint('❌ _buildBody: Mostrando estado de error: $_errorMessage');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar brigadas',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(color: Colors.red.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  debugPrint('🔄 Error: Botón reintentar presionado');
                  _cargarBrigadas();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_brigadas.isEmpty) {
      debugPrint('📭 _buildBody: Mostrando estado vacío');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No hay brigadas registradas',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Toque "Nueva Brigada" para crear la primera brigada',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  debugPrint('➕ Empty: Navegando a CrearBrigadaMejoradaScreen');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrearBrigadaMejoradaScreen(),
                    ),
                  );
                  
                  if (result == true) {
                    _cargarBrigadas();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                icon: const Icon(Icons.add),
                label: const Text('a Brigada'),
              ),
            ],
          ),
        ),
      );
    }

    debugPrint('📋 _buildBody: Mostrando lista con ${_brigadas.length} brigadas');
    return RefreshIndicator(
      onRefresh: _cargarBrigadas,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _brigadas.length,
        itemBuilder: (context, index) {
          final brigada = _brigadas[index];
          debugPrint('🏗️ _buildBody: Construyendo card para brigada $index: ${brigada.tema}');
          return _buildBrigadaCard(brigada, index);
        },
      ),
    );
  }

  Widget _buildBrigadaCard(Brigada brigada, int index) {
    final formatter = DateFormat('dd/MM/yyyy');
    final pacientesCount = brigada.pacientesIds?.length ?? 0;
    
    debugPrint('🎴 _buildBrigadaCard: Construyendo card $index para "${brigada.tema}"');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          debugPrint('👆 Card: Tap en brigada ${brigada.id}');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleBrigadaScreen(brigadaId: brigada.id),
            ),
          );
          
          if (result == true) {
            _cargarBrigadas();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brigada.tema,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                brigada.lugarEvento,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: brigada.syncStatus == 1 
                          ? Colors.green.shade100 
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: brigada.syncStatus == 1 
                            ? Colors.green.shade300 
                            : Colors.orange.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          brigada.syncStatus == 1 
                              ? Icons.cloud_done 
                              : Icons.cloud_upload,
                          size: 16,
                          color: brigada.syncStatus == 1 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          brigada.syncStatus == 1 ? 'Sincronizado' : 'Pendiente',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: brigada.syncStatus == 1 
                                ? Colors.green.shade700 
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información principal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fecha: ${formatter.format(brigada.fechaBrigada)}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conductor: ${brigada.nombreConductor}',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pacientes: $pacientesCount asignados',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (brigada.observaciones != null && brigada.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Observaciones:',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        brigada.observaciones!,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        debugPrint('🗑️ Card: Eliminar brigada ${brigada.id}');
                        _eliminarBrigada(brigada);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text(
                        'Eliminar',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        debugPrint('👁️ Card: Ver detalle brigada ${brigada.id}');
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleBrigadaScreen(brigadaId: brigada.id),
                          ),
                        );
                        
                        if (result == true) {
                          _cargarBrigadas();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(
                        'Ver Detalle',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
