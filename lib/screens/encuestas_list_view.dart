// views/encuestas_list_view.dart
import 'package:flutter/material.dart';
import 'package:fnpv_app/models/encuesta_model.dart';
import 'package:fnpv_app/models/paciente_model.dart';
import 'package:fnpv_app/screens/encuesta_detail_view.dart';
import 'package:fnpv_app/screens/encuesta_view.dart';
import 'package:fnpv_app/services/encuesta_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncuestasListView extends StatefulWidget {
  const EncuestasListView({Key? key}) : super(key: key);

  @override
  _EncuestasListViewState createState() => _EncuestasListViewState();
}

class _EncuestasListViewState extends State<EncuestasListView> {
  List<Encuesta> _encuestas = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEncuestas();
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
      debugPrint('Error al cargar encuestas: $e');
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
        debugPrint('✅ Token obtenido desde SharedPreferences');
        return token;
      }
      
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getLoggedInUser();
      token = user?['token'];
      
      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        debugPrint('✅ Token recuperado desde usuario logueado y guardado en prefs');
        return token;
      }
      
      debugPrint('❌ No se pudo obtener token válido de ninguna fuente');
      return null;
      
    } catch (e) {
      debugPrint('❌ Error obteniendo token: $e');
      return null;
    }
  }

  Future<void> _sincronizarEncuestasPendientes() async {
    if (_isSyncing) {
      debugPrint('⚠️ Ya hay una sincronización en progreso');
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final token = await _obtenerTokenValido();
      
      if (token == null) {
        _mostrarMensajeError(
          'No hay token de autenticación disponible',
          'Por favor, inicia sesión nuevamente',
          Colors.orange,
          Icons.warning,
        );
        return;
      }

      _mostrarMensajeCarga('Sincronizando encuestas pendientes...');

      final estadisticasAntes = await EncuestaService.obtenerEstadisticasEncuestas();
      final pendientesAntes = estadisticasAntes['pendientes'] ?? 0;

      debugPrint('📊 Encuestas pendientes antes de sincronizar: $pendientesAntes');

      if (pendientesAntes == 0) {
        _mostrarMensajeInfo(
          'No hay encuestas pendientes por sincronizar',
          'Todas las encuestas están actualizadas',
          Colors.blue,
          Icons.info,
        );
        return;
      }

      final resultado = await EncuestaService.sincronizarEncuestasPendientes(token);
      
      final exitosas = resultado['exitosas'] ?? 0;
      final fallidas = resultado['fallidas'] ?? 0;
      final errores = resultado['errores'] as List<String>? ?? [];
      final total = resultado['total'] ?? 0;

      debugPrint('📊 Resultado sincronización: $exitosas exitosas, $fallidas fallidas de $total total');

      await _loadEncuestas();

      if (exitosas > 0) {
        _mostrarMensajeExito(
          '$exitosas encuestas sincronizadas exitosamente',
          fallidas > 0 
            ? '$fallidas encuestas fallaron en la sincronización' 
            : 'Todas las encuestas pendientes fueron sincronizadas',
          Colors.green,
          Icons.cloud_done,
        );
      } else if (fallidas > 0) {
        _mostrarMensajeError(
          'Error en sincronización de encuestas',
          'No se pudo sincronizar ninguna encuesta. ${errores.isNotEmpty ? errores.first : "Error desconocido"}',
          Colors.red,
          Icons.error,
        );
      } else {
        _mostrarMensajeInfo(
          'Sin encuestas para sincronizar',
          'No se encontraron encuestas pendientes',
          Colors.blue,
          Icons.info,
        );
      }

    } catch (e) {
      debugPrint('❌ Error durante sincronización: $e');
      _mostrarMensajeError(
        'Error inesperado en sincronización',
        'Error: ${e.toString()}',
        Colors.red,
        Icons.error,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _mostrarMensajeCarga(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(mensaje),
          ],
        ),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarMensajeExito(String titulo, String subtitulo, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (subtitulo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarMensajeError(String titulo, String subtitulo, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (subtitulo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _sincronizarEncuestasPendientes,
        ),
      ),
    );
  }

  void _mostrarMensajeInfo(String titulo, String subtitulo, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (subtitulo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      appBar: AppBar(
        title: const Text('Encuestas de Satisfacción'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSyncing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _sincronizarEncuestasPendientes,
            tooltip: _isSyncing 
              ? 'Sincronizando...' 
              : 'Sincronizar encuestas pendientes',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEncuestas,
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatusIndicator(),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar encuestas',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEncuestas.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Encuesta'),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    final encuestasPendientes = _encuestas.where((e) => e.syncStatus == 0).length;
    final encuestasSincronizadas = _encuestas.where((e) => e.syncStatus == 1).length;
    
    if (_encuestas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: encuestasPendientes > 0 ? Colors.orange[50] : Colors.green[50],
        border: Border(
          bottom: BorderSide(
            color: encuestasPendientes > 0 ? Colors.orange[200]! : Colors.green[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            encuestasPendientes > 0 ? Icons.cloud_queue : Icons.cloud_done,
            color: encuestasPendientes > 0 ? Colors.orange[700] : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              encuestasPendientes > 0 
                ? '$encuestasPendientes encuestas pendientes de sincronización'
                : 'Todas las encuestas están sincronizadas ($encuestasSincronizadas)',
              style: TextStyle(
                color: encuestasPendientes > 0 ? Colors.orange[700] : Colors.green[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (encuestasPendientes > 0) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isSyncing ? null : _sincronizarEncuestasPendientes,
              icon: _isSyncing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 16),
              label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[700],
                textStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.poll_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay encuestas registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para crear tu primera encuesta',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showPacienteSelector,
            icon: const Icon(Icons.add),
            label: const Text('Crear Encuesta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncuestaCard(Encuesta encuesta) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: encuesta.syncStatus == 1 ? Colors.green : Colors.orange,
          child: Icon(
            encuesta.syncStatus == 1 ? Icons.cloud_done : Icons.cloud_upload,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Encuesta ${encuesta.id.substring(0, 8)}...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Domicilio: ${encuesta.domicilio}'),
            Text('Fecha: ${encuesta.fecha.day}/${encuesta.fecha.month}/${encuesta.fecha.year}'),
            Text('Entidad: ${encuesta.entidadAfiliada}'),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: encuesta.syncStatus == 1 ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                encuesta.syncStatus == 1 ? 'Sincronizada' : 'Pendiente',
                style: TextStyle(
                  color: encuesta.syncStatus == 1 ? Colors.green[700] : Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (encuesta.syncStatus == 0)
              const Icon(Icons.sync_problem, color: Colors.orange),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _viewEncuestaDetail(encuesta),
      ),
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

  // 🆕 MÉTODO MODIFICADO CON BÚSQUEDA DE PACIENTES
  void _showPacienteSelector() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final pacientes = await dbHelper.readAllPacientes();
      
      if (pacientes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay pacientes registrados. Sincroniza primero los datos.'),
            backgroundColor: Colors.orange,
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
      debugPrint('Error al cargar pacientes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar pacientes: $e'),
          backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('Encuesta creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}

// 🆕 WIDGET SEPARADO PARA EL DIÁLOGO DE SELECCIÓN DE PACIENTES CON BÚSQUEDA
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_search, color: Colors.indigo[700]),
          const SizedBox(width: 8),
          const Text('Seleccionar Paciente'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500, // Aumentamos la altura para acomodar la búsqueda
        child: Column(
          children: [
            // 🆕 BARRA DE BÚSQUEDA
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o identificación',
                hintText: 'Escribe para buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 🆕 CONTADOR DE RESULTADOS
            if (_searchQuery.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredPacientes.length} paciente(s) encontrado(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // LISTA DE PACIENTES FILTRADOS
            Expanded(
              child: _filteredPacientes.isEmpty
                  ? _buildEmptySearchResults()
                  : ListView.builder(
                      itemCount: _filteredPacientes.length,
                      itemBuilder: (context, index) {
                        final paciente = _filteredPacientes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo[100],
                              child: Text(
                                paciente.nombre[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.indigo[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              paciente.nombreCompleto,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${paciente.identificacion}'),
                                // 🆕 RESALTADO DE TEXTO COINCIDENTE (OPCIONAL)
                                if (_searchQuery.isNotEmpty)
                                  Text(
                                    'Coincidencia encontrada',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(context, paciente);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  // 🆕 WIDGET PARA MOSTRAR CUANDO NO HAY RESULTADOS DE BÚSQUEDA
  Widget _buildEmptySearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron pacientes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otro término de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar búsqueda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
