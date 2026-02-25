// screens/tamizajes_lista_screen.dart
import 'package:flutter/material.dart';
import '../models/tamizaje_model.dart';
import '../services/tamizaje_service.dart';
import '../services/sincronizacion_service.dart';
import '../database/database_helper.dart';
import 'tamizaje_screen.dart'; // ← LÍNEA AGREGADA PARA IMPORTAR LA PANTALLA
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF1B5E20);

class TamizajesListaScreen extends StatefulWidget {
  const TamizajesListaScreen({Key? key}) : super(key: key);

  @override
  State<TamizajesListaScreen> createState() => _TamizajesListaScreenState();
}

class _TamizajesListaScreenState extends State<TamizajesListaScreen> {
  List<Tamizaje> _tamizajes = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _filtroClasificacion = 'Todos';
  String _filtroSincronizacion = 'Todos';

  final List<String> _clasificaciones = [
    'Todos',
    'Normal',
    'Elevada',
    'Hipertensión Etapa 1',
    'Hipertensión Etapa 2',
    'Crisis Hipertensiva'
  ];

  final List<String> _estadosSincronizacion = [
    'Todos',
    'Sincronizados',
    'Pendientes'
  ];

  @override
  void initState() {
    super.initState();
    _cargarTamizajes();
  }

