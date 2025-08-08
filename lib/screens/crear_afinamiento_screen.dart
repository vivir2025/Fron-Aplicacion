// lib/screens/crear_afinamiento_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/afinamiento_model.dart';
import '../models/paciente_model.dart';
import '../services/afinamiento_service.dart';
import '../database/database_helper.dart';
import '../widgets/paciente_selector_widget.dart';

class CrearAfinamientoScreen extends StatefulWidget {
  final Afinamiento? afinamientoExistente;
  final String? pacienteId;

  const CrearAfinamientoScreen({
    Key? key,
    this.afinamientoExistente,
    this.pacienteId,
  }) : super(key: key);

  @override
  State<CrearAfinamientoScreen> createState() => _CrearAfinamientoScreenState();
}

class _CrearAfinamientoScreenState extends State<CrearAfinamientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controladores de texto
  final _procedenciaController = TextEditingController();
  final _presionArterialTamizController = TextEditingController();
  final _conductaController = TextEditingController();
  
  // Controladores para primer afinamiento
  final _presionSistolica1Controller = TextEditingController();
  final _presionDiastolica1Controller = TextEditingController();
  
  // Controladores para segundo afinamiento
  final _presionSistolica2Controller = TextEditingController();
  final _presionDiastolica2Controller = TextEditingController();
  
  // Controladores para tercer afinamiento
  final _presionSistolica3Controller = TextEditingController();
  final _presionDiastolica3Controller = TextEditingController();

  // Variables de estado
  Paciente? _pacienteSeleccionado;
  DateTime _fechaTamizaje = DateTime.now();
  DateTime? _primerAfinamientoFecha;
  DateTime? _segundoAfinamientoFecha;
  DateTime? _tercerAfinamientoFecha;
  
  bool _isLoading = false;
  bool _isEditing = false;
  String? _usuarioId;

  // Variables para mostrar promedios calculados
  double? _promedioSistolica;
  double? _promedioDiastolica;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Obtener usuario actual
    final usuario = await DatabaseHelper.instance.getLoggedInUser();
    if (usuario != null) {
      _usuarioId = usuario['id'];
    }

    // Si hay un afinamiento existente, cargar datos
    if (widget.afinamientoExistente != null) {
      _isEditing = true;
      await _cargarDatosExistentes();
    }

    // Si hay un paciente preseleccionado, cargarlo
    if (widget.pacienteId != null) {
      final paciente = await DatabaseHelper.instance.getPacienteById(widget.pacienteId!);
      if (paciente != null) {
        setState(() {
          _pacienteSeleccionado = paciente;
        });
      }
    }
  }

  Future<void> _cargarDatosExistentes() async {
    final afinamiento = widget.afinamientoExistente!;
    
    // Cargar paciente
    final paciente = await DatabaseHelper.instance.getPacienteById(afinamiento.idpaciente);
    if (paciente != null) {
      _pacienteSeleccionado = paciente;
    }
    
    // Cargar datos del formulario
    _procedenciaController.text = afinamiento.procedencia;
    _presionArterialTamizController.text = afinamiento.presionArterialTamiz;
    _conductaController.text = afinamiento.conducta ?? '';
    
    _fechaTamizaje = afinamiento.fechaTamizaje;
    _primerAfinamientoFecha = afinamiento.primerAfinamientoFecha;
    _segundoAfinamientoFecha = afinamiento.segundoAfinamientoFecha;
    _tercerAfinamientoFecha = afinamiento.tercerAfinamientoFecha;
    
    if (afinamiento.presionSistolica1 != null) {
      _presionSistolica1Controller.text = afinamiento.presionSistolica1.toString();
    }
    if (afinamiento.presionDiastolica1 != null) {
      _presionDiastolica1Controller.text = afinamiento.presionDiastolica1.toString();
    }
    
    if (afinamiento.presionSistolica2 != null) {
      _presionSistolica2Controller.text = afinamiento.presionSistolica2.toString();
    }
    if (afinamiento.presionDiastolica2 != null) {
      _presionDiastolica2Controller.text = afinamiento.presionDiastolica2.toString();
    }
    
    if (afinamiento.presionSistolica3 != null) {
      _presionSistolica3Controller.text = afinamiento.presionSistolica3.toString();
    }
    if (afinamiento.presionDiastolica3 != null) {
      _presionDiastolica3Controller.text = afinamiento.presionDiastolica3.toString();
    }

    _calcularPromedios();
    setState(() {}); // Actualizar UI
  }

  void _calcularPromedios() {
    List<int> sistolicas = [];
    List<int> diastolicas = [];
    
    // Recopilar valores válidos
    if (_presionSistolica1Controller.text.isNotEmpty) {
      final valor = int.tryParse(_presionSistolica1Controller.text);
      if (valor != null) sistolicas.add(valor);
    }
    if (_presionSistolica2Controller.text.isNotEmpty) {
      final valor = int.tryParse(_presionSistolica2Controller.text);
      if (valor != null) sistolicas.add(valor);
    }
    if (_presionSistolica3Controller.text.isNotEmpty) {
      final valor = int.tryParse(_presionSistolica3Controller.text);
      if (valor != null) sistolicas.add(valor);
    }
    
    if (_presionDiastolica1Controller.text.isNotEmpty) {
      final valor = int.tryParse(_presionDiastolica1Controller.text);
      if (valor != null) diastolicas.add(valor);
    }
    if (_presionDiastolica2Controller.text.isNotEmpty) {
      final valor = int.tryParse(_presionDiastolica2Controller.text);
      if (valor != null) diastolicas.add(valor);
    }
    if (_presionDiastolica3Controller.text.isNotEmpty) {
      final valor = int.tryParse(_presionDiastolica3Controller.text);
      if (valor != null) diastolicas.add(valor);
    }
    
    setState(() {
      _promedioSistolica = sistolicas.isNotEmpty 
          ? sistolicas.reduce((a, b) => a + b) / sistolicas.length 
          : null;
      _promedioDiastolica = diastolicas.isNotEmpty 
          ? diastolicas.reduce((a, b) => a + b) / diastolicas.length 
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Afinamiento' : 'Nuevo Afinamiento'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmarEliminacion,
              tooltip: 'Eliminar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de paciente
              _buildSeccionPaciente(),
              
              const SizedBox(height: 24),
              
              // Información del tamizaje
              _buildSeccionTamizaje(),
              
              const SizedBox(height: 24),
              
              // Afinamientos
              _buildSeccionAfinamientos(),
              
              const SizedBox(height: 24),
              
              // Promedios calculados
              if (_promedioSistolica != null && _promedioDiastolica != null)
                _buildSeccionPromedios(),
              
              const SizedBox(height: 24),
              
              // Conducta
              _buildSeccionConducta(),
              
              const SizedBox(height: 32),
              
              // Botones de acción
              _buildBotonesAccion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionPaciente() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_pacienteSeleccionado == null)
              PacienteSelectorWidget(
                onPacienteSelected: (paciente) {
                  setState(() {
                    _pacienteSeleccionado = paciente;
                  });
                },
                enabled: !_isEditing, // No permitir cambiar paciente al editar
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pacienteSeleccionado!.nombreCompleto,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'ID: ${_pacienteSeleccionado!.identificacion}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.change_circle),
                        onPressed: () {
                          setState(() {
                            _pacienteSeleccionado = null;
                          });
                        },
                        tooltip: 'Cambiar paciente',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTamizaje() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Tamizaje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Procedencia
            TextFormField(
              controller: _procedenciaController,
              decoration: const InputDecoration(
                labelText: 'Procedencia *',
                hintText: 'Ej: Hospital Central, Consulta Externa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La procedencia es requerida';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Fecha de tamizaje - CORREGIDO
            InkWell(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaTamizaje,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                
                if (fecha != null) {
                  setState(() {
                    _fechaTamizaje = fecha;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Tamizaje *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_fechaTamizaje),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Presión arterial del tamizaje
            TextFormField(
              controller: _presionArterialTamizController,
              decoration: const InputDecoration(
                labelText: 'Presión Arterial Tamizaje *',
                hintText: 'Ej: 140/90',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La presión arterial del tamizaje es requerida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionAfinamientos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Afinamientos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Primer afinamiento
            _buildAfinamiento(
              numero: 1,
              fecha: _primerAfinamientoFecha,
              onFechaChanged: (fecha) => setState(() => _primerAfinamientoFecha = fecha),
              sistolicaController: _presionSistolica1Controller,
              diastolicaController: _presionDiastolica1Controller,
            ),
            
            const SizedBox(height: 16),
            
            // Segundo afinamiento
            _buildAfinamiento(
              numero: 2,
              fecha: _segundoAfinamientoFecha,
              onFechaChanged: (fecha) => setState(() => _segundoAfinamientoFecha = fecha),
              sistolicaController: _presionSistolica2Controller,
              diastolicaController: _presionDiastolica2Controller,
            ),
            
            const SizedBox(height: 16),
            
            // Tercer afinamiento
            _buildAfinamiento(
              numero: 3,
              fecha: _tercerAfinamientoFecha,
              onFechaChanged: (fecha) => setState(() => _tercerAfinamientoFecha = fecha),
              sistolicaController: _presionSistolica3Controller,
              diastolicaController: _presionDiastolica3Controller,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfinamiento({
    required int numero,
    required DateTime? fecha,
    required Function(DateTime?) onFechaChanged,
    required TextEditingController sistolicaController,
    required TextEditingController diastolicaController,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Afinamiento $numero',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Fecha del afinamiento - CORREGIDO SIN LOCALE
          InkWell(
            onTap: () async {
              final fechaSeleccionada = await showDatePicker(
                context: context,
                initialDate: fecha ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                // REMOVIDO: locale: const Locale('es', 'ES'),
              );
              
              if (fechaSeleccionada != null) {
                onFechaChanged(fechaSeleccionada);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha Afinamiento $numero',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: fecha != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => onFechaChanged(null),
                      )
                    : null,
              ),
              child: Text(
                fecha != null 
                    ? DateFormat('dd/MM/yyyy').format(fecha)
                    : 'Seleccionar fecha',
                style: TextStyle(
                  fontSize: 16,
                  color: fecha != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Presiones arteriales
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: sistolicaController,
                  decoration: const InputDecoration(
                    labelText: 'Sistólica',
                    hintText: '120',
                    border: OutlineInputBorder(),
                    suffixText: 'mmHg',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: (_) => _calcularPromedios(),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final intValue = int.tryParse(value);
                      if (intValue == null || intValue < 50 || intValue > 300) {
                        return 'Entre 50-300';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: diastolicaController,
                  decoration: const InputDecoration(
                    labelText: 'Diastólica',
                    hintText: '80',
                    border: OutlineInputBorder(),
                    suffixText: 'mmHg',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: (_) => _calcularPromedios(),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final intValue = int.tryParse(value);
                      if (intValue == null || intValue < 30 || intValue > 200) {
                        return 'Entre 30-200';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPromedios() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promedios Calculados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Sistólica',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _promedioSistolica!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        'mmHg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.blue[200],
                  ),
                  Column(
                    children: [
                      Text(
                        'Diastólica',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _promedioDiastolica!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        'mmHg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildSeccionConducta() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conducta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _conductaController,
              decoration: const InputDecoration(
                labelText: 'Conducta a seguir',
                hintText: 'Describa la conducta médica recomendada...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarAfinamiento,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isEditing ? 'Actualizar Afinamiento' : 'Guardar Afinamiento',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _guardarAfinamiento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pacienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un paciente'),
                    backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear o actualizar afinamiento
      final afinamiento = AfinamientoService.crearDesdeFormulario(
        idpaciente: _pacienteSeleccionado!.id,
        idusuario: _usuarioId!,
        procedencia: _procedenciaController.text.trim(),
        fechaTamizaje: _fechaTamizaje,
        presionArterialTamiz: _presionArterialTamizController.text.trim(),
        primerAfinamientoFecha: _primerAfinamientoFecha,
        presionSistolica1: _presionSistolica1Controller.text.isNotEmpty
            ? int.tryParse(_presionSistolica1Controller.text)
            : null,
        presionDiastolica1: _presionDiastolica1Controller.text.isNotEmpty
            ? int.tryParse(_presionDiastolica1Controller.text)
            : null,
        segundoAfinamientoFecha: _segundoAfinamientoFecha,
        presionSistolica2: _presionSistolica2Controller.text.isNotEmpty
            ? int.tryParse(_presionSistolica2Controller.text)
            : null,
        presionDiastolica2: _presionDiastolica2Controller.text.isNotEmpty
            ? int.tryParse(_presionDiastolica2Controller.text)
            : null,
        tercerAfinamientoFecha: _tercerAfinamientoFecha,
        presionSistolica3: _presionSistolica3Controller.text.isNotEmpty
            ? int.tryParse(_presionSistolica3Controller.text)
            : null,
        presionDiastolica3: _presionDiastolica3Controller.text.isNotEmpty
            ? int.tryParse(_presionDiastolica3Controller.text)
            : null,
        conducta: _conductaController.text.trim().isNotEmpty
            ? _conductaController.text.trim()
            : null,
      );

      // Obtener token del usuario
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      final token = usuario?['token'];

      bool success;
      if (_isEditing) {
        final afinamientoActualizado = afinamiento.copyWith(
          id: widget.afinamientoExistente!.id,
        );
        success = await AfinamientoService.actualizarAfinamiento(
          afinamientoActualizado,
          token,
        );
      } else {
        success = await AfinamientoService.guardarAfinamiento(afinamiento, token);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Afinamiento actualizado exitosamente'
                    : 'Afinamiento guardado exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al ${_isEditing ? 'actualizar' : 'guardar'} el afinamiento',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarEliminacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar este afinamiento?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final usuario = await DatabaseHelper.instance.getLoggedInUser();
        final token = usuario?['token'];

        final success = await AfinamientoService.eliminarAfinamiento(
          widget.afinamientoExistente!.id,
          token,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Afinamiento eliminado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar el afinamiento'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _procedenciaController.dispose();
    _presionArterialTamizController.dispose();
    _conductaController.dispose();
    _presionSistolica1Controller.dispose();
    _presionDiastolica1Controller.dispose();
    _presionSistolica2Controller.dispose();
    _presionDiastolica2Controller.dispose();
    _presionSistolica3Controller.dispose();
    _presionDiastolica3Controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
