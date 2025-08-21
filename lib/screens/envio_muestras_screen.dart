// screens/envio_muestras_screen.dart - VERSIÓN CON BOTÓN ELIMINAR
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/envio_muestra_model.dart';
import '../services/envio_muestra_service.dart';
import '../providers/auth_provider.dart';
import 'crear_envio_muestra_screen.dart';

class EnvioMuestrasScreen extends StatefulWidget {
  @override
  _EnvioMuestrasScreenState createState() => _EnvioMuestrasScreenState();
}

class _EnvioMuestrasScreenState extends State<EnvioMuestrasScreen> {
  List<EnvioMuestra> _envios = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, int> _estadoSincronizacion = {};

  @override
  void initState() {
    super.initState();
    _cargarEnvios();
    _cargarEstadoSincronizacion();
  }

  Future<void> _cargarEnvios() async {
    setState(() => _isLoading = true);
    
    try {
      final envios = await EnvioMuestraService.obtenerTodosLosEnvios();
      setState(() {
        _envios = envios;
        _isLoading = false;
      });
      debugPrint('📊 ${envios.length} envíos cargados');
    } catch (e) {
      debugPrint('❌ Error cargando envíos: $e');
      setState(() => _isLoading = false);
      _mostrarMensaje('Error cargando envíos: $e', isError: true);
    }
  }

  Future<void> _cargarEstadoSincronizacion() async {
    try {
      final estado = await EnvioMuestraService.obtenerEstadoSincronizacion();
      setState(() => _estadoSincronizacion = estado);
      debugPrint('📈 Estado cargado: ${estado['pendientes']} pendientes, ${estado['sincronizados']} sincronizados');
    } catch (e) {
      debugPrint('❌ Error cargando estado: $e');
    }
  }