  Future<void> _cargarTamizajes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tamizajes = await TamizajeService.obtenerTamizajesConPaciente();
      setState(() {
        _tamizajes = tamizajes;
      });
    } catch (e) {
      _mostrarError('Error al cargar tamizajes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Tamizaje> get _tamizajesFiltrados {
    return _tamizajes.where((tamizaje) {
      // Filtro por clasificación
      if (_filtroClasificacion != 'Todos' && 
          tamizaje.clasificacionPresion != _filtroClasificacion) {
        return false;
      }

      // Filtro por sincronización
      if (_filtroSincronizacion == 'Sincronizados' && !tamizaje.isSincronizado) {
        return false;
      }
      if (_filtroSincronizacion == 'Pendientes' && tamizaje.isSincronizado) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tamizajesFiltrados = _tamizajesFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Tamizajes Realizados',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _sincronizar,
            tooltip: 'Sincronizar',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _mostrarEstadisticas,
            tooltip: 'Estadísticas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroClasificacion,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Clasificación',
                          labelStyle: GoogleFonts.roboto(color: Colors.grey[700]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
                        items: _clasificaciones.map((clasificacion) {
                          return DropdownMenuItem(
                            value: clasificacion,
                            child: Text(
                              clasificacion,
                              style: GoogleFonts.roboto(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _filtroClasificacion = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroSincronizacion,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          labelStyle: GoogleFonts.roboto(color: Colors.grey[700]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
                        items: _estadosSincronizacion.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(
                              estado,
                              style: GoogleFonts.roboto(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _filtroSincronizacion = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Mostrando ${tamizajesFiltrados.length} de ${_tamizajes.length} tamizajes',
                      style: GoogleFonts.roboto(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de tamizajes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : tamizajesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _tamizajes.isEmpty
                                  ? 'No hay tamizajes registrados'
                                  : 'No hay tamizajes que coincidan con los filtros',
                              style: GoogleFonts.roboto(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _irANuevoTamizaje,
                              icon: const Icon(Icons.add),
                              label: Text('Crear Primer Tamizaje', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarTamizajes,
                        child: ListView.builder(
                          itemCount: tamizajesFiltrados.length,
                          itemBuilder: (context, index) {
                            final tamizaje = tamizajesFiltrados[index];
                            return _buildTamizajeCard(tamizaje);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Botón flotante para agregar nuevo tamizaje
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irANuevoTamizaje,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Nuevo Tamizaje',
        icon: const Icon(Icons.add),
        label: Text('Nuevo Tamizaje', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ← FUNCIÓN CORREGIDA PARA NAVEGAR A LA PANTALLA DE NUEVO TAMIZAJE
  void _irANuevoTamizaje() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TamizajeScreen(),
      ),
    );
    
    // Si se creó un tamizaje exitosamente, recargar la lista
    if (resultado == true) {
      _cargarTamizajes();
    }
  }

  Widget _buildTamizajeCard(Tamizaje tamizaje) {
    final colorClasificacion = _getColorClasificacion(tamizaje.clasificacionPresion);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorClasificacion.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 0),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _mostrarDetallesTamizaje(tamizaje),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Patient name and status)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tamizaje.nombrePaciente ?? 'Paciente desconocido',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ID: ${tamizaje.identificacionPaciente ?? 'N/A'}',
                                    style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatearFecha(tamizaje.fechaPrimeraToma),
                                    style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Sync Status
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: tamizaje.isSincronizado ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tamizaje.isSincronizado ? Icons.cloud_done : Icons.cloud_upload,
                        size: 20,
                        color: tamizaje.isSincronizado ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // BP and Classification
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Presión Arterial',
                              style: GoogleFonts.roboto(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tamizaje.presionArterial} mmHg',
                              style: GoogleFonts.roboto(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorClasificacion.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorClasificacion.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clasificación',
                              style: GoogleFonts.roboto(
                                color: colorClasificacion,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tamizaje.clasificacionPresion,
                              style: GoogleFonts.roboto(
                                color: colorClasificacion,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Location and Promotor
                if (tamizaje.veredaResidencia.isNotEmpty || tamizaje.promotorVida != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (tamizaje.veredaResidencia.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tamizaje.veredaResidencia,
                                  style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        if (tamizaje.veredaResidencia.isNotEmpty && tamizaje.promotorVida != null)
                          const SizedBox(height: 4),
                        if (tamizaje.promotorVida != null)
                          Row(
                            children: [
                              Icon(Icons.health_and_safety, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Promotor: ${tamizaje.promotorVida}',
                                  style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesTamizaje(Tamizaje tamizaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tamizaje - ${tamizaje.nombrePaciente}', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Identificación:', tamizaje.identificacionPaciente ?? 'N/A'),
              _buildDetalleRow('Edad:', '${tamizaje.edadPaciente ?? 'N/A'} años'),
              _buildDetalleRow('Sexo:', tamizaje.sexoPaciente ?? 'N/A'),
              _buildDetalleRow('Sede:', tamizaje.sedePaciente ?? 'N/A'),
              const Divider(),
              _buildDetalleRow('Fecha de Toma:', _formatearFecha(tamizaje.fechaPrimeraToma)),
              _buildDetalleRow('Vereda:', tamizaje.veredaResidencia),
              if (tamizaje.telefono != null)
                _buildDetalleRow('Teléfono:', tamizaje.telefono!),
              _buildDetalleRow('Brazo:', tamizaje.brazoToma.replaceAll('_', ' ')),
              _buildDetalleRow('Posición:', tamizaje.posicionPersona.replaceAll('_', ' ')),
              _buildDetalleRow('Reposo 5 min:', tamizaje.reposoCincoMinutos),
              const Divider(),
              _buildDetalleRow('Presión Arterial:', '${tamizaje.presionArterial} mmHg'),
              _buildDetalleRow('Clasificación:', tamizaje.clasificacionPresion),
              if (tamizaje.conducta != null && tamizaje.conducta!.isNotEmpty) ...[
                const Divider(),
                _buildDetalleRow('Conducta:', tamizaje.conducta!),
              ],
              const Divider(),
              _buildDetalleRow('Estado:', tamizaje.isSincronizado ? 'Sincronizado' : 'Pendiente'),
              _buildDetalleRow('Promotor:', tamizaje.promotorVida ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: GoogleFonts.roboto()),
          ),
          if (!tamizaje.isSincronizado)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sincronizarTamizajeEspecifico(tamizaje);
              },
              child: Text('Sincronizar', style: GoogleFonts.roboto()),
            ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getColorClasificacion(String clasificacion) {
    switch (clasificacion) {
      case 'Normal':
        return Colors.green;
      case 'Elevada':
        return Colors.orange;
      case 'Hipertensión Etapa 1':
        return Colors.red[300]!;
      case 'Hipertensión Etapa 2':
        return Colors.red;
      default:
        return Colors.red[900]!;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _sincronizar() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      if (usuario == null || usuario['token'] == null) {
        _mostrarError('No hay usuario autenticado');
        return;
      }

      final resultado = await SincronizacionService.sincronizarTamizajesPendientes(
        usuario['token']
      );

      final exitosas = resultado['exitosas'] ?? 0;
      final fallidas = resultado['fallidas'] ?? 0;

      if (exitosas > 0) {
        _mostrarExito('$exitosas tamizajes sincronizados exitosamente');
        await _cargarTamizajes(); // Recargar la lista
      } else if (fallidas > 0) {
        _mostrarError('Error al sincronizar algunos tamizajes');
      } else {
        _mostrarExito('No hay tamizajes pendientes de sincronización');
      }
    } catch (e) {
      _mostrarError('Error en la sincronización: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _sincronizarTamizajeEspecifico(Tamizaje tamizaje) async {
    // Esta función podría implementarse para sincronizar un tamizaje específico
    // Por ahora, sincronizamos todos los pendientes
    await _sincronizar();
  }

  Future<void> _mostrarEstadisticas() async {
    try {
      final estadisticas = await TamizajeService.obtenerEstadisticas();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Estadísticas de Tamizajes'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total de tamizajes: ${estadisticas['total'] ?? 0}'),
                Text('Sincronizados: ${estadisticas['sincronizados'] ?? 0}'),
                Text('Pendientes: ${estadisticas['pendientes'] ?? 0}'),
                const Divider(),
                const Text(
                  'Clasificación de Presión Arterial:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (estadisticas['clasificacion_presion'] != null) ...[
                  Text('Normal: ${estadisticas['clasificacion_presion']['normal'] ?? 0}'),
                  Text('Elevada: ${estadisticas['clasificacion_presion']['elevada'] ?? 0}'),
                  Text('Hipertensión Etapa 1: ${estadisticas['clasificacion_presion']['hipertension_etapa_1'] ?? 0}'),
                  Text('Hipertensión Etapa 2: ${estadisticas['clasificacion_presion']['hipertension_etapa_2'] ?? 0}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _mostrarError('Error al obtener estadísticas: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }
}
