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
  final _lugarLlegadaController = TextEditingController(text: 'Caucalab');
  final _observacionesController = TextEditingController();
  final _responsableTransporteController = TextEditingController();
  final _responsableRecepcionController = TextEditingController(text: 'Caucalab');
  
  // ✅ VARIABLES PARA CONTROLAR ESTADO DE CAMPOS LLENOS
  bool _lugarTomaLleno = false;
  bool _temperaturaSalidaLlena = false;
  bool _responsableTransporteLleno = false;
  
  DateTime _fechaSeleccionada = DateTime.now();
  DateTime? _fechaSalida;
  DateTime? _fechaLlegada;
  
  TimeOfDay? _horaSalidaSeleccionada;
  TimeOfDay? _horaLlegadaSeleccionada;
  
  List<Map<String, dynamic>> _sedes = [];
  String? _sedeSeleccionada;
  bool _cargandoSedes = true;
  
  List<DetalleEnvioMuestra> _detalles = [];
  List<Paciente> _pacientes = [];
  bool _isLoading = false;
  bool _isSaving = false;

  String? _usuarioLogueado;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    
    // ✅ AGREGAR LISTENERS PARA DETECTAR CUANDO SE LLENAN LOS CAMPOS
    _lugarTomaController.addListener(() {
      setState(() {
        _lugarTomaLleno = _lugarTomaController.text.trim().isNotEmpty;
      });
    });
    
    _temperaturaSalidaController.addListener(() {
      setState(() {
        _temperaturaSalidaLlena = _temperaturaSalidaController.text.trim().isNotEmpty;
      });
    });
    
    _responsableTransporteController.addListener(() {
      setState(() {
        _responsableTransporteLleno = _responsableTransporteController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _cargarPacientes(),
        _cargarSedes(),
        _cargarUsuarioLogueado(),
      ]);
    } catch (e) {
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarUsuarioLogueado() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuario = authProvider.user;
      
      if (usuario != null) {
        setState(() {
          _usuarioLogueado = '${usuario['nombre'] ?? 'Usuario'} (${usuario['usuario'] ?? ''})';
        });
        debugPrint('✅ Usuario logueado: $_usuarioLogueado');
      } else {
        debugPrint('⚠️ No hay usuario logueado');
        setState(() {
          _usuarioLogueado = 'Usuario no identificado';
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando usuario: $e');
      setState(() {
        _usuarioLogueado = 'Error al cargar usuario';
      });
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

  Future<void> _cargarSedes() async {
    setState(() => _cargandoSedes = true);
    
    try {
      final dbHelper = DatabaseHelper.instance;
      final sedes = await dbHelper.getSedes();
      
      setState(() {
        _sedes = sedes;
        _cargandoSedes = false;
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userSedeId = authProvider.user?['sede_id']?.toString();
        
        if (userSedeId != null && sedes.any((sede) => sede['id'] == userSedeId)) {
          _sedeSeleccionada = userSedeId;
          debugPrint('✅ Sede del usuario seleccionada automáticamente: $userSedeId');
        } else if (sedes.isNotEmpty) {
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

  Future<void> _seleccionarFechaSalida() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSalida ?? _fechaSeleccionada,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    
    if (fecha != null) {
      setState(() => _fechaSalida = fecha);
    }
  }

  Future<void> _seleccionarFechaLlegada() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLlegada ?? _fechaSalida ?? _fechaSeleccionada,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    
    if (fecha != null) {
      setState(() => _fechaLlegada = fecha);
    }
  }

  Future<void> _seleccionarHoraSalida() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSalidaSeleccionada ?? TimeOfDay.now(),
    );
    
    if (hora != null) {
      setState(() {
        _horaSalidaSeleccionada = hora;
        _horaSalidaController.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _seleccionarHoraLlegada() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaLlegadaSeleccionada ?? _horaSalidaSeleccionada ?? TimeOfDay.now(),
    );
    
    if (hora != null) {
      setState(() {
        _horaLlegadaSeleccionada = hora;
        _horaLlegadaController.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'No seleccionada';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  // ✅ MÉTODO PARA OBTENER COLOR DINÁMICO (ROJO → VERDE)
  Color _getBorderColor(bool isLleno) {
    return isLleno ? Colors.green : Colors.red[300]!;
  }

  Color _getIconColor(bool isLleno) {
    return isLleno ? Colors.green[700]! : Colors.red[700]!;
  }

  bool _validarCamposObligatorios() {
    List<String> camposFaltantes = [];

    if (_sedeSeleccionada == null || _sedeSeleccionada!.isEmpty) {
      camposFaltantes.add('Sede');
    }
    
    if (_lugarTomaController.text.trim().isEmpty) {
      camposFaltantes.add('Lugar de toma de muestras');
    }
    
    if (_fechaSalida == null) {
      camposFaltantes.add('Fecha de salida');
    }
    
    if (_horaSalidaController.text.trim().isEmpty) {
      camposFaltantes.add('Hora de salida');
    }
    
    if (_temperaturaSalidaController.text.trim().isEmpty) {
      camposFaltantes.add('Temperatura de salida');
    }
    
    if (_responsableTransporteController.text.trim().isEmpty) {
      camposFaltantes.add('Responsable de transporte');
    }

    if (camposFaltantes.isNotEmpty) {
      String mensaje = 'Por favor complete los siguientes campos obligatorios:\n\n';
      mensaje += camposFaltantes.map((campo) => '• $campo').join('\n');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Text(
                'Campos Obligatorios',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No puede guardar el envío sin completar los siguientes campos:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                ...camposFaltantes.map((campo) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          campo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Entendido'),
            ),
          ],
        ),
      );
      
      return false;
    }

    return true;
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
                    SizedBox(height: 80),
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
            onPressed: _detalles.isEmpty || _isSaving ? null : _guardarEnvio,
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
            backgroundColor: _detalles.isEmpty ? Colors.grey : Colors.blue[800],
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
            
            // RESPONSABLE DE TOMA (USUARIO LOGUEADO)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Responsable de Toma de Muestras',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _usuarioLogueado ?? 'Cargando...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Se asignará automáticamente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // ✅ SEDE OBLIGATORIA (ROJO → VERDE)
            _buildSelectorSede(),
            SizedBox(height: 16),
            
            // ✅ FECHA DEL ENVÍO (SIEMPRE VERDE PORQUE TIENE VALOR POR DEFECTO)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.green[700]),
                title: Row(
                  children: [
                    Text('Fecha del envío'),
                    SizedBox(width: 4),
                    Text('*', style: TextStyle(color: Colors.green, fontSize: 18)),
                  ],
                ),
                subtitle: Text(
                  '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Icon(Icons.check_circle, color: Colors.green),
                onTap: _seleccionarFecha,
              ),
            ),
            SizedBox(height: 16),
            
            // ✅ LUGAR DE TOMA OBLIGATORIO (ROJO → VERDE)
            TextFormField(
              controller: _lugarTomaController,
              decoration: InputDecoration(
                labelText: 'Lugar de toma de muestras',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _lugarTomaLleno ? Colors.green[700] : Colors.red[700],
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: _getBorderColor(_lugarTomaLleno), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _getBorderColor(_lugarTomaLleno), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _lugarTomaLleno ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Icons.location_on, color: _getIconColor(_lugarTomaLleno)),
                suffixIcon: _lugarTomaLleno 
                    ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : Icon(Icons.star, color: Colors.red, size: 16),
                hintText: 'Ingrese el lugar de toma',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // ✅ INFORMACIÓN DE SALIDA (TODOS OBLIGATORIOS - ROJO → VERDE)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_fechaSalida != null && _horaSalidaSeleccionada != null && 
                        _temperaturaSalidaLlena && _responsableTransporteLleno)
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_fechaSalida != null && _horaSalidaSeleccionada != null && 
                          _temperaturaSalidaLlena && _responsableTransporteLleno)
                      ? Colors.green[300]!
                      : Colors.red[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        (_fechaSalida != null && _horaSalidaSeleccionada != null && 
                         _temperaturaSalidaLlena && _responsableTransporteLleno)
                            ? Icons.check_circle
                            : Icons.warning,
                        color: (_fechaSalida != null && _horaSalidaSeleccionada != null && 
                                _temperaturaSalidaLlena && _responsableTransporteLleno)
                            ? Colors.green[700]
                            : Colors.red[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Información de Salida',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (_fechaSalida != null && _horaSalidaSeleccionada != null && 
                                  _temperaturaSalidaLlena && _responsableTransporteLleno)
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // ✅ FECHA SALIDA OBLIGATORIA (ROJO → VERDE)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _fechaSalida != null ? Colors.green : Colors.red[300]!,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: _fechaSalida != null ? Colors.green[600] : Colors.red[600],
                      ),
                      title: Row(
                        children: [
                          Text('Fecha de salida'),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(
                            color: _fechaSalida != null ? Colors.green : Colors.red,
                            fontSize: 18,
                          )),
                        ],
                      ),
                      subtitle: Text(
                        _formatearFecha(_fechaSalida),
                        style: TextStyle(
                          fontWeight: _fechaSalida == null ? FontWeight.normal : FontWeight.bold,
                          color: _fechaSalida == null ? Colors.grey : Colors.black,
                        ),
                      ),
                      trailing: _fechaSalida != null 
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _seleccionarFechaSalida,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // ✅ HORA Y TEMPERATURA SALIDA (ROJO → VERDE)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _horaSalidaSeleccionada != null ? Colors.green : Colors.red[300]!,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Icon(
                                Icons.access_time,
                                color: _horaSalidaSeleccionada != null ? Colors.green[600] : Colors.red[600],
                              ),
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Hora salida',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '*',
                                    style: TextStyle(
                                      color: _horaSalidaSeleccionada != null ? Colors.green : Colors.red,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                _horaSalidaSeleccionada != null 
                                    ? '${_horaSalidaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSalidaSeleccionada!.minute.toString().padLeft(2, '0')}'
                                    : 'Seleccionar',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: _horaSalidaSeleccionada == null ? FontWeight.normal : FontWeight.bold,
                                  color: _horaSalidaSeleccionada == null ? Colors.grey : Colors.black,
                                ),
                              ),
                              trailing: _horaSalidaSeleccionada != null 
                                  ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                                  : null,
                              onTap: _seleccionarHoraSalida,
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _temperaturaSalidaController,
                          decoration: InputDecoration(
                            labelText: 'Temp. salida (°C)',
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _temperaturaSalidaLlena ? Colors.green[700] : Colors.red[700],
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _getBorderColor(_temperaturaSalidaLlena),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _getBorderColor(_temperaturaSalidaLlena),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _temperaturaSalidaLlena ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.thermostat,
                              color: _getIconColor(_temperaturaSalidaLlena),
                            ),
                            suffixIcon: _temperaturaSalidaLlena
                                ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : Icon(Icons.star, color: Colors.red, size: 16),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // ✅ RESPONSABLE DE TRANSPORTE (ROJO → VERDE)
                  TextFormField(
                    controller: _responsableTransporteController,
                    decoration: InputDecoration(
                      labelText: 'Responsable de Transporte',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _responsableTransporteLleno ? Colors.green[700] : Colors.red[700],
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _getBorderColor(_responsableTransporteLleno),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _getBorderColor(_responsableTransporteLleno),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _responsableTransporteLleno ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.local_shipping,
                        color: _getIconColor(_responsableTransporteLleno),
                      ),
                      suffixIcon: _responsableTransporteLleno
                          ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : Icon(Icons.star, color: Colors.red, size: 16),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Nombre del responsable',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Este campo es obligatorio';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

                       // INFORMACIÓN DE LLEGADA (OPCIONALES)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Información de Llegada ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Colors.green[600]),
                    title: Text('Fecha de llegada'),
                    subtitle: Text(_formatearFecha(_fechaLlegada)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _seleccionarFechaLlegada,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: Colors.white,
                  ),
                  SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: Icon(Icons.access_time_filled, color: Colors.green[600]),
                          title: Text('Hora llegada'),
                          subtitle: Text(_horaLlegadaSeleccionada != null 
                              ? '${_horaLlegadaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaLlegadaSeleccionada!.minute.toString().padLeft(2, '0')}'
                              : 'No seleccionada'),
                          onTap: _seleccionarHoraLlegada,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _temperaturaLlegadaController,
                          decoration: InputDecoration(
                            labelText: 'Temp. llegada (°C)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.thermostat_outlined, color: Colors.green[600]),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // LUGAR DE LLEGADA CON VALOR AUTOMÁTICO "Caucalab"
                  TextFormField(
                    controller: _lugarLlegadaController,
                    decoration: InputDecoration(
                      labelText: 'Lugar de llegada',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city, color: Colors.green[600]),
                      filled: true,
                      fillColor: Colors.green[100],
                      suffixIcon: Tooltip(
                        message: 'Valor predeterminado: Caucalab',
                        child: Icon(Icons.check_circle, color: Colors.green[700]),
                      ),
                    ),
                    readOnly: false,
                  ),
                  SizedBox(height: 12),
                  
                  // RESPONSABLE DE RECEPCIÓN CON VALOR AUTOMÁTICO "Caucalab"
                  TextFormField(
                    controller: _responsableRecepcionController,
                    decoration: InputDecoration(
                      labelText: 'Responsable de Recepción',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.how_to_reg, color: Colors.green[600]),
                      filled: true,
                      fillColor: Colors.green[100],
                      suffixIcon: Tooltip(
                        message: 'Valor predeterminado: Caucalab',
                        child: Icon(Icons.check_circle, color: Colors.green[700]),
                      ),
                    ),
                    readOnly: false,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
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

  Widget _buildSelectorSede() {
    // ✅ DETERMINAR SI LA SEDE ESTÁ SELECCIONADA
    bool sedeSeleccionada = _sedeSeleccionada != null && _sedeSeleccionada!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sede',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(width: 4),
            Text('*', style: TextStyle(
              color: sedeSeleccionada ? Colors.green : Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: sedeSeleccionada ? Colors.green : Colors.red[300]!,
              width: 2,
            ),
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
                        prefixIcon: Icon(
                          Icons.business,
                          color: sedeSeleccionada ? Colors.green[700] : Colors.red[700],
                        ),
                        suffixIcon: sedeSeleccionada 
                            ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                            : null,
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

  String _obtenerNombreSede(String sedeId) {
    try {
      final sede = _sedes.firstWhere((s) => s['id'].toString() == sedeId);
      return sede['nombresede']?.toString() ?? 'Sede sin nombre';
    } catch (e) {
      return 'Sede desconocida';
    }
  }

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
    Paciente? pacienteInfo;
    try {
      pacienteInfo = _pacientes.firstWhere((p) => p.id == detalle.pacienteId);
    } catch (e) {
      debugPrint('⚠️ Paciente no encontrado para ID: ${detalle.pacienteId}');
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue[50]!.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${detalle.numeroOrden}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Text(
            'Muestra #${detalle.numeroOrden}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
          subtitle: Container(
            margin: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          pacienteInfo != null
                              ? '${pacienteInfo.identificacion} - ${pacienteInfo.nombre} ${pacienteInfo.apellido}'
                              : 'ID: ${detalle.pacienteId} (Paciente no encontrado)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (detalle.dm?.isNotEmpty == true || detalle.hta?.isNotEmpty == true) ...[
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Diagnóstico: ${[detalle.dm, detalle.hta].where((e) => e?.isNotEmpty == true).join(', ')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (detalle.numMuestrasEnviadas?.isNotEmpty == true) ...[
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.science,
                          size: 16,
                          color: Colors.purple[700],
                        ),
                        SizedBox(width: 6),
                        Text(
                          '# Muestras: ${detalle.numMuestrasEnviadas}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.red[600]),
              onPressed: () => _eliminarMuestra(index),
              tooltip: 'Eliminar muestra',
            ),
          ),
          onTap: () => _editarMuestra(index),
        ),
      ),
    );
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
                    microo: _detalles[i].microo,
                    creaori: _detalles[i].creaori,
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

  Future<void> _guardarEnvio() async {
    if (!_formKey.currentState!.validate()) {
      _mostrarError('Por favor corrija los errores en el formulario');
      return;
    }

    if (!_validarCamposObligatorios()) {
      return;
    }

    if (_detalles.isEmpty) {
      _mostrarError('Debe agregar al menos una muestra');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final envio = EnvioMuestra(
        id: 'env_${_uuid.v4()}',
        codigo: 'PM-CE-TM-F-01',
        fecha: _fechaSeleccionada,
        version: '1',
        lugarTomaMuestras: _lugarTomaController.text.trim(),
        horaSalida: _horaSalidaController.text.trim(),
        fechaSalida: _fechaSalida,
        temperaturaSalida: double.tryParse(_temperaturaSalidaController.text.trim()),
        responsableTransporteId: _responsableTransporteController.text.trim(),
        fechaLlegada: _fechaLlegada,
        horaLlegada: _horaLlegadaController.text.isEmpty ? null : _horaLlegadaController.text.trim(),
        temperaturaLlegada: _temperaturaLlegadaController.text.isEmpty 
            ? null 
            : double.tryParse(_temperaturaLlegadaController.text.trim()),
        lugarLlegada: _lugarLlegadaController.text.trim(),
        responsableRecepcionId: _responsableRecepcionController.text.trim(),
        observaciones: _observacionesController.text.isEmpty ? null : _observacionesController.text.trim(),
        idsede: _sedeSeleccionada!,
        detalles: _detalles,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await EnvioMuestraService.guardarEnvioMuestra(envio, authProvider.token);

      if (success) {
        _mostrarExito('✅ Envío de muestras guardado exitosamente');
        await Future.delayed(Duration(seconds: 1));
        Navigator.of(context).pop(true);
      } else {
        _mostrarError('❌ Error al guardar el envío de muestras');
      }
    } catch (e) {
      _mostrarError('❌ Error: $e');
      debugPrint('Error completo: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
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
    _responsableTransporteController.dispose();
    _responsableRecepcionController.dispose();
    super.dispose();
  }
}