  Future<void> _sincronizarEnvios() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      _mostrarMensaje('No hay token de autenticación', isError: true);
      return;
    }

    setState(() => _isSyncing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sincronizando envíos de muestras...'),
            SizedBox(height: 8),
            Text(
              'Por favor espera mientras se sincronizan los datos',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      debugPrint('🔄 Iniciando sincronización manual...');
      
      final resultado = await EnvioMuestraService.sincronizarEnviosPendientes(authProvider.token!);
      
      Navigator.of(context).pop(); // Cerrar diálogo
      setState(() => _isSyncing = false);

      final exitosas = resultado['exitosas'] ?? 0;
      final fallidas = resultado['fallidas'] ?? 0;
      final total = resultado['total'] ?? 0;

      debugPrint('📈 Resultado: $exitosas exitosas, $fallidas fallidas de $total total');

      if (exitosas > 0) {
        _mostrarMensaje('✅ $exitosas envíos sincronizados exitosamente');
        await _cargarEnvios();
        await _cargarEstadoSincronizacion();
      } else if (fallidas > 0) {
        final errores = resultado['errores'] as List<String>? ?? [];
        String mensajeError = '⚠️ $fallidas envíos fallaron en la sincronización';
        if (errores.isNotEmpty) {
          mensajeError += '\nPrimer error: ${errores.first}';
        }
        _mostrarMensaje(mensajeError, isError: true);
      } else if (total == 0) {
        _mostrarMensaje('ℹ️ No hay envíos pendientes por sincronizar');
      } else {
        _mostrarMensaje('⚠️ No se pudieron sincronizar los envíos', isError: true);
      }
    } catch (e) {
      Navigator.of(context).pop();
      setState(() => _isSyncing = false);
      debugPrint('💥 Error en sincronización: $e');
      _mostrarMensaje('❌ Error en sincronización: $e', isError: true);
    }
  }

  // 🆕 MÉTODO PARA ELIMINAR ENVÍO
  Future<void> _eliminarEnvio(EnvioMuestra envio) async {
    // Mostrar diálogo de confirmación
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_forever, color: Colors.red[700], size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Eliminar Envío',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código: ${envio.codigo}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text('📅 Fecha: ${envio.fecha.day}/${envio.fecha.month}/${envio.fecha.year}'),
                      Text('📍 Lugar: ${envio.lugarTomaMuestras}'),
                      Text('🧪 Muestras: ${envio.detalles.length}'),
                      if (envio.syncStatus == 1) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done, size: 16, color: Colors.green[700]),
                              SizedBox(width: 4),
                              Text(
                                'Sincronizado',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¿Estás seguro de que deseas eliminar este envío? Esta acción no se puede deshacer.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Eliminar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Eliminando envío...'),
            ],
          ),
        ),
      );

      try {
        final resultado = await EnvioMuestraService.eliminarEnvio(envio.id);
        
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        
        if (resultado) {
          _mostrarMensaje('✅ Envío eliminado exitosamente');
          await _cargarEnvios();
          await _cargarEstadoSincronizacion();
        } else {
          _mostrarMensaje('❌ Error al eliminar el envío', isError: true);
        }
      } catch (e) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        debugPrint('❌ Error eliminando envío: $e');
        _mostrarMensaje('❌ Error al eliminar: $e', isError: true);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
        action: isError ? SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _estadoSincronizacion['pendientes'] ?? 0;
    final sincronizados = _estadoSincronizacion['sincronizados'] ?? 0;
    final total = _estadoSincronizacion['total'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Envío de Muestras'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (pendientes > 0 && !_isSyncing)
            IconButton(
              icon: Badge(
                label: Text('$pendientes'),
                child: Icon(Icons.sync),
              ),
              onPressed: _sincronizarEnvios,
              tooltip: 'Sincronizar envíos pendientes',
            ),
          if (_isSyncing)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              _cargarEnvios();
              _cargarEstadoSincronizacion();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ PANEL DE ESTADO MEJORADO
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.blue[200]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Sincronización',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEstadoCard('Total', total.toString(), Colors.blue),
                    _buildEstadoCard('Sincronizados', sincronizados.toString(), Colors.green),
                    _buildEstadoCard('Pendientes', pendientes.toString(), 
                        pendientes > 0 ? Colors.orange : Colors.grey),
                  ],
                ),
                if (pendientes > 0) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                        SizedBox(width: 4),
                        Text(
                          '$pendientes envíos necesitan sincronización',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Lista de envíos
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando envíos...'),
                      ],
                    ),
                  )
                : _envios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.science, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay envíos de muestras',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Presiona + para crear el primer envío',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _cargarEnvios();
                          await _cargarEstadoSincronizacion();
                        },
                        child: ListView.builder(
                          itemCount: _envios.length,
                          itemBuilder: (context, index) {
                            final envio = _envios[index];
                            return _buildEnvioCard(envio);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrearEnvioMuestraScreen(),
            ),
          );
          
          if (resultado == true) {
            debugPrint('🔄 Recargando datos después de crear envío...');
            await _cargarEnvios();
            await _cargarEstadoSincronizacion();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        tooltip: 'Crear nuevo envío',
      ),
    );
  }

  Widget _buildEstadoCard(String titulo, String valor, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 CARD DE ENVÍO MEJORADO CON BOTÓN ELIMINAR
  Widget _buildEnvioCard(EnvioMuestra envio) {
    final isSincronizado = envio.syncStatus == 1;
    final fechaFormateada = '${envio.fecha.day}/${envio.fecha.month}/${envio.fecha.year}';
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSincronizado ? Colors.green : Colors.orange,
          child: Icon(
            isSincronizado ? Icons.cloud_done : Icons.cloud_upload,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Envío ${envio.codigo}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 Fecha: $fechaFormateada'),
            Text('📍 Lugar: ${envio.lugarTomaMuestras}'),
            Text('🧪 Muestras: ${envio.detalles.length}'),
            if (envio.detalles.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                '👥 Pacientes: ${envio.detalles.map((d) => d.pacienteId).toSet().length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (!isSincronizado) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pendiente de sincronización',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 BOTÓN ELIMINAR
            Container(
              margin: EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[600],
                  size: 22,
                ),
                onPressed: () => _eliminarEnvio(envio),
                tooltip: 'Eliminar envío',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  padding: EdgeInsets.all(8),
                  minimumSize: Size(36, 36),
                ),
              ),
            ),
            // Estado de sincronización
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSincronizado ? Icons.check_circle : Icons.pending,
                  color: isSincronizado ? Colors.green : Colors.orange,
                ),
                SizedBox(height: 4),
                Text(
                  isSincronizado ? 'Sync' : 'Pend',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSincronizado ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _mostrarDetalleEnvio(envio),
      ),
    );
  }

  void _mostrarDetalleEnvio(EnvioMuestra envio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle del Envío'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Código:', envio.codigo),
              _buildDetalleRow('Fecha:', '${envio.fecha.day}/${envio.fecha.month}/${envio.fecha.year}'),
              _buildDetalleRow('Versión:', envio.version),
              _buildDetalleRow('Lugar:', envio.lugarTomaMuestras),
              _buildDetalleRow('Estado:', envio.syncStatus == 1 ? 'Sincronizado' : 'Pendiente'),
              if (envio.horaSalida != null)
                _buildDetalleRow('Hora Salida:', envio.horaSalida!),
              if (envio.temperaturaSalida != null)
                _buildDetalleRow('Temperatura:', '${envio.temperaturaSalida}°C'),
              if (envio.observaciones != null && envio.observaciones!.isNotEmpty)
                _buildDetalleRow('Observaciones:', envio.observaciones!),
              
              SizedBox(height: 16),
              Text(
                'Muestras (${envio.detalles.length}):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              
              ...envio.detalles.map((detalle) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muestra #${detalle.numeroOrden}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                      SizedBox(height: 8),
                      
                      Text('Paciente ID: ${detalle.pacienteId}'),
                      
                      if (detalle.dm != null && detalle.dm!.isNotEmpty) 
                        Text('DM: ${detalle.dm}'),
                      if (detalle.hta != null && detalle.hta!.isNotEmpty) 
                        Text('HTA: ${detalle.hta}'),
                      
                      if (detalle.peso != null && detalle.peso!.isNotEmpty) 
                        Text('Peso: ${detalle.peso}'),
                      if (detalle.talla != null && detalle.talla!.isNotEmpty) 
                        Text('Talla: ${detalle.talla}'),
                      
                      if (detalle.numMuestrasEnviadas != null && detalle.numMuestrasEnviadas!.isNotEmpty) 
                        Text('# Muestras: ${detalle.numMuestrasEnviadas}'),
                      
                      // Mostrar información de tubos si existe
                      if (detalle.tuboLila != null && detalle.tuboLila!.isNotEmpty) 
                        Text('Tubo Lila: ${detalle.tuboLila}'),
                      if (detalle.tuboAmarillo != null && detalle.tuboAmarillo!.isNotEmpty) 
                        Text('Tubo Amarillo: ${detalle.tuboAmarillo}'),
                      if (detalle.tuboAmarilloForrado != null && detalle.tuboAmarilloForrado!.isNotEmpty) 
                        Text('Tubo Amarillo Forrado: ${detalle.tuboAmarilloForrado}'),
                      
                      // Mostrar información de orina si existe
                      if (detalle.orinaEsp != null && detalle.orinaEsp!.isNotEmpty) 
                        Text('Orina ESP: ${detalle.orinaEsp}'),
                      if (detalle.orina24h != null && detalle.orina24h!.isNotEmpty) 
                        Text('Orina 24H: ${detalle.orina24h}'),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
