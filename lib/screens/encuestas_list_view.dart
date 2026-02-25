// views/encuestas_list_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Bornive/models/encuesta_model.dart';
import 'package:Bornive/models/paciente_model.dart';
import 'package:Bornive/screens/encuesta_detail_view.dart';
import 'package:Bornive/screens/encuesta_view.dart';
import 'package:Bornive/services/encuesta_service.dart';
import 'package:Bornive/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncuestasListView extends StatefulWidget {
  const EncuestasListView({Key? key}) : super(key: key);

  @override
  _EncuestasListViewState createState() => _EncuestasListViewState();
}

class _EncuestasListViewState extends State<EncuestasListView> with TickerProviderStateMixin {
  List<Encuesta> _encuestas = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _searchQuery = '';
  late AnimationController _syncAnimationController;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadEncuestas();
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadEncuestas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final encuestas = await EncuestaService.obtenerTodasLasEncuestas();
      setState(() {
        _encuestas = encuestas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _obtenerTokenValido() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token != null && token.isNotEmpty) {
        return token;
      }
      
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getLoggedInUser();
      token = user?['token'];
      
      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        return token;
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }

  Future<void> _sincronizarEncuestasPendientes() async {
    if (_isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });
    _syncAnimationController.repeat();

    try {
      final token = await _obtenerTokenValido();
      
      if (token == null) {
        _mostrarMensajeError(
          'No hay token de autenticación disponible',
          'Por favor, inicia sesión nuevamente',
          Colors.orange,
          Icons.warning_rounded,
        );
        return;
      }

      _mostrarMensajeCarga('Sincronizando encuestas pendientes...');

      final estadisticasAntes = await EncuestaService.obtenerEstadisticasEncuestas();
      final pendientesAntes = estadisticasAntes['pendientes'] ?? 0;

      if (pendientesAntes == 0) {
        _mostrarMensajeInfo(
          'No hay encuestas pendientes por sincronizar',
          'Todas las encuestas están actualizadas',
          Colors.blue,
          Icons.info_rounded,
        );
        return;
      }

      final resultado = await EncuestaService.sincronizarEncuestasPendientes(token);
      
      final exitosas = resultado['exitosas'] ?? 0;
      final fallidas = resultado['fallidas'] ?? 0;
      final errores = resultado['errores'] as List<String>? ?? [];
      final total = resultado['total'] ?? 0;

      await _loadEncuestas();

      if (exitosas > 0) {
        _mostrarMensajeExito(
          '$exitosas encuestas sincronizadas exitosamente',
          fallidas > 0 
            ? '$fallidas encuestas fallaron en la sincronización' 
            : 'Todas las encuestas pendientes fueron sincronizadas',
          Colors.green,
          Icons.cloud_done_rounded,
        );
      } else if (fallidas > 0) {
        _mostrarMensajeError(
          'Error en sincronización de encuestas',
          'No se pudo sincronizar ninguna encuesta. ${errores.isNotEmpty ? errores.first : "Error desconocido"}',
          Colors.red,
          Icons.error_rounded,
        );
      } else {
        _mostrarMensajeInfo(
          'Sin encuestas para sincronizar',
          'No se encontraron encuestas pendientes',
          Colors.blue,
          Icons.info_rounded,
        );
      }

    } catch (e) {
      _mostrarMensajeError(
        'Error inesperado en sincronización',
        'Error: ${e.toString()}',
        Colors.red,
        Icons.error_rounded,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
      _syncAnimationController.stop();
      _syncAnimationController.reset();
    }
  }

