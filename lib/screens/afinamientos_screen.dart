// lib/screens/afinamientos_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/afinamiento_model.dart';
import '../services/afinamiento_service.dart';
import '../database/database_helper.dart';
import 'crear_afinamiento_screen.dart';
import 'detalle_afinamiento_screen.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF1B5E20);

class AfinamientosScreen extends StatefulWidget {
  const AfinamientosScreen({Key? key}) : super(key: key);

  @override
  State<AfinamientosScreen> createState() => _AfinamientosScreenState();
}

class _AfinamientosScreenState extends State<AfinamientosScreen> {
  List<Map<String, dynamic>> _afinamientos = [];
  bool _isLoading = true;
  bool _isSyncing = false; // 🆕 Estado de sincronización
  String _searchQuery = '';
  String _filtroSincronizacion = 'todos'; // todos, sincronizados, pendientes

  @override
  void initState() {
    super.initState();
    _cargarAfinamientos();
  }

  Future<void> _cargarAfinamientos() async {
    setState(() => _isLoading = true);
    
    try {
      final afinamientos = await AfinamientoService.obtenerAfinamientosConPaciente();
      setState(() {
        _afinamientos = afinamientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar afinamientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🆕 MÉTODO PARA SINCRONIZAR AFINAMIENTOS PENDIENTES
  Future<void> _sincronizarAfinamientosPendientes() async {
    setState(() => _isSyncing = true);
    
    try {
      // Obtener token del usuario logueado
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      final token = usuario?['token'];
      
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay token de autenticación disponible'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Mostrar diálogo de progreso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Sincronizando afinamientos...'),
                const SizedBox(height: 8),
                Text(
                  'Por favor espere',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // Ejecutar sincronización
      final resultado = await AfinamientoService.sincronizarAfinamientosPendientes(token);
      
      // Cerrar diálogo de progreso
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      final exitosas = resultado['exitosas'] ?? 0;
      final fallidas = resultado['fallidas'] ?? 0;
      final total = resultado['total'] ?? 0;
      final errores = resultado['errores'] as List<String>? ?? [];
      
      // Recargar afinamientos después de la sincronización
      await _cargarAfinamientos();
      
      if (mounted) {
        if (exitosas > 0) {
          // Mostrar resultado exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ $exitosas de $total afinamientos sincronizados exitosamente',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (total == 0) {
          // No hay afinamientos pendientes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ℹ️ No hay afinamientos pendientes de sincronización'),
              backgroundColor: primaryColor.withOpacity(0.05),
            ),
          );
        } else {
          // Mostrar errores si los hay
          String mensaje = '⚠️ ';
          if (fallidas > 0) {
            mensaje += '$fallidas afinamientos fallaron en la sincronización';
            if (errores.isNotEmpty) {
              mensaje += '\nPrimer error: ${errores.first}';
            }
          } else {
            mensaje += 'No se pudieron sincronizar los afinamientos';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      
    } catch (e) {
      // Cerrar diálogo de progreso si está abierto
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error durante la sincronización: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  List<Map<String, dynamic>> get _afinamientosFiltrados {
    return _afinamientos.where((afinamiento) {
      // Filtro por búsqueda
      final nombrePaciente = afinamiento['nombre_paciente']?.toString().toLowerCase() ?? '';
      final identificacion = afinamiento['identificacion_paciente']?.toString().toLowerCase() ?? '';
      final procedencia = afinamiento['procedencia']?.toString().toLowerCase() ?? '';
      
      final matchesSearch = _searchQuery.isEmpty ||
          nombrePaciente.contains(_searchQuery.toLowerCase()) ||
          identificacion.contains(_searchQuery.toLowerCase()) ||
          procedencia.contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      
      // Filtro por sincronización
      final syncStatus = afinamiento['sync_status'] as int? ?? 0;
      switch (_filtroSincronizacion) {
        case 'sincronizados':
          return syncStatus == 1;
        case 'pendientes':
          return syncStatus == 0;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Calcular afinamientos pendientes para el botón
    final afinamientosPendientes = _afinamientos.where((a) => (a['sync_status'] as int? ?? 0) == 0).length;
    
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Afinamientos',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 🆕 BOTÓN DE SINCRONIZACIÓN REEMPLAZANDO EL DE REFRESCAR
          Stack(
            children: [
              IconButton(
                icon: _isSyncing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.cloud_sync),
                onPressed: _isSyncing ? null : _sincronizarAfinamientosPendientes,
                tooltip: 'Sincronizar afinamientos pendientes',
              ),
              // 🆕 Badge con número de pendientes
              if (afinamientosPendientes > 0 && !_isSyncing)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$afinamientosPendientes',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // 🆕 Botón de actualizar manual (opcional)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _cargarAfinamientos,
            tooltip: 'Actualizar lista',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filtroSincronizacion = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'sincronizados',
                child: Text('Sincronizados'),
              ),
              const PopupMenuItem(
                value: 'pendientes',
                child: Text('Pendientes'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: Column(
        children: [
          // 🆕 BANNER DE INFORMACIÓN DE SINCRONIZACIÓN
          if (afinamientosPendientes > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$afinamientosPendientes afinamiento${afinamientosPendientes > 1 ? 's' : ''} pendiente${afinamientosPendientes > 1 ? 's' : ''} de sincronización',
                      style: GoogleFonts.roboto(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSyncing ? null : _sincronizarAfinamientosPendientes,
                    child: Text(
                      'Sincronizar',
                      style: GoogleFonts.roboto(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Estadísticas
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadistica(
                  'Total',
                  _afinamientos.length.toString(),
                  primaryColor,
                ),
                _buildEstadistica(
                  'Sincronizados',
                  _afinamientos.where((a) => (a['sync_status'] as int? ?? 0) == 1).length.toString(),
                  Colors.green,
                ),
                _buildEstadistica(
                  'Pendientes',
                  afinamientosPendientes.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de afinamientos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _afinamientosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _cargarAfinamientos,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _afinamientosFiltrados.length,
                          itemBuilder: (context, index) {
                            final afinamiento = _afinamientosFiltrados[index];
                            return _buildAfinamientoCard(afinamiento);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearAfinamientoScreen(),
            ),
          );
          
          if (result == true) {
            _cargarAfinamientos();
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Nuevo Afinamiento',
      ),
    );
  }

  Widget _buildEstadistica(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filtroSincronizacion != 'todos'
                ? 'No se encontraron afinamientos\ncon los filtros aplicados'
                : 'No hay afinamientos registrados',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isNotEmpty || _filtroSincronizacion != 'todos')
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filtroSincronizacion = 'todos';
                });
              },
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  Widget _buildAfinamientoCard(Map<String, dynamic> afinamiento) {
    final syncStatus = afinamiento['sync_status'] as int? ?? 0;
    final fechaTamizaje = DateTime.parse(afinamiento['fecha_tamizaje'].toString());
    final nombrePaciente = afinamiento['nombre_paciente']?.toString() ?? 'Sin nombre';
    final identificacion = afinamiento['identificacion_paciente']?.toString() ?? 'Sin ID';
    final procedencia = afinamiento['procedencia']?.toString() ?? 'Sin procedencia';
    final promotorVida = afinamiento['promotor_vida']?.toString() ?? 'Sin promotor';
    
    // Calcular promedios si existen
    final sistolicaPromedio = afinamiento['presion_sistolica_promedio'];
    final diastolicaPromedio = afinamiento['presion_diastolica_promedio'];
    
    String promedioTexto = 'Sin promedios';
    if (sistolicaPromedio != null && diastolicaPromedio != null) {
      promedioTexto = '${double.parse(sistolicaPromedio.toString()).toStringAsFixed(1)}/${double.parse(diastolicaPromedio.toString()).toStringAsFixed(1)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: syncStatus == 1 ? primaryColor.withOpacity(0.2) : Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleAfinamientoScreen(
                afinamientoId: afinamiento['id'].toString(),
              ),
            ),
          );
          
          if (result == true) {
            _cargarAfinamientos();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado de sincronización
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nombrePaciente,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: syncStatus == 1 ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          syncStatus == 1 ? Icons.cloud_done : Icons.cloud_upload,
                          size: 16,
                          color: syncStatus == 1 ? Colors.green[700] : Colors.orange[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          syncStatus == 1 ? 'Sincronizado' : 'Pendiente',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: syncStatus == 1 ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Información del paciente
              Row(
                children: [
                  Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'ID: $identificacion',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 4),

              // Procedencia
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      procedencia,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Información del afinamiento
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha Tamizaje',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(fechaTamizaje),
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Promedio PA',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              promedioTexto,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sistolicaPromedio != null ? primaryColor : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Promotor: $promotorVida',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Presión arterial del tamizaje
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                  SizedBox(width: 4),
                  Text(
                    'PA Tamizaje: ${afinamiento['presion_arterial_tamiz']}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
