// views/encuesta_view.dart
import 'package:flutter/material.dart';
import 'package:Bornive/models/encuesta_model.dart';
import 'package:Bornive/models/paciente_model.dart';
import 'package:Bornive/services/encuesta_service.dart';
import 'package:Bornive/database/database_helper.dart';
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
  String? _selectedSedeId;
  String? _userSedeId;
  String? _userSedeNombre;
  List<Map<String, dynamic>> _sedes = [];
  bool _loadingSedes = true;

  // 🎨 TEMA DE COLORES UNIFICADO
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryLightColor = Color(0xFF5E92F3);
  static const Color primaryDarkColor = Color(0xFF003C8F);
  static const Color accentColor = Color(0xFF00C853);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

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

  Future<void> _loadUserSede() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getLoggedInUser();
      
      if (user != null && user['sede_id'] != null) {
        final sedeId = user['sede_id'].toString();
        setState(() {
          _userSedeId = sedeId;
          _selectedSedeId = sedeId;
        });
        
        debugPrint('✅ Usuario logueado con sede ID: $sedeId');
        
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
  

  Future<void> _syncPendingEncuestas() async {
    try {
      final token = await _obtenerTokenValido();
      
      if (token == null) {
        _showSnackBar(
          'No hay token de autenticación disponible',
          Icons.warning,
          Colors.orange,
        );
        return;
      }
      
      _showSnackBar(
        'Sincronizando encuestas pendientes...',
        Icons.sync,
        primaryColor,
        showProgress: true,
      );
      
      final resultado = await EncuestaService.sincronizarEncuestasPendientes(token);
      final exitosas = resultado['exitosas'] ?? 0;
      
      _showSnackBar(
        exitosas > 0 
          ? '$exitosas encuestas sincronizadas exitosamente'
          : 'No hay encuestas pendientes por sincronizar',
        exitosas > 0 ? Icons.check_circle : Icons.info,
        exitosas > 0 ? accentColor : primaryColor,
      );
    } catch (e) {
      _showSnackBar(
        'Error en sincronización: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

@override
Widget build(BuildContext context) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      // 🔧 CORRECCIÓN: Usar CardThemeData en lugar de CardTheme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Encuesta de Satisfacción'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: _syncPendingEncuestas,
              tooltip: 'Sincronizar encuestas pendientes',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfo(),
                    const SizedBox(height: 24),
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildCalificationQuestions(),
                    const SizedBox(height: 24),
                    _buildAdditionalQuestions(),
                    const SizedBox(height: 24),
                    _buildSuggestions(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    ),
  );
}

  Widget _buildLoadingState() {
    return Container(
      color: surfaceColor,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Guardando encuesta...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, primaryLightColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.paciente.nombre[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
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
                      const Text(
                        'Información del Paciente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.paciente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${widget.paciente.identificacion}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
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
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Información Básica', Icons.info_outline),
            const SizedBox(height: 24),
            
            _buildSedeField(),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _domicilioController,
              label: 'Domicilio',
              hint: 'Ingrese la dirección del domicilio',
              icon: Icons.home_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese el domicilio';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildDropdownField(
              value: _entidadAfiliada,
              label: 'Entidad Afiliada',
              icon: Icons.business_outlined,
              items: ['ASMET', 'OTRA'],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _entidadAfiliada = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            
            _buildDateField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha de la Encuesta',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: textSecondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeField() {
    if (_loadingSedes) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: const Row(
          children: [
            Icon(Icons.location_city_outlined, color: primaryColor),
            SizedBox(width: 16),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
            ),
            SizedBox(width: 12),
            Text('Cargando sedes disponibles...'),
          ],
        ),
      );
    }

    if (_sedes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange.withOpacity(0.1),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
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
        if (_userSedeNombre != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              border: Border.all(color: accentColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tu sede asignada: $_userSedeNombre',
                  style: const TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        DropdownButtonFormField<String>(
          value: _selectedSedeId,
          decoration: InputDecoration(
            labelText: 'Sede donde se realiza la encuesta',
            hintText: 'Seleccione una sede',
            prefixIcon: const Icon(Icons.location_city_outlined, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            helperText: 'Puede seleccionar cualquier sede disponible',
            helperStyle: const TextStyle(color: textSecondaryColor, fontSize: 12),
          ),
          items: _sedes.map((sede) {
            final sedeId = sede['id'].toString();
            final sedeNombre = sede['nombresede'] ?? 'Sede $sedeId';
            final esSedeUsuario = sedeId == _userSedeId;
            
            return DropdownMenuItem<String>(
              value: sedeId,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: esSedeUsuario ? accentColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      esSedeUsuario ? Icons.person : Icons.business,
                      size: 16,
                      color: esSedeUsuario ? accentColor : primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sedeNombre,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: esSedeUsuario ? FontWeight.w600 : FontWeight.normal,
                        color: esSedeUsuario ? accentColor : textPrimaryColor,
                      ),
                    ),
                  ),
                  if (esSedeUsuario) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Mi sede',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
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
        ),
      ],
    );
  }

  Widget _buildCalificationQuestions() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Califique los servicios recibidos', Icons.star_rate_outlined),
            const SizedBox(height: 8),
            const Text(
              'Seleccione una opción para cada pregunta',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pregunta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Encuesta.opcionesCalificacion.map((opcion) {
              final isSelected = _respuestasCalificacion['pregunta_$index'] == opcion;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _respuestasCalificacion['pregunta_$index'] = isSelected ? '' : opcion;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primaryColor : dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      opcion,
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalQuestions() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Preguntas Adicionales', Icons.help_outline),
            const SizedBox(height: 8),
            const Text(
              'Complete las siguientes preguntas específicas',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildAdditionalQuestion(
              0,
              Encuesta.preguntasAdicionales[0],
              Encuesta.opcionesEntendimiento,
            ),
            _buildAdditionalQuestion(
              1,
              Encuesta.preguntasAdicionales[1],
              Encuesta.opcionesCaracteristicas,
            ),
            _buildAdditionalQuestion(
                           2,
              Encuesta.preguntasAdicionales[2],
              Encuesta.opcionesRecomendacion,
            ),
            _buildAdditionalQuestion(
              3,
              Encuesta.preguntasAdicionales[3],
              Encuesta.opcionesSiNo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalQuestion(int index, String pregunta, List<String> opciones) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pregunta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opciones.map((opcion) {
              final isSelected = _respuestasAdicionales['pregunta_$index'] == opcion;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _respuestasAdicionales['pregunta_$index'] = isSelected ? '' : opcion;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? accentColor : accentColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      opcion,
                      style: TextStyle(
                        color: isSelected ? Colors.white : accentColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Sugerencias (Opcional)', Icons.comment_outlined),
            const SizedBox(height: 8),
            const Text(
              'Comparta sus comentarios o sugerencias adicionales',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _sugerenciasController,
              decoration: InputDecoration(
                hintText: 'Escriba aquí sus comentarios, sugerencias o cualquier observación adicional...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, primaryLightColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitEncuesta,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      SizedBox(width: 16),
                      Text(
                        'Guardando encuesta...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Guardar Encuesta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
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
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
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
    _showSnackBar(message, Icons.warning_rounded, Colors.orange);
  }

  void _showSnackBar(String message, IconData icon, Color color, {bool showProgress = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showProgress) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              Icon(icon, color: Colors.white, size: 20),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: showProgress ? 2 : 4),
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
      // Debug temporal
      debugPrint('🔍 === DEBUGGING RESPUESTAS ===');
      debugPrint('📊 Respuestas Calificación:');
      _respuestasCalificacion.forEach((key, value) {
        debugPrint('   $key: "$value" (${value.runtimeType})');
      });
      
      debugPrint('📊 Respuestas Adicionales:');
      _respuestasAdicionales.forEach((key, value) {
        debugPrint('   $key: "$value" (${value.runtimeType})');
      });

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

      // Obtener token
      String? token = await _obtenerTokenValido();
      
      debugPrint('🔍 Token obtenido para encuesta: ${token != null ? "Disponible (${token.length} chars)" : "No disponible"}');

      // Guardar encuesta
      final success = await EncuestaService.guardarEncuesta(encuesta, token);

      if (success) {
        final mensaje = token != null 
            ? 'Encuesta guardada y sincronizada exitosamente'
            : 'Encuesta guardada localmente (se sincronizará cuando haya conexión)';
        
        final color = token != null ? accentColor : Colors.orange[600]!;
        final icon = token != null ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded;
        
        _showSnackBar(mensaje, icon, color);
        
        // Mostrar diálogo de confirmación antes de salir
        await _showSuccessDialog(sedeSeleccionada['nombresede'], token != null);
        
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar('Error al guardar la encuesta. Intente nuevamente.', Icons.error_rounded, Colors.red);
      }
    } catch (e) {
      debugPrint('❌ Error al guardar encuesta: $e');
      _showSnackBar('Error inesperado: ${e.toString()}', Icons.error_rounded, Colors.red);
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  (sincronizada ? accentColor : Colors.orange[400]!).withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de éxito
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: sincronizada 
                        ? [accentColor, accentColor.withOpacity(0.8)]
                        : [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: (sincronizada ? accentColor : Colors.orange[400]!).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    sincronizada ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                Text(
                  sincronizada ? '¡Encuesta Sincronizada!' : '¡Encuesta Guardada!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Descripción
                Text(
                  sincronizada 
                    ? 'La encuesta ha sido guardada y sincronizada exitosamente con el servidor.'
                    : 'La encuesta ha sido guardada localmente y se sincronizará automáticamente cuando haya conexión a internet.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: textSecondaryColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Información detallada
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (sincronizada ? accentColor : Colors.orange[400]!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (sincronizada ? accentColor : Colors.orange[400]!).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person_outline, 'Paciente', widget.paciente.nombreCompleto, sincronizada),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_city_outlined, 'Sede', nombreSede, sincronizada),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today_outlined, 
                        'Fecha', 
                        '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                        sincronizada,
                      ),
                      
                      if (!sincronizada) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Se sincronizará automáticamente cuando detecte conexión a internet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón de continuar
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: sincronizada 
                        ? [accentColor, accentColor.withOpacity(0.8)]
                        : [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (sincronizada ? accentColor : Colors.orange[400]!).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool sincronizada) {
    return Row(
      children: [
        Icon(
          icon,
          color: sincronizada ? accentColor : Colors.orange[600],
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: textPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _domicilioController.dispose();
    _sugerenciasController.dispose();
    super.dispose();
  }
}
