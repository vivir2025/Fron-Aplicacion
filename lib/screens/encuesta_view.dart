// views/encuesta_view.dart
import 'package:flutter/material.dart';
import 'package:fnpv_app/models/encuesta_model.dart';
import 'package:fnpv_app/models/paciente_model.dart';
import 'package:fnpv_app/services/encuesta_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncuestaView extends StatefulWidget {
  final Paciente paciente;

  const EncuestaView({
    Key? key,
    required this.paciente,
  }) : super(key: key);

  @override
  _EncuestaViewState createState() => _EncuestaViewState();
}

class _EncuestaViewState extends State<EncuestaView> {
  final _formKey = GlobalKey<FormState>();
  final _domicilioController = TextEditingController();
  final _sugerenciasController = TextEditingController();
  
  String _entidadAfiliada = 'ASMET';
  DateTime _fechaSeleccionada = DateTime.now();
  
  // Respuestas de calificación (8 preguntas)
  Map<String, String> _respuestasCalificacion = {};
  
  // Respuestas adicionales (4 preguntas)
  Map<String, String> _respuestasAdicionales = {};
  
  bool _isLoading = false;
  String? _selectedSedeId; // 🆕 Sede seleccionada
  String? _userSedeId; // Sede del usuario logueado
  String? _userSedeNombre; // Nombre de la sede del usuario
  List<Map<String, dynamic>> _sedes = []; // Lista de todas las sedes
  bool _loadingSedes = true; // Estado de carga de sedes

  @override
  void initState() {
    super.initState();
    _loadUserSede();
    _loadSedes();
    _initializeResponses();
  }

  void _initializeResponses() {
    // Inicializar respuestas de calificación
    for (int i = 0; i < Encuesta.preguntasCalificacion.length; i++) {
      _respuestasCalificacion['pregunta_$i'] = '';
    }
    
    // Inicializar respuestas adicionales
    for (int i = 0; i < Encuesta.preguntasAdicionales.length; i++) {
      _respuestasAdicionales['pregunta_$i'] = '';
    }
  }

  // 🆕 Cargar todas las sedes disponibles
  Future<void> _loadSedes() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final sedes = await dbHelper.getSedes();
      
      setState(() {
        _sedes = sedes;
        _loadingSedes = false;
      });
      
