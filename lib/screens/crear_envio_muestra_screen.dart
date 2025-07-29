// screens/crear_envio_muestra_screen.dart - VERSIÓN ACTUALIZADA
import 'package:flutter/material.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/models/envio_muestra_model.dart';
import 'package:fnpv_app/models/paciente_model.dart';
import 'package:fnpv_app/services/envio_muestra_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import 'agregar_detalle_muestra_screen.dart';

class CrearEnvioMuestraScreen extends StatefulWidget {
  @override
  _CrearEnvioMuestraScreenState createState() => _CrearEnvioMuestraScreenState();
}

class _CrearEnvioMuestraScreenState extends State<CrearEnvioMuestraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  
  // Controladores para el formulario principal
  final _lugarTomaController = TextEditingController();
  final _horaSalidaController = TextEditingController();
  final _temperaturaSalidaController = TextEditingController();
  final _horaLlegadaController = TextEditingController();
  final _temperaturaLlegadaController = TextEditingController();
  final _lugarLlegadaController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  DateTime _fechaSeleccionada = DateTime.now();
  DateTime? _fechaSalida;
  DateTime? _fechaLlegada;
  
  // ✅ NUEVAS VARIABLES PARA SEDES
  List<Map<String, dynamic>> _sedes = [];
  String? _sedeSeleccionada;
  bool _cargandoSedes = true;
  
  List<DetalleEnvioMuestra> _detalles = [];
  List<Paciente> _pacientes = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  // ✅ MÉTODO PARA CARGAR DATOS INICIALES
  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar en paralelo para mejor rendimiento
      await Future.wait([
        _cargarPacientes(),
        _cargarSedes(),
      ]);
    } catch (e) {
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarPacientes() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final pacientes = await dbHelper.readAllPacientes();
      setState(() {
        _pacientes = pacientes;
      });
      debugPrint('✅ ${pacientes.length} pacientes cargados');
    } catch (e) {
      debugPrint('❌ Error cargando pacientes: $e');
      throw e;
    }
  }

  // ✅ MÉTODO PARA CARGAR SEDES DESDE LA BASE DE DATOS LOCAL
  Future<void> _cargarSedes() async {
    setState(() => _cargandoSedes = true);
    
    try {
      final dbHelper = DatabaseHelper.instance;
      final sedes = await dbHelper.getSedes();
      
      setState(() {
        _sedes = sedes;
        _cargandoSedes = false;
        
        // ✅ SELECCIONAR AUTOMÁTICAMENTE LA SEDE DEL USUARIO SI EXISTE
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userSedeId = authProvider.user?['sede_id']?.toString();
        
        if (userSedeId != null && sedes.any((sede) => sede['id'] == userSedeId)) {
          _sedeSeleccionada = userSedeId;
          debugPrint('✅ Sede del usuario seleccionada automáticamente: $userSedeId');
        } else if (sedes.isNotEmpty) {
          // Si no tiene sede asignada, seleccionar la primera disponible
          _sedeSeleccionada = sedes.first['id'].toString();
          debugPrint('✅ Primera sede seleccionada por defecto: ${_sedeSeleccionada}');
        }
      });
      
      debugPrint('✅ ${sedes.length} sedes cargadas desde base de datos local');
    } catch (e) {
      setState(() => _cargandoSedes = false);
      debugPrint('❌ Error cargando sedes: $e');
      _mostrarError('Error cargando sedes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Envío de Muestras'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_detalles.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_detalles.length} muestras',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormularioPrincipal(),
                    SizedBox(height: 24),
                    _buildSeccionMuestras(),
                    SizedBox(height: 80), // Espacio para FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "add_sample",
            onPressed: _agregarMuestra,
            child: Icon(Icons.add),
            backgroundColor: Colors.blue[600],
            mini: true,
            tooltip: 'Agregar muestra',
          ),
          SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "save_envio",
            onPressed: _detalles.isEmpty || _isSaving || _sedeSeleccionada == null ? null : _guardarEnvio,
            icon: _isSaving 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar Envío'),
            backgroundColor: (_detalles.isEmpty || _sedeSeleccionada == null) ? Colors.grey : Colors.blue[800],
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioPrincipal() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Envío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 16),
            
            // ✅ SELECTOR DE SEDE - NUEVO CAMPO
            _buildSelectorSede(),
            SizedBox(height: 16),
            
            // Fecha
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Fecha del envío'),
              subtitle: Text('${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}'),
              onTap: _seleccionarFecha,
            ),
            
            // Lugar de toma de muestras
            TextFormField(
              controller: _lugarTomaController,
              decoration: InputDecoration(
                labelText: 'Lugar de toma de muestras *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Información de salida
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _horaSalidaController,
                    decoration: InputDecoration(
                      labelText: 'Hora salida',
                      hintText: '08:00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _temperaturaSalidaController,
                    decoration: InputDecoration(
                      labelText: 'Temperatura salida (°C)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thermostat),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Información de llegada
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _horaLlegadaController,
                    decoration: InputDecoration(
                      labelText: 'Hora llegada',
                      hintText: '10:00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_filled),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _temperaturaLlegadaController,
                    decoration: InputDecoration(
                      labelText: 'Temperatura llegada (°C)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thermostat_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Lugar de llegada
            TextFormField(
              controller: _lugarLlegadaController,
              decoration: InputDecoration(
                labelText: 'Lugar de llegada',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            SizedBox(height: 16),
            
            // Observaciones
            TextFormField(
              controller: _observacionesController,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET PARA SELECTOR DE SEDE
  Widget _buildSelectorSede() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sede *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _cargandoSedes
              ? Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Cargando sedes...'),
                    ],
                  ),
                )
              : _sedes.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No hay sedes disponibles',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Contacte al administrador',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _sedeSeleccionada,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Icon(Icons.business),
                      ),
                      hint: Text('Seleccione una sede'),
                      items: _sedes.map((sede) {
                        return DropdownMenuItem<String>(
                          value: sede['id'].toString(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sede['nombresede']?.toString() ?? 'Sin nombre',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (sede['direccion'] != null && sede['direccion'].toString().isNotEmpty)
                                Text(
                                  sede['direccion'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? nuevaSede) {
                        setState(() {
                          _sedeSeleccionada = nuevaSede;
                        });
                        debugPrint('✅ Sede seleccionada: $nuevaSede');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Debe seleccionar una sede';
                        }
                        return null;
                      },
                    ),
        ),
        if (_sedeSeleccionada != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                SizedBox(width: 4),
                Text(
                  'Sede seleccionada: ${_obtenerNombreSede(_sedeSeleccionada!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ✅ MÉTODO AUXILIAR PARA OBTENER NOMBRE DE SEDE
  String _obtenerNombreSede(String sedeId) {
    try {
      final sede = _sedes.firstWhere((s) => s['id'].toString() == sedeId);
      return sede['nombresede']?.toString() ?? 'Sede sin nombre';
    } catch (e) {
      return 'Sede desconocida';
    }
  }

  // ... resto de los métodos existentes sin cambios ...
  Widget _buildSeccionMuestras() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Muestras (${_detalles.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                if (_detalles.isEmpty)
                  TextButton.icon(
                    onPressed: _agregarMuestra,
                    icon: Icon(Icons.add),
                    label: Text('Agregar primera muestra'),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            if (_detalles.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.science, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay muestras agregadas',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Presiona + para agregar la primera muestra',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _detalles.length,
                itemBuilder: (context, index) {
                  final detalle = _detalles[index];
                  return _buildMuestraCard(detalle, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuestraCard(DetalleEnvioMuestra detalle, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[800],
          child: Text(
            '${detalle.numeroOrden}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Muestra #${detalle.numeroOrden}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paciente ID: ${detalle.pacienteId}'),
            if (detalle.dm?.isNotEmpty == true || detalle.hta?.isNotEmpty == true)
              Text('Diagnóstico: ${[detalle.dm, detalle.hta].where((e) => e?.isNotEmpty == true).join(', ')}'),
            if (detalle.numMuestrasEnviadas?.isNotEmpty == true)
              Text('# Muestras: ${detalle.numMuestrasEnviadas}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _eliminarMuestra(index),
        ),
        onTap: () => _editarMuestra(index),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  void _agregarMuestra() async {
    if (_sedeSeleccionada == null) {
      _mostrarError('Debe seleccionar una sede antes de agregar muestras');
      return;
    }

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarDetalleMuestraScreen(
          pacientes: _pacientes,
          numeroOrden: _detalles.length + 1,
          onAgregar: (detalle) {
            setState(() {
              _detalles.add(detalle);
            });
          },
        ),
      ),
    );
  }

  void _editarMuestra(int index) {
    _mostrarInfo('Función de edición en desarrollo');
  }

  void _eliminarMuestra(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar muestra'),
        content: Text('¿Estás seguro de que quieres eliminar esta muestra?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _detalles.removeAt(index);
                // Reordenar números
                for (int i = 0; i < _detalles.length; i++) {
                  _detalles[i] = DetalleEnvioMuestra(
                    id: _detalles[i].id,
                    envioMuestraId: _detalles[i].envioMuestraId,
                    pacienteId: _detalles[i].pacienteId,
                    numeroOrden: i + 1,
                    dm: _detalles[i].dm,
                    hta: _detalles[i].hta,
                    numMuestrasEnviadas: _detalles[i].numMuestrasEnviadas,
                    tuboLila: _detalles[i].tuboLila,
                    tuboAmarillo: _detalles[i].tuboAmarillo,
                    tuboAmarilloForrado: _detalles[i].tuboAmarilloForrado,
                    orinaEsp: _detalles[i].orinaEsp,
                    orina24h: _detalles[i].orina24h,
                    a: _detalles[i].a,
                    m: _detalles[i].m,
                    oe: _detalles[i].oe,
                    po: _detalles[i].po,
                    h3: _detalles[i].h3,
                    hba1c: _detalles[i].hba1c,
                    pth: _detalles[i].pth,
                    glu: _detalles[i].glu,
                    crea: _detalles[i].crea,
                    pl: _detalles[i].pl,
                    au: _detalles[i].au,
                    bun: _detalles[i].bun,
                    relacionCreaAlb: _detalles[i].relacionCreaAlb,
                    dcre24h: _detalles[i].dcre24h,
                    alb24h: _detalles[i].alb24h,
                    buno24h: _detalles[i].buno24h,
                    fer: _detalles[i].fer,
                    tra: _detalles[i].tra,
                    fosfat: _detalles[i].fosfat,
                    alb: _detalles[i].alb,
                    fe: _detalles[i].fe,
                    tsh: _detalles[i].tsh,
                    p: _detalles[i].p,
                    ionograma: _detalles[i].ionograma,
                    b12: _detalles[i].b12,
                    acidoFolico: _detalles[i].acidoFolico,
                    peso: _detalles[i].peso,
                    talla: _detalles[i].talla,
                    volumen: _detalles[i].volumen,
                  );
                }
              });
              Navigator.pop(context);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO PARA GUARDAR CON VALIDACIÓN DE SEDE
  Future<void> _guardarEnvio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sedeSeleccionada == null) {
      _mostrarError('Debe seleccionar una sede');
      return;
    }

    if (_detalles.isEmpty) {
      _mostrarError('Debe agregar al menos una muestra');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Crear envío con sede seleccionada
      final envio = EnvioMuestra(
        id: 'env_${_uuid.v4()}',
        codigo: 'PM-CE-TM-F-01',
        fecha: _fechaSeleccionada,
        version: '1',
        lugarTomaMuestras: _lugarTomaController.text,
        horaSalida: _horaSalidaController.text.isEmpty ? null : _horaSalidaController.text,
        fechaSalida: _fechaSalida,
        temperaturaSalida: _temperaturaSalidaController.text.isEmpty 
            ? null 
            : double.tryParse(_temperaturaSalidaController.text),
        fechaLlegada: _fechaLlegada,
        horaLlegada: _horaLlegadaController.text.isEmpty ? null : _horaLlegadaController.text,
        temperaturaLlegada: _temperaturaLlegadaController.text.isEmpty 
            ? null 
            : double.tryParse(_temperaturaLlegadaController.text),
        lugarLlegada: _lugarLlegadaController.text.isEmpty ? null : _lugarLlegadaController.text,
        observaciones: _observacionesController.text.isEmpty ? null : _observacionesController.text,
        idsede: _sedeSeleccionada!, // ✅ USAR SEDE SELECCIONADA
        detalles: _detalles,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await EnvioMuestraService.guardarEnvioMuestra(envio, authProvider.token);

      if (success) {
        _mostrarExito('Envío de muestras guardado exitosamente');
        Navigator.of(context).pop(true);
      } else {
        _mostrarError('Error al guardar el envío de muestras');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _lugarTomaController.dispose();
    _horaSalidaController.dispose();
    _temperaturaSalidaController.dispose();
    _horaLlegadaController.dispose();
    _temperaturaLlegadaController.dispose();
    _lugarLlegadaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}