  void _mostrarMensajeCarga(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarMensajeExito(String titulo, String subtitulo, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitulo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarMensajeError(String titulo, String subtitulo, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitulo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          backgroundColor: Colors.white24,
          onPressed: _sincronizarEncuestasPendientes,
        ),
      ),
    );
  }

  void _mostrarMensajeInfo(String titulo, String subtitulo, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitulo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Encuesta> get _filteredEncuestas {
    if (_searchQuery.isEmpty) {
      return _encuestas;
    }
    
    return _encuestas.where((encuesta) {
      return encuesta.domicilio.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             encuesta.entidadAfiliada.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             encuesta.id.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Encuestas de Satisfacción',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600, 
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: _isSyncing 
                ? RotationTransition(
                    turns: _syncAnimationController,
                    child: const Icon(Icons.sync_rounded, size: 24),
                  )
                : const Icon(Icons.sync_rounded, size: 24),
              onPressed: _isSyncing ? null : _sincronizarEncuestasPendientes,
              tooltip: _isSyncing 
                ? 'Sincronizando...' 
                : 'Sincronizar encuestas pendientes',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 24),
              onPressed: _isLoading ? null : _loadEncuestas,
              tooltip: 'Recargar lista',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatusIndicator(),
          
          // Barra de búsqueda mejorada
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Buscar encuestas',
                  labelStyle: GoogleFonts.roboto(),
                  hintText: 'ID, domicilio o entidad...',
                  hintStyle: GoogleFonts.roboto(),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.roboto(),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 16),
                        Text(
                          'Cargando encuestas...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _filteredEncuestas.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredEncuestas.length,
                        itemBuilder: (context, index) {
                          final encuesta = _filteredEncuestas[index];
                          return _buildEncuestaCard(encuesta);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPacienteSelector,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Nueva Encuesta', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    final encuestasPendientes = _encuestas.where((e) => e.syncStatus == 0).length;
    final encuestasSincronizadas = _encuestas.where((e) => e.syncStatus == 1).length;
    
    if (_encuestas.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool hasPendientes = encuestasPendientes > 0;
    final Color statusColor = hasPendientes ? Colors.orange[700]! : Colors.green[700]!;
    final IconData statusIcon = hasPendientes ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPendientes 
                    ? 'Sincronización pendiente'
                    : 'Todo sincronizado',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPendientes 
                    ? '$encuestasPendientes encuestas pendientes de sincronización'
                    : 'Todas las encuestas están sincronizadas ($encuestasSincronizadas)',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (hasPendientes) ...[
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: _isSyncing ? null : _sincronizarEncuestasPendientes,
                icon: _isSyncing 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColor,
                      ),
                    )
                  : Icon(Icons.sync_rounded, size: 18, color: statusColor),
                label: Text(
                  _isSyncing ? 'Sincronizando...' : 'Sincronizar',
                  style: GoogleFonts.roboto(color: statusColor),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20).withOpacity(0.1),
                    const Color(0xFF1B5E20).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.poll_outlined,
                size: 60,
                color: const Color(0xFF1B5E20).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty 
                ? 'No hay encuestas registradas'
                : 'No se encontraron encuestas',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                ? 'Toca el botón + para crear tu primera encuesta'
                : 'Intenta con otro término de búsqueda',
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_searchQuery.isEmpty) ...[
              ElevatedButton.icon(
                onPressed: _showPacienteSelector,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear Encuesta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Limpiar búsqueda'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncuestaCard(Encuesta encuesta) {
    final bool isSynced = encuesta.syncStatus == 1;
    final Color statusColor = isSynced ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewEncuestaDetail(encuesta),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Encuesta ${encuesta.id.substring(0, 8)}...',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isSynced ? 'Sincronizada' : 'Pendiente',
                                  style: GoogleFonts.roboto(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isSynced)
                          Icon(Icons.sync_problem_rounded, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 16),
                
                // Información detallada
                FutureBuilder<Paciente?>(
                  future: DatabaseHelper.instance.getPacienteById(encuesta.idpaciente),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        children: [
                          _buildInfoRow('Paciente', 'Cargando...', Icons.person_outlined),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                    
                    final paciente = snapshot.data;
                    if (paciente == null) {
                      return Column(
                        children: [
                          _buildInfoRow('Paciente', 'ID: ${encuesta.idpaciente}', Icons.person_outlined),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                    
                    return Column(
                      children: [
                        _buildInfoRow('Nombre', paciente.nombreCompleto, Icons.person_outlined),
                        const SizedBox(height: 12),
                        _buildInfoRow('Identificación', paciente.identificacion, Icons.badge_outlined),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
                _buildInfoRow('Domicilio', encuesta.domicilio, Icons.home_outlined),
                const SizedBox(height: 12),
                _buildInfoRow('Fecha', '${encuesta.fecha.day}/${encuesta.fecha.month}/${encuesta.fecha.year}', Icons.calendar_today_outlined),
                const SizedBox(height: 12),
                _buildInfoRow('Entidad', encuesta.entidadAfiliada, Icons.business_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1B5E20), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _viewEncuestaDetail(Encuesta encuesta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EncuestaDetailView(encuesta: encuesta),
      ),
    ).then((_) => _loadEncuestas());
  }

  void _showPacienteSelector() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final pacientes = await dbHelper.readAllPacientes();
      
      if (pacientes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No hay pacientes registrados. Sincroniza primero los datos.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _PacienteSelectorDialog(pacientes: pacientes);
        },
      ).then((pacienteSeleccionado) {
        if (pacienteSeleccionado != null) {
          _navegarANuevaEncuesta(pacienteSeleccionado);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al cargar pacientes: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navegarANuevaEncuesta(Paciente paciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EncuestaView(paciente: paciente),
      ),
    ).then((result) {
      if (result == true) {
        _loadEncuestas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Encuesta creada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });
  }
}

// Widget mejorado para el diálogo de selección de pacientes
class _PacienteSelectorDialog extends StatefulWidget {
  final List<Paciente> pacientes;

  const _PacienteSelectorDialog({
    required this.pacientes,
  });

  @override
  _PacienteSelectorDialogState createState() => _PacienteSelectorDialogState();
}

class _PacienteSelectorDialogState extends State<_PacienteSelectorDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Paciente> get _filteredPacientes {
    if (_searchQuery.isEmpty) {
      return widget.pacientes;
    }
    
    return widget.pacientes.where((paciente) {
      final searchLower = _searchQuery.toLowerCase();
      return paciente.nombre.toLowerCase().contains(searchLower) ||
             paciente.apellido.toLowerCase().contains(searchLower) ||
             paciente.nombreCompleto.toLowerCase().contains(searchLower) ||
             paciente.identificacion.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header mejorado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccionar Paciente',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.pacientes.length} pacientes disponibles',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Barra de búsqueda mejorada
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar paciente',
                  hintText: 'Nombre, apellido o identificación...',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Contador de resultados
            if (_searchQuery.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: Colors.green[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredPacientes.length} resultado(s) encontrado(s)',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Lista de pacientes
            Expanded(
              child: _filteredPacientes.isEmpty
                  ? _buildEmptySearchResults()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredPacientes.length,
                      itemBuilder: (context, index) {
                        final paciente = _filteredPacientes[index];
                        return _buildPacienteCard(paciente);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context, paciente);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B5E20).withOpacity(0.15),
                        const Color(0xFF1B5E20).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      paciente.nombre[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paciente.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${paciente.identificacion}',
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Coincidencia encontrada',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[300]!.withOpacity(0.3),
                    Colors.grey[200]!.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No se encontraron pacientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta con otro término de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpiar búsqueda'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                side: const BorderSide(color: Color(0xFF1B5E20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