      debugPrint('✅ Sedes cargadas: ${sedes.length}');
      for (var sede in sedes) {
        debugPrint('   - ${sede['id']}: ${sede['nombresede']}');
      }
    } catch (e) {
      debugPrint('❌ Error al cargar sedes: $e');
      setState(() {
        _loadingSedes = false;
      });
    }
  }

  // Cargar la sede del usuario logueado
  Future<void> _loadUserSede() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getLoggedInUser();
      
      if (user != null && user['sede_id'] != null) {
        final sedeId = user['sede_id'].toString();
        setState(() {
          _userSedeId = sedeId;
          _selectedSedeId = sedeId; // Pre-seleccionar la sede del usuario
        });
        
        debugPrint('✅ Usuario logueado con sede ID: $sedeId');
        
        // Buscar el nombre de la sede
        final dbHelper = DatabaseHelper.instance;
        final sedes = await dbHelper.getSedes();
        final sede = sedes.firstWhere(
          (s) => s['id'].toString() == sedeId,
          orElse: () => {'nombresede': 'Sede $sedeId'},
        );
        
        setState(() {
          _userSedeNombre = sede['nombresede'];
        });
        
        debugPrint('✅ Nombre de sede del usuario: ${sede['nombresede']}');
      } else {
        debugPrint('⚠️ Usuario sin sede asignada');
      }
    } catch (e) {
      debugPrint('❌ Error al cargar sede del usuario: $e');
    }
  }

  // 🆕 MÉTODO PARA OBTENER TOKEN DE MÚLTIPLES FUENTES
  Future<String?> _obtenerTokenValido() async {
    try {
      // 1. Intentar desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token != null && token.isNotEmpty) {
        debugPrint('✅ Token obtenido desde SharedPreferences');
        return token;
      }
      
      // 2. Intentar desde usuario logueado en DB
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getLoggedInUser();
      token = user?['token'];
      
      if (token != null && token.isNotEmpty) {
        // Guardar en SharedPreferences para próximas veces
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

  // 🆕 MÉTODO PARA SINCRONIZAR MANUALMENTE
  Future<void> _syncPendingEncuestas() async {
    try {
      final token = await _obtenerTokenValido();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Text('No hay token de autenticación disponible'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Sincronizando encuestas pendientes...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Intentar sincronizar
      final resultado = await EncuestaService.sincronizarEncuestasPendientes(token);
      final exitosas = resultado['exitosas'] ?? 0;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                exitosas > 0 ? Icons.check_circle : Icons.info,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                exitosas > 0 
                  ? '$exitosas encuestas sincronizadas exitosamente'
                  : 'No hay encuestas pendientes por sincronizar'
              ),
            ],
          ),
          backgroundColor: exitosas > 0 ? Colors.green : Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error en sincronización: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encuesta de Satisfacción'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncPendingEncuestas,
            tooltip: 'Sincronizar encuestas pendientes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando encuesta...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfo(),
                    const SizedBox(height: 20),
                    _buildBasicInfo(),
                    const SizedBox(height: 20),
                    _buildCalificationQuestions(),
                    const SizedBox(height: 20),
                    _buildAdditionalQuestions(),
                    const SizedBox(height: 20),
                    _buildSuggestions(),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[800],
                  child: Text(
                    widget.paciente.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Paciente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nombre: ${widget.paciente.nombreCompleto}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Identificación: ${widget.paciente.identificacion}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 20),
            
            // 🆕 Campo Sede - COMPLETAMENTE FUNCIONAL
            _buildSedeField(),
            const SizedBox(height: 16),
            
            // Campo Domicilio
            TextFormField(
              controller: _domicilioController,
              decoration: InputDecoration(
                labelText: 'Domicilio',
                hintText: 'Ingrese la dirección del domicilio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.home, color: Colors.blue[700]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese el domicilio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo Entidad Afiliada
            DropdownButtonFormField<String>(
              value: _entidadAfiliada,
              decoration: InputDecoration(
                labelText: 'Entidad Afiliada',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.business, color: Colors.blue[700]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: ['ASMET', 'OTRA'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _entidadAfiliada = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Campo Fecha
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de la Encuesta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[700]),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                child: Text(
                  '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Widget para el campo de sede - COMPLETAMENTE FUNCIONAL
  Widget _buildSedeField() {
    if (_loadingSedes) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.location_city, color: Colors.blue[700]),
            const SizedBox(width: 12),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Cargando sedes disponibles...'),
          ],
        ),
      );
    }

    if (_sedes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange[50],
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No hay sedes disponibles. Contacte al administrador.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de la sede del usuario (si existe)
        if (_userSedeNombre != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tu sede asignada: $_userSedeNombre',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Dropdown de selección de sede
        DropdownButtonFormField<String>(
          value: _selectedSedeId,
          decoration: InputDecoration(
            labelText: 'Sede donde se realiza la encuesta',
            hintText: 'Seleccione una sede',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.location_city, color: Colors.blue[700]),
            filled: true,
            fillColor: Colors.grey[50],
            helperText: 'Puede seleccionar cualquier sede disponible',
            helperStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: _sedes.map((sede) {
            final sedeId = sede['id'].toString();
            final sedeNombre = sede['nombresede'] ?? 'Sede $sedeId';
            final esSedeUsuario = sedeId == _userSedeId;
            
            return DropdownMenuItem<String>(
              value: sedeId,
              child: Row(
                children: [
                  Icon(
                    esSedeUsuario ? Icons.person : Icons.business,
                    size: 18,
                    color: esSedeUsuario ? Colors.green[600] : Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sedeNombre,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: esSedeUsuario ? FontWeight.w600 : FontWeight.normal,
                        color: esSedeUsuario ? Colors.green[700] : null,
                      ),
                    ),
                  ),
                  if (esSedeUsuario) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Mi sede',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSedeId = newValue;
              });
              
              // Encontrar el nombre de la sede seleccionada para logging
              final sedeSeleccionada = _sedes.firstWhere(
                (s) => s['id'].toString() == newValue,
                orElse: () => {'nombresede': 'Sede $newValue'},
              );
              
              debugPrint('✅ Sede seleccionada: ${sedeSeleccionada['nombresede']} (ID: $newValue)');
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione una sede';
            }
            return null;
          },
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
        ),
      ],
    );
  }

  Widget _buildCalificationQuestions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rate, color: Colors.blue[800], size: 28),
                const SizedBox(width: 8),
                Text(
                  'Califique los servicios recibidos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Seleccione una opción para cada pregunta',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ...Encuesta.preguntasCalificacion.asMap().entries.map((entry) {
              int index = entry.key;
              String pregunta = entry.value;
              return _buildCalificationQuestion(index, pregunta);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalificationQuestion(int index, String pregunta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $pregunta',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Encuesta.opcionesCalificacion.map((opcion) {
              final isSelected = _respuestasCalificacion['pregunta_$index'] == opcion;
              return ChoiceChip(
                label: Text(
                  opcion,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue[800],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _respuestasCalificacion['pregunta_$index'] = selected ? opcion : '';
                  });
                },
                selectedColor: Colors.blue[600],
                backgroundColor: Colors.white,
                elevation: isSelected ? 4 : 1,
                pressElevation: 2,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalQuestions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue[800], size: 28),
                const SizedBox(width: 8),
                Text(
                  'Preguntas Adicionales',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complete las siguientes preguntas específicas',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // 🔧 USAR LAS OPCIONES CORRECTAS DEL MODELO
            _buildAdditionalQuestion(
              0,
              Encuesta.preguntasAdicionales[0],
              Encuesta.opcionesEntendimiento, // ✅ 'Si entendí', 'No entendí'
            ),
            _buildAdditionalQuestion(
              1,
              Encuesta.preguntasAdicionales[1],
              Encuesta.opcionesCaracteristicas, // ✅ 'Amabilidad', 'Confianza', 'Agilidad', 'Seguridad', 'Otra'
            ),
            _buildAdditionalQuestion(
              2,
              Encuesta.preguntasAdicionales[2],
              Encuesta.opcionesRecomendacion, // ✅ 'Definitivamente sí', 'Definitivamente no'
            ),
            _buildAdditionalQuestion(
              3,
              Encuesta.preguntasAdicionales[3],
              Encuesta.opcionesSiNo, // ✅ 'Sí', 'No'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalQuestion(int index, String pregunta, List<String> opciones) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $pregunta',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opciones.map((opcion) {
              final isSelected = _respuestasAdicionales['pregunta_$index'] == opcion;
              return ChoiceChip(
                label: Text(
                  opcion,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.green[800],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _respuestasAdicionales['pregunta_$index'] = selected ? opcion : '';
                  });
                },
                selectedColor: Colors.green[600],
                backgroundColor: Colors.white,
                elevation: isSelected ? 4 : 1,
                pressElevation: 2,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: Colors.blue[800], size: 28),
                const SizedBox(width: 8),
                Text(
                  'Sugerencias (Opcional)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Comparta sus comentarios o sugerencias adicionales',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sugerenciasController,
              decoration: InputDecoration(
                hintText: 'Escriba aquí sus comentarios, sugerencias o cualquier observación adicional...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitEncuesta,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                                   SizedBox(width: 12),
                  Text('Guardando encuesta...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Guardar Encuesta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  bool _validateResponses() {
    // Validar que todas las preguntas de calificación estén respondidas
    for (int i = 0; i < Encuesta.preguntasCalificacion.length; i++) {
      if (_respuestasCalificacion['pregunta_$i']?.isEmpty ?? true) {
        _showValidationError('Por favor responda: ${Encuesta.preguntasCalificacion[i]}');
        return false;
      }
    }

    // Validar que todas las preguntas adicionales estén respondidas
    for (int i = 0; i < Encuesta.preguntasAdicionales.length; i++) {
      if (_respuestasAdicionales['pregunta_$i']?.isEmpty ?? true) {
        _showValidationError('Por favor responda: ${Encuesta.preguntasAdicionales[i]}');
        return false;
      }
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _submitEncuesta() async {
    // Validar formulario básico
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que se haya seleccionado una sede
    if (_selectedSedeId == null || _selectedSedeId!.isEmpty) {
      _showValidationError('Por favor seleccione una sede');
      return;
    }

    // Validar respuestas
    if (!_validateResponses()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔧 DEBUG TEMPORAL - Agregar antes de crear la encuesta
      debugPrint('🔍 === DEBUGGING RESPUESTAS ===');
      debugPrint('📊 Respuestas Calificación:');
      _respuestasCalificacion.forEach((key, value) {
        debugPrint('   $key: "$value" (${value.runtimeType})');
      });
      
      debugPrint('📊 Respuestas Adicionales:');
      _respuestasAdicionales.forEach((key, value) {
        debugPrint('   $key: "$value" (${value.runtimeType})');
      });
      
      debugPrint('🔍 === OPCIONES DISPONIBLES EN MODELO ===');
      debugPrint('📊 Calificación: ${Encuesta.opcionesCalificacion}');
      debugPrint('📊 Entendimiento: ${Encuesta.opcionesEntendimiento}');
      debugPrint('📊 Características: ${Encuesta.opcionesCaracteristicas}');
      debugPrint('📊 Recomendación: ${Encuesta.opcionesRecomendacion}');
      debugPrint('📊 Sí/No: ${Encuesta.opcionesSiNo}');

      // Obtener nombre de la sede seleccionada para el mensaje
      final sedeSeleccionada = _sedes.firstWhere(
        (s) => s['id'].toString() == _selectedSedeId,
        orElse: () => {'nombresede': 'Sede $_selectedSedeId'},
      );

      // Crear encuesta
      final encuesta = Encuesta(
        id: EncuestaService.generarIdUnico(),
        idpaciente: widget.paciente.id,
        idsede: _selectedSedeId!,
        domicilio: _domicilioController.text.trim(),
        entidadAfiliada: _entidadAfiliada,
        fecha: _fechaSeleccionada,
        respuestasCalificacion: Map<String, String>.from(_respuestasCalificacion),
        respuestasAdicionales: Map<String, String>.from(_respuestasAdicionales),
        sugerencias: _sugerenciasController.text.trim().isNotEmpty 
            ? _sugerenciasController.text.trim() 
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 🔧 DEBUG TEMPORAL - Ver qué se va a enviar
      debugPrint('🔍 === JSON PARA SERVIDOR ===');
      final serverJson = encuesta.toServerJson();
      debugPrint('📤 respuestas_calificacion: ${serverJson['respuestas_calificacion']}');
      debugPrint('📤 respuestas_adicionales: ${serverJson['respuestas_adicionales']}');

      // 🆕 OBTENER TOKEN DE MÚLTIPLES FUENTES
      String? token = await _obtenerTokenValido();
      
      debugPrint('🔍 Token obtenido para encuesta: ${token != null ? "Disponible (${token.length} chars)" : "No disponible"}');

      // Guardar encuesta
      final success = await EncuestaService.guardarEncuesta(encuesta, token);

      if (success) {
        // 🆕 MENSAJE DIFERENCIADO SEGÚN DISPONIBILIDAD DE TOKEN
        final mensaje = token != null 
            ? 'Encuesta guardada y sincronizada exitosamente'
            : 'Encuesta guardada localmente (se sincronizará cuando haya conexión)';
        
        final color = token != null ? Colors.green[700] : Colors.orange[700];
        final icon = token != null ? Icons.cloud_done : Icons.cloud_queue;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensaje,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sede: ${sedeSeleccionada['nombresede']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Paciente: ${widget.paciente.nombreCompleto}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (token == null) ...[
                        const Text(
                          'Se sincronizará automáticamente cuando detecte conexión',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Mostrar diálogo de confirmación antes de salir
        await _showSuccessDialog(sedeSeleccionada['nombresede'], token != null);
        
        Navigator.of(context).pop(true);
      } else {
        _showErrorMessage('Error al guardar la encuesta. Intente nuevamente.');
      }
    } catch (e) {
      debugPrint('❌ Error al guardar encuesta: $e');
      _showErrorMessage('Error inesperado: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSuccessDialog(String nombreSede, bool sincronizada) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: sincronizada ? Colors.green[100] : Colors.orange[100],
                child: Icon(
                  sincronizada ? Icons.cloud_done : Icons.cloud_queue,
                  color: sincronizada ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(sincronizada ? '¡Encuesta Sincronizada!' : '¡Encuesta Guardada!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sincronizada 
                  ? 'La encuesta ha sido guardada y sincronizada exitosamente con el servidor.'
                  : 'La encuesta ha sido guardada localmente y se sincronizará automáticamente cuando haya conexión a internet.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sincronizada ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sincronizada ? Colors.green[200]! : Colors.orange[200]!
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, 
                          color: sincronizada ? Colors.green[700] : Colors.orange[700], 
                          size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Paciente: ${widget.paciente.nombreCompleto}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_city, 
                          color: sincronizada ? Colors.green[700] : Colors.orange[700], 
                          size: 16),
                        const SizedBox(width: 6),
                        Text('Sede: $nombreSede'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, 
                          color: sincronizada ? Colors.green[700] : Colors.orange[700], 
                          size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Fecha: ${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                        ),
                      ],
                    ),
                    if (!sincronizada) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, 
                              color: Colors.orange[700], 
                              size: 16),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Se sincronizará automáticamente cuando detecte conexión a internet',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Continuar',
                style: TextStyle(
                  color: sincronizada ? Colors.green[800] : Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () {
            _submitEncuesta();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _domicilioController.dispose();
    _sugerenciasController.dispose();
    super.dispose();
  }
}
