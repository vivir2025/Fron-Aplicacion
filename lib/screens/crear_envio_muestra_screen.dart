import 'package:flutter/material.dart';
import 'package:Bornive/database/database_helper.dart';
import 'package:Bornive/models/envio_muestra_model.dart';
import 'package:Bornive/models/paciente_model.dart';
import 'package:Bornive/services/envio_muestra_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import 'agregar_detalle_muestra_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 TEMA DE COLORES UNIFICADO
const Color primaryColor = Color(0xFF1B5E20);
const Color primaryLightColor = Color(0xFF4CAF50);
const Color surfaceColor = Color(0xFFF0F4F8);
const Color textPrimaryColor = Color(0xFF212121);
const Color textSecondaryColor = Color(0xFF757575);
const Color dividerColor = Color(0xFFE0E0E0);

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
      } else {
        setState(() {
          _usuarioLogueado = 'Usuario no identificado';
        });
      }
    } catch (e) {
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
    } catch (e) {
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
        } else if (sedes.isNotEmpty) {
          _sedeSeleccionada = sedes.first['id'].toString();
        }
      });
      
    } catch (e) {
      setState(() => _cargandoSedes = false);
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
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        textTheme: GoogleFonts.robotoTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dividerColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dividerColor),
          ),
          filled: true,
          fillColor: Colors.white,
          floatingLabelStyle: const TextStyle(color: primaryColor),
        ),
      ),
      child: Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Crear Envío de Muestras',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            if (_detalles.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '${_detalles.length} muestras',
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
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
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 16),
                    Text('Cargando datos...', style: GoogleFonts.roboto(color: textSecondaryColor)),
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
            child: const Icon(Icons.add),
            backgroundColor: primaryColor,
            tooltip: 'Agregar muestra',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "save_envio",
            onPressed: _detalles.isEmpty || _isSaving ? null : _guardarEnvio,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar Envío', style: GoogleFonts.roboto()),
            backgroundColor: _detalles.isEmpty ? Colors.grey : primaryColor,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFormularioPrincipal() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información del Envío',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // RESPONSABLE DE TOMA (USUARIO LOGUEADO)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responsable de Toma',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _usuarioLogueado ?? 'Cargando...',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // ✅ SEDE OBLIGATORIA (ROJO → VERDE)
            _buildSelectorSede(),
            SizedBox(height: 16),
            
            // FECHA DEL ENVÍO
            InkWell(
              onTap: _seleccionarFecha,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha del Envío *',
                  prefixIcon: const Icon(Icons.calendar_today, color: primaryColor),
                ),
                child: Text(
                  '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                  style: GoogleFonts.roboto(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // LUGAR DE TOMA
            TextFormField(
              controller: _lugarTomaController,
              style: GoogleFonts.roboto(),
              decoration: const InputDecoration(
                labelText: 'Lugar de Toma de Muestras *',
                prefixIcon: Icon(Icons.location_on, color: primaryColor),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // INFORMACIÓN DE SALIDA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Salida',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // FECHA SALIDA
                  InkWell(
                    onTap: _seleccionarFechaSalida,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Salida *',
                        prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                      ),
                      child: Text(
                        _formatearFecha(_fechaSalida),
                        style: GoogleFonts.roboto(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // HORA Y TEMPERATURA SALIDA
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _seleccionarHoraSalida,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora Salida *',
                              prefixIcon: Icon(Icons.access_time, color: primaryColor),
                            ),
                            child: Text(
                              _horaSalidaSeleccionada != null 
                                  ? '${_horaSalidaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSalidaSeleccionada!.minute.toString().padLeft(2, '0')}'
                                  : 'Seleccionar',
                              style: GoogleFonts.roboto(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _temperaturaSalidaController,
                          style: GoogleFonts.roboto(),
                          decoration: const InputDecoration(
                            labelText: 'Temp. Salida (°C) *',
                            prefixIcon: Icon(Icons.thermostat, color: primaryColor),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // RESPONSABLE DE TRANSPORTE
                  TextFormField(
                    controller: _responsableTransporteController,
                    style: GoogleFonts.roboto(),
                    decoration: const InputDecoration(
                      labelText: 'Responsable de Transporte *',
                      prefixIcon: Icon(Icons.local_shipping, color: primaryColor),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // INFORMACIÓN DE LLEGADA (OPCIONALES)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Llegada (Opcional)',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: _seleccionarFechaLlegada,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Llegada',
                        prefixIcon: Icon(Icons.calendar_today, color: textSecondaryColor),
                      ),
                      child: Text(
                        _formatearFecha(_fechaLlegada),
                        style: GoogleFonts.roboto(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _seleccionarHoraLlegada,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora Llegada',
                              prefixIcon: Icon(Icons.access_time, color: textSecondaryColor),
                            ),
                            child: Text(
                              _horaLlegadaSeleccionada != null 
                                  ? '${_horaLlegadaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaLlegadaSeleccionada!.minute.toString().padLeft(2, '0')}'
                                  : 'No seleccionada',
                              style: GoogleFonts.roboto(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _temperaturaLlegadaController,
                          style: GoogleFonts.roboto(),
                          decoration: const InputDecoration(
                            labelText: 'Temp. Llegada (°C)',
                            prefixIcon: Icon(Icons.thermostat, color: textSecondaryColor),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // LUGAR DE LLEGADA
                  TextFormField(
                    controller: _lugarLlegadaController,
                    style: GoogleFonts.roboto(),
                    decoration: const InputDecoration(
                      labelText: 'Lugar de Llegada',
                      prefixIcon: Icon(Icons.location_city, color: textSecondaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // RESPONSABLE DE RECEPCIÓN
                  TextFormField(
                    controller: _responsableRecepcionController,
                    style: GoogleFonts.roboto(),
                    decoration: const InputDecoration(
                      labelText: 'Responsable de Recepción',
                      prefixIcon: Icon(Icons.how_to_reg, color: textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observacionesController,
              style: GoogleFonts.roboto(),
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.note, color: textSecondaryColor),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorSede() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _cargandoSedes
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text('Cargando sedes...', style: GoogleFonts.roboto()),
                  ],
                ),
              )
            : _sedes.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('Cargando sedes...', style: GoogleFonts.roboto()),
                  ],
                ),
              )
            : _sedes.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
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
                    decoration: const InputDecoration(
                      labelText: 'Sede *',
                      prefixIcon: Icon(Icons.business, color: primaryColor),
                    ),
                    hint: const Text('Seleccione una sede'),
                    items: _sedes.map((sede) {
                      return DropdownMenuItem<String>(
                        value: sede['id'].toString(),
                        child: Text(
                          sede['nombresede']?.toString() ?? 'Sin nombre',
                        ),
                      );
                    }).toList(),
                    onChanged: (String? nuevaSede) {
                      setState(() {
                        _sedeSeleccionada = nuevaSede;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
      ],
    );
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
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (_detalles.isEmpty)
                  TextButton.icon(
                    onPressed: _agregarMuestra,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar muestra'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_detalles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2), style: BorderStyle.solid, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.science_outlined, size: 48, color: primaryColor.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No hay muestras agregadas',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona + para agregar',
                      style: GoogleFonts.roboto(
                        color: primaryColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
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
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${detalle.numeroOrden}',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muestra #${detalle.numeroOrden}',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (pacienteInfo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'CC: ${pacienteInfo.identificacion}',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: textSecondaryColor,
                          ),
                        ),
                        Text(
                          '${pacienteInfo.nombre} ${pacienteInfo.apellido}',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: textSecondaryColor,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Paciente no encontrado',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                  onPressed: () => _eliminarMuestra(index),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            if (detalle.dm?.isNotEmpty == true || detalle.hta?.isNotEmpty == true || detalle.numMuestrasEnviadas?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (detalle.dm?.isNotEmpty == true || detalle.hta?.isNotEmpty == true)
                    Chip(
                      label: Text(
                        'Dx: ${[detalle.dm, detalle.hta].where((e) => e?.isNotEmpty == true).join(', ')}',
                        style: GoogleFonts.roboto(fontSize: 12),
                      ),
                      backgroundColor: Colors.orange[50],
                      avatar: Icon(Icons.medical_services, size: 16, color: Colors.orange[700]),
                    ),
                  if (detalle.numMuestrasEnviadas?.isNotEmpty == true)
                    Chip(
                      label: Text(
                        '# Muestras: ${detalle.numMuestrasEnviadas}',
                        style: GoogleFonts.roboto(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[50],
                      avatar: Icon(Icons.science, size: 16, color: Colors.blue[700]),
                    ),
                ],
              ),
            ],
          ],
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
    
    // ✅ RECARGAR PACIENTES AL VOLVER (por si se creó uno nuevo)
    await _cargarPacientes();
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
