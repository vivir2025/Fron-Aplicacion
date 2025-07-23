import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fnpv_app/models/medicamento_con_indicaciones.dart';
import 'package:fnpv_app/services/medicamento_service.dart';
import 'package:fnpv_app/widgets/medicamentos_selector.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../models/paciente_model.dart';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../services/sincronizacion_service.dart';
import '../services/file_service.dart';
import '../api/visita_service.dart';

class VisitasFormScreen extends StatefulWidget {
  final ThemeData theme;
  final Visita? visitaToEdit;
  final VoidCallback? onVisitaSaved;

  const VisitasFormScreen({
    Key? key,
    required this.theme,
    this.visitaToEdit,
    this.onVisitaSaved,
  }) : super(key: key);

  @override
  State<VisitasFormScreen> createState() => _VisitasFormScreenState();
}

class _VisitasFormScreenState extends State<VisitasFormScreen> {
  // Controladores del formulario básicos
  final _formKey = GlobalKey<FormState>();
  final _identificacionController = TextEditingController();
  final _nombreApellidoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _fechaVisitaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _htaController = TextEditingController();
  final _dmController = TextEditingController();
  final _zonaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _tallaController = TextEditingController();
  final _perimetroAbdominalController = TextEditingController();
  final _frecuenciaCardiacaController = TextEditingController();
  final _frecuenciaRespiratoriaController = TextEditingController();
  final _tensionArterialController = TextEditingController();
  final _glucometriaController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _novedadesController = TextEditingController();
  final _proximoControlController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();

  // Variables de estado
  bool _showGeolocalizacion = false;
  bool _isGettingLocation = false;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentVisitaId;
  double? _imcValue;
  int? _edad;
  Paciente? _currentPaciente;

  // Nuevas variables para los campos actualizados
  String? _familiar; // "Si" o "No"
  String? _abandonoSocial; // "Si" o "No"
  List<String> _motivosNoAsistencia = []; // Múltiple selección
  List<String> _factoresRiesgo = []; // Múltiple selección
  List<String> _conductas = []; // Múltiple selección
   // 🆕 Variables para medicamentos
  List<MedicamentoConIndicaciones> _selectedMedicamentos = [];
  

  // ✅ VARIABLES ACTUALIZADAS PARA ARCHIVOS
  File? _fotoRiesgo;
  String? _fotoRiesgoPath; // Path local del archivo
  String? _firmaPath; // Path local de la firma
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // Opciones predefinidas
  final List<String> _opcionesMotivosNoAsistencia = [
    'Solo',
    'Enfermo', 
    'No quiere',
    'Olvido',
    'Tratamiento Alternativo',
    'Tiene medicamentos'
  ];

  final List<String> _opcionesFactoresRiesgo = [
    'Dolor de cabeza',
    'Nauseas',
    'Mareos',
    'Cambio de vision',
    'Sangrado nasal',
    'Hinchazon de pies',
    'Ganas de orinar constante',
    'Cansancio o Debilidad'
  ];

  final List<String> _opcionesConductas = [
    'Educacion',
    'Alimentacion',
    'Actividad fisica',
    'Tratamiento Farmacologico'
  ];

  @override
  void initState() {
    super.initState();
    _fechaVisitaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (widget.visitaToEdit != null) {
      _loadVisitaForEdit(widget.visitaToEdit!);
    }

       // Cargar medicamentos disponibles
    _loadMedicamentosIfNeeded();
  }

  @override
  void dispose() {
    // Dispose de todos los controladores
    _identificacionController.dispose();
    _nombreApellidoController.dispose();
    _fechaNacimientoController.dispose();
    _fechaVisitaController.dispose();
    _telefonoController.dispose();
    _htaController.dispose();
    _dmController.dispose();
    _zonaController.dispose();
    _pesoController.dispose();
    _tallaController.dispose();
    _perimetroAbdominalController.dispose();
    _frecuenciaCardiacaController.dispose();
    _frecuenciaRespiratoriaController.dispose();
    _tensionArterialController.dispose();
    _glucometriaController.dispose();
    _temperaturaController.dispose();
    _novedadesController.dispose();
    _proximoControlController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
    Future<void> _loadMedicamentosIfNeeded() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      // Intentar cargar medicamentos desde servidor si hay conexión
      await MedicamentoService.ensureMedicamentosLoaded(token);
    } catch (e) {
      debugPrint('⚠️ Error cargando medicamentos iniciales: $e');
    }
  }
void _loadVisitaForEdit(Visita visita) async {
    setState(() {
      _isEditing = true;
      _currentVisitaId = visita.id;
      _identificacionController.text = visita.identificacion;
      _nombreApellidoController.text = visita.nombreApellido;
      _fechaVisitaController.text = DateFormat('yyyy-MM-dd').format(visita.fecha);
      _telefonoController.text = visita.telefono ?? '';
      _htaController.text = visita.hta ?? '';
      _dmController.text = visita.dm ?? '';
      _zonaController.text = visita.zona ?? '';
      _pesoController.text = visita.peso?.toString() ?? '';
      _tallaController.text = visita.talla?.toString() ?? '';
      _imcValue = visita.imc;
      _perimetroAbdominalController.text = visita.perimetroAbdominal?.toString() ?? '';
      _frecuenciaCardiacaController.text = visita.frecuenciaCardiaca?.toString() ?? '';
      _frecuenciaRespiratoriaController.text = visita.frecuenciaRespiratoria?.toString() ?? '';
      _tensionArterialController.text = visita.tensionArterial ?? '';
      _glucometriaController.text = visita.glucometria?.toString() ?? '';
      _temperaturaController.text = visita.temperatura?.toString() ?? '';

      // Cargar nuevos campos
      _familiar = visita.familiar;
      _abandonoSocial = visita.abandonoSocial;
      
      // Cargar listas de selección múltiple
      if (visita.motivo != null && visita.motivo!.isNotEmpty) {
        _motivosNoAsistencia = visita.motivo!.split(',').map((e) => e.trim()).toList();
      }
      if (visita.factores != null && visita.factores!.isNotEmpty) {
        _factoresRiesgo = visita.factores!.split(',').map((e) => e.trim()).toList();
      }
      if (visita.conductas != null && visita.conductas!.isNotEmpty) {
        _conductas = visita.conductas!.split(',').map((e) => e.trim()).toList();
      }
      
      _novedadesController.text = visita.novedades ?? '';
      _proximoControlController.text = visita.proximoControl != null
          ? DateFormat('yyyy-MM-dd').format(visita.proximoControl!)
          : '';
      
      // ✅ CARGAR ARCHIVOS EXISTENTES
      _firmaPath = visita.firma;
      _fotoRiesgoPath = visita.riesgoFotografico;
      if (_fotoRiesgoPath != null && _fotoRiesgoPath!.isNotEmpty) {
        _fotoRiesgo = File(_fotoRiesgoPath!);
      }
      
      _latitudController.text = visita.latitud?.toString() ?? '';
      _longitudController.text = visita.longitud?.toString() ?? '';
    });

    // 🆕 Cargar medicamentos de la visita
    try {
      final dbHelper = DatabaseHelper.instance;
      _selectedMedicamentos = await dbHelper.getMedicamentosDeVisita(visita.id);
      debugPrint('📋 ${_selectedMedicamentos.length} medicamentos cargados para edición');
    } catch (e) {
      debugPrint('❌ Error cargando medicamentos de visita: $e');
    }

    try {
      final dbHelper = DatabaseHelper.instance;
      final paciente = await dbHelper.getPacienteById(visita.idpaciente);
      if (paciente != null) {
        setState(() {
          _currentPaciente = paciente;
          _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(paciente.fecnacimiento);
        });
        _updateEdad();
      }
    } catch (e) {
      debugPrint('Error al obtener datos completos del paciente: $e');
    }
    _calculateIMC();
  }
  // ✅ MÉTODO MEJORADO PARA TOMAR FOTO
  Future<void> _tomarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (photo != null) {
        // 🆕 Usar FileService para guardar la foto
        final visitaId = _currentVisitaId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final savedPath = await FileService.saveRiskPhoto(File(photo.path), visitaId);
        
        if (savedPath != null) {
          setState(() {
            _fotoRiesgo = File(savedPath);
            _fotoRiesgoPath = savedPath;
          });
          
          debugPrint('✅ Foto guardada en: $savedPath');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto capturada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('No se pudo guardar la foto');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al tomar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ MÉTODO MEJORADO PARA MANEJAR FIRMA
  void _mostrarDialogoFirma() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firma'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _signatureController.clear();
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_signatureController.isNotEmpty) {
                await _guardarFirma();
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, agregue una firma')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO MEJORADO PARA GUARDAR FIRMA
  Future<void> _guardarFirma() async {
    try {
      final Uint8List? signature = await _signatureController.toPngBytes();
      if (signature != null) {
        // 🆕 Usar FileService para guardar la firma
        final visitaId = _currentVisitaId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final savedPath = await FileService.saveSignature(signature, visitaId);
        
        if (savedPath != null) {
          setState(() {
            _firmaPath = savedPath;
          });
          
          debugPrint('✅ Firma guardada en: $savedPath');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firma guardada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('No se pudo guardar la firma');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al guardar firma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar firma: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Resto de métodos existentes (searchPaciente, updateEdad, calculateIMC, etc.)
  Future<void> _searchPaciente() async {
    final identificacion = _identificacionController.text.trim();
    if (identificacion.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final paciente = await dbHelper.getPacienteByIdentificacion(identificacion);
      
      if (paciente != null) {
        setState(() {
          _currentPaciente = paciente;
          _nombreApellidoController.text = paciente.nombreCompleto;
          _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(paciente.fecnacimiento);
          
          if (paciente.latitud != null && paciente.longitud != null) {
            _latitudController.text = paciente.latitud!.toString();
            _longitudController.text = paciente.longitud!.toString();
          } else {
            _latitudController.clear();
            _longitudController.clear();
          }
        });
        _updateEdad();
        
        debugPrint('Paciente cargado - Lat: ${paciente.latitud}, Lng: ${paciente.longitud}');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente no encontrado')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al buscar paciente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateEdad() {
    if (_fechaNacimientoController.text.isEmpty) return;
    try {
      final birthday = DateTime.parse(_fechaNacimientoController.text);
      final today = DateTime.now();
      int age = today.year - birthday.year;
      if (today.month < birthday.month ||
          (today.month == birthday.month && today.day < birthday.day)) {
        age--;
      }
      setState(() => _edad = age);
    } catch (_) {
      setState(() => _edad = null);
    }
  }

  void _calculateIMC() {
    final peso = double.tryParse(_pesoController.text);
    final talla = double.tryParse(_tallaController.text);
    if (peso != null && talla != null && talla > 0) {
      setState(() {
        _imcValue = peso / ((talla / 100) * (talla / 100));
      });
    } else {
      setState(() => _imcValue = null);
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isNacimiento = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: widget.theme.copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF2E7D32),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (isNacimiento) _updateEdad();
      });
    }
  }

  // Métodos de geolocalización
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los servicios de ubicación están desactivados')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los permisos de ubicación fueron denegados permanentemente')),
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los permisos de ubicación fueron denegados')),
          );
        }
        return false;
      }
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitudController.text = position.latitude.toString();
        _longitudController.text = position.longitude.toString();
      });

      if (_currentPaciente == null || _identificacionController.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Primero busque un paciente para guardar la ubicación')),
          );
        }
        return;
      }

      final updated = await DatabaseHelper.instance.updatePacienteGeolocalizacion(
        _currentPaciente!.id,
        position.latitude,
        position.longitude,
      );

      if (updated > 0) {
        _currentPaciente = _currentPaciente!.copyWith(
          latitud: position.latitude,
          longitud: position.longitude,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ubicación guardada para el paciente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar la ubicación')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _clearGeolocalizacion() {
    setState(() {
      _latitudController.clear();
      _longitudController.clear();
    });
    
    if (_currentPaciente != null) {
      DatabaseHelper.instance.updatePacienteGeolocalizacion(
        _currentPaciente!.id,
        0.0,
        0.0,
      ).then((_) {
        _currentPaciente = _currentPaciente!.copyWith(
          latitud: null,
          longitud: null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ubicación eliminada')),
          );
        }
      });
    }
  }

  // 🆕 Método para guardar medicamentos
  Future<void> _saveMedicamentosVisita(String visitaId) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.saveMedicamentosVisita(visitaId, _selectedMedicamentos);
      debugPrint('✅ Medicamentos guardados para visita $visitaId');
    } catch (e) {
      debugPrint('❌ Error guardando medicamentos: $e');
    }
  }

 // ✅ MÉTODO PRINCIPAL ACTUALIZADO - CON MANEJO DE MODO OFFLINE COMPLETO
Future<void> _saveVisita() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_currentPaciente == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debe buscar un paciente primero')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = await authProvider.getCurrentUserId();
    final token = authProvider.token;

    if (userId == null) {
      throw Exception('No se pudo obtener el ID del usuario. Vuelva a iniciar sesión.');
    }

    // ✅ 1. Preparar medicamentos ANTES de crear la visita (CORREGIDO)
    List<Map<String, dynamic>> medicamentosData = [];
    for (var medicamentoConIndicaciones in _selectedMedicamentos) {
      if (medicamentoConIndicaciones.isSelected) {
        // 🆕 ASEGURAR QUE TODOS LOS CAMPOS SEAN STRING
        medicamentosData.add({
          'id': medicamentoConIndicaciones.medicamento.id.toString(),
          'nombre': medicamentoConIndicaciones.medicamento.nombmedicamento.toString(),
          'indicaciones': (medicamentoConIndicaciones.indicaciones ?? '').toString(),
        });
      }
    }

    debugPrint('💊 Medicamentos preparados para envío: ${medicamentosData.length}');
    for (var med in medicamentosData) {
      debugPrint('  - ${med['nombre']}: ${med['indicaciones']}');
    }

    // ✅ 2. Actualizar geolocalización del paciente si es necesario
    if (_latitudController.text.isNotEmpty && _longitudController.text.isNotEmpty) {
      final lat = double.tryParse(_latitudController.text);
      final lng = double.tryParse(_longitudController.text);
      
      if (lat != null && lng != null) {
        await DatabaseHelper.instance.updatePacienteGeolocalizacion(
          _currentPaciente!.id,
          lat,
          lng,
        );
        
        _currentPaciente = _currentPaciente!.copyWith(
          latitud: lat,
          longitud: lng,
        );
      }
    }

    // ✅ 3. Preparar ID de visita
    final visitaId = _currentVisitaId ?? VisitaService.generateId();
    
    // ✅ 4. VERIFICAR CONEXIÓN A INTERNET - VERSIÓN MEJORADA
    bool isConnected = false;
    String connectionStatus = '';

    try {
      debugPrint('🔍 Verificando conexión a internet...');
      
      // Paso 1: Verificar conectividad básica
      final List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();
      final hasNetworkConnection = connectivityResults.contains(ConnectivityResult.wifi) || 
                                  connectivityResults.contains(ConnectivityResult.mobile);
      
      debugPrint('📶 Conectividad detectada: $connectivityResults');
      
      if (hasNetworkConnection) {
        connectionStatus = 'Red detectada';
        
        // Paso 2: Verificar conexión real a internet
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 8));
          
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            isConnected = true;
            connectionStatus = 'Conexión confirmada';
            debugPrint('✅ Conexión a internet confirmada');
          } else {
            connectionStatus = 'Sin acceso a internet';
            debugPrint('⚠️ Red detectada pero sin acceso a internet');
          }
        } catch (lookupError) {
          connectionStatus = 'Error de DNS/conectividad';
          debugPrint('⚠️ Error en lookup DNS: $lookupError');
        }
      } else {
        connectionStatus = 'Sin red disponible';
        debugPrint('📵 Sin conectividad de red detectada');
      }
    } catch (e) {
      connectionStatus = 'Error al verificar conexión';
      debugPrint('❌ Error general al verificar conexión: $e');
      isConnected = false;
    }

    debugPrint('🌐 Estado final de conexión: $connectionStatus (conectado: $isConnected)');

    // Estado de sincronización inicial: no sincronizado
    int syncStatus = 0; 
    
    // ✅ 5. Si hay conexión, intentar sincronizar con el servidor
    if (isConnected && token != null) {
      try {
        debugPrint('🌐 Intentando guardar en servidor...');
        
        // Datos para enviar al servidor
        final visitaData = {
          'id': visitaId,
          'nombre_apellido': _nombreApellidoController.text,
          'identificacion': _identificacionController.text,
          'fecha': _fechaVisitaController.text,
          'idusuario': userId.toString(),
          'idpaciente': _currentPaciente!.id.toString(),
          
          // Campos opcionales
          'hta': _htaController.text.isEmpty ? '' : _htaController.text,
          'dm': _dmController.text.isEmpty ? '' : _dmController.text,
          'telefono': _telefonoController.text.isEmpty ? '' : _telefonoController.text,
          'zona': _zonaController.text.isEmpty ? '' : _zonaController.text,
          'peso': _pesoController.text.isEmpty ? '' : _pesoController.text,
          'talla': _tallaController.text.isEmpty ? '' : _tallaController.text,
          'imc': _imcValue?.toString() ?? '',
          'perimetro_abdominal': _perimetroAbdominalController.text.isEmpty ? '' : _perimetroAbdominalController.text,
          'frecuencia_cardiaca': _frecuenciaCardiacaController.text.isEmpty ? '' : _frecuenciaCardiacaController.text,
          'frecuencia_respiratoria': _frecuenciaRespiratoriaController.text.isEmpty ? '' : _frecuenciaRespiratoriaController.text,
          'tension_arterial': _tensionArterialController.text.isEmpty ? '' : _tensionArterialController.text,
          'glucometria': _glucometriaController.text.isEmpty ? '' : _glucometriaController.text,
          'temperatura': _temperaturaController.text.isEmpty ? '' : _temperaturaController.text,
          'familiar': _familiar ?? '',
          'abandono_social': _abandonoSocial ?? '',
          'motivo': _motivosNoAsistencia.isEmpty ? '' : _motivosNoAsistencia.join(', '),
          'factores': _factoresRiesgo.isEmpty ? '' : _factoresRiesgo.join(', '),
          'conductas': _conductas.isEmpty ? '' : _conductas.join(', '),
          'novedades': _novedadesController.text.isEmpty ? '' : _novedadesController.text,
          'proximo_control': _proximoControlController.text.isEmpty ? '' : _proximoControlController.text,
        };
        
        Map<String, dynamic>? resultado;
        
        if (_isEditing) {
          // ACTUALIZAR VISITA EXISTENTE
          resultado = await FileService.updateVisitaCompleta(
            visitaId: visitaId,
            visitaData: visitaData,
            token: token,
            riskPhotoPath: _fotoRiesgoPath,
            signaturePath: _firmaPath,
            medicamentosData: medicamentosData, // 🆕 Incluir medicamentos
          );
        } else {
          // CREAR NUEVA VISITA
          resultado = await FileService.createVisitaCompleta(
            visitaData: visitaData,
            token: token,
            riskPhotoPath: _fotoRiesgoPath,
            signaturePath: _firmaPath,
            medicamentosData: medicamentosData, // 🆕 Incluir medicamentos
          );
        }

        if (resultado != null && resultado['success'] == true) {
          // Si se guardó correctamente, actualizar estado de sincronización
          syncStatus = 1; // Sincronizado
          debugPrint('✅ Guardado en servidor exitoso');
        } else {
          throw Exception(resultado?['error'] ?? 'Error desconocido al guardar en servidor');
        }
      } catch (e) {
        debugPrint('⚠️ Error al guardar en servidor: $e');
        // Si falla, continuar con guardado local solamente
        syncStatus = 0; // No sincronizado
      }
    } else {
      debugPrint('📵 Sin conexión a internet, guardando localmente...');
    }

    // ✅ 6. SIEMPRE guardar en base de datos local
    final visita = Visita(
      id: visitaId,
      nombreApellido: _nombreApellidoController.text,
      identificacion: _identificacionController.text,
      hta: _htaController.text.isEmpty ? null : _htaController.text,
      dm: _dmController.text.isEmpty ? null : _dmController.text,
      fecha: DateTime.parse(_fechaVisitaController.text),
      telefono: _telefonoController.text.isEmpty ? null : _telefonoController.text,
      longitud: double.tryParse(_longitudController.text),
      latitud: double.tryParse(_latitudController.text),
      zona: _zonaController.text.isEmpty ? null : _zonaController.text,
      peso: double.tryParse(_pesoController.text),
      talla: double.tryParse(_tallaController.text),
      imc: _imcValue,
      perimetroAbdominal: double.tryParse(_perimetroAbdominalController.text),
      frecuenciaCardiaca: int.tryParse(_frecuenciaCardiacaController.text),
      frecuenciaRespiratoria: int.tryParse(_frecuenciaRespiratoriaController.text),
      tensionArterial: _tensionArterialController.text.isEmpty ? null : _tensionArterialController.text,
      glucometria: double.tryParse(_glucometriaController.text),
      temperatura: double.tryParse(_temperaturaController.text),
      familiar: _familiar,
      riesgoFotografico: _fotoRiesgoPath,
      abandonoSocial: _abandonoSocial,
      motivo: _motivosNoAsistencia.isEmpty ? null : _motivosNoAsistencia.join(', '),
      medicamentos: null, // Este campo ya no se usa
      factores: _factoresRiesgo.isEmpty ? null : _factoresRiesgo.join(', '),
      conductas: _conductas.isEmpty ? null : _conductas.join(', '),
      novedades: _novedadesController.text.isEmpty ? null : _novedadesController.text,
      proximoControl: _proximoControlController.text.isNotEmpty
          ? DateTime.parse(_proximoControlController.text)
          : null,
      firma: _firmaPath,
      idusuario: userId,
      idpaciente: _currentPaciente!.id,
      syncStatus: syncStatus, // Estado de sincronización
    );

    final dbHelper = DatabaseHelper.instance;
    
    try {
      if (_isEditing) {
        await dbHelper.updateVisita(visita);
        debugPrint('✅ Visita actualizada localmente con ID: ${visita.id}, estado: ${visita.syncStatus}');
      } else {
        await dbHelper.createVisita(visita);
        debugPrint('✅ Visita creada localmente con ID: ${visita.id}, estado: ${visita.syncStatus}');
      }
      
      // 🆕 Guardar medicamentos localmente
      await dbHelper.saveMedicamentosVisita(visitaId, _selectedMedicamentos);
      debugPrint('✅ Medicamentos guardados para visita $visitaId');
    } catch (e) {
      debugPrint('❌ Error al guardar en base de datos local: $e');
      throw Exception('Error al guardar localmente: $e');
    }

    // ✅ 7. Programar sincronización si está pendiente - MEJORADO
    if (syncStatus == 0) {
      try {
        debugPrint('🔄 Programando sincronización automática...');
        final sincronizacionService = SincronizacionService();
        await sincronizacionService.scheduleSync();
        debugPrint('✅ Sincronización programada correctamente');
      } catch (e) {
        debugPrint('⚠️ Error al programar sincronización: $e');
        // No es crítico, solo log el error
      }
    }

    // ✅ 8. Mostrar mensaje de éxito - MEJORADO
    if (mounted) {
      String mensaje = _isEditing ? 'Visita actualizada' : 'Visita guardada';
      String detalles = '';
      Color backgroundColor = Colors.green;
      
      if (syncStatus == 1) {
        detalles = ' y sincronizada con el servidor ✅';
        backgroundColor = Colors.green;
      } else {
        detalles = ' localmente 📱. Se sincronizará automáticamente cuando haya conexión 🔄';
        backgroundColor = Colors.orange;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mensaje$detalles'),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 5),
          action: syncStatus == 0 ? SnackBarAction(
            label: 'Intentar ahora',
            textColor: Colors.white,
            onPressed: () async {
              final sincronizacionService = SincronizacionService();
              await sincronizacionService.scheduleSync();
            },
          ) : null,
        ),
      );
      
      // Callback para actualizar la lista
      if (widget.onVisitaSaved != null) {
        widget.onVisitaSaved!();
      }
      
      // Si es nueva visita, limpiar formulario, si es edición, cerrar
      if (_isEditing) {
        Navigator.of(context).pop(true);
      } else {
        _resetForm();
      }
    }
    
  } catch (e) {
    debugPrint('💥 Error general al guardar visita: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _saveVisita(),
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _isEditing = false;
      _currentVisitaId = null;
      _currentPaciente = null;
      _imcValue = null;
      _edad = null;
      _familiar = null;
      _abandonoSocial = null;
      _motivosNoAsistencia.clear();
      _factoresRiesgo.clear();
      _conductas.clear();
      _fotoRiesgo = null;
      _fotoRiesgoPath = null;
      _firmaPath = null;
      _selectedMedicamentos.clear();
      _identificacionController.clear();
      _nombreApellidoController.clear();
      _fechaNacimientoController.clear();
      _fechaVisitaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _telefonoController.clear();
      _htaController.clear();
      _dmController.clear();
      _zonaController.clear();
      _pesoController.clear();
      _tallaController.clear();
      _perimetroAbdominalController.clear();
      _frecuenciaCardiacaController.clear();
      _frecuenciaRespiratoriaController.clear();
      _tensionArterialController.clear();
      _glucometriaController.clear();
      _temperaturaController.clear();
      _novedadesController.clear();
      _proximoControlController.clear();
      _latitudController.clear();
      _longitudController.clear();
    });
    _signatureController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.visitaToEdit != null
          ? AppBar(
              title: const Text('Editar Visita'),
              backgroundColor: widget.theme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Datos del Paciente
                  _buildSectionHeader("Datos del Paciente"),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: _identificacionController,
                          decoration: const InputDecoration(labelText: "Identificación"),
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingrese una identificación' : null,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.search_rounded, color: widget.theme.primaryColor),
                        tooltip: 'Buscar paciente',
                        onPressed: _searchPaciente,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  TextFormField(
                    controller: _nombreApellidoController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Nombre y Apellido"),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fechaNacimientoController,
                          decoration: const InputDecoration(labelText: "Fecha Nacimiento"),
                          readOnly: true,
                          onTap: () => _selectDate(context, _fechaNacimientoController, isNacimiento: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: "Edad"),
                          controller: TextEditingController(text: _edad?.toString() ?? ''),
                          enabled: false,
                        ),
                      )
                    ],
                  ),

                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: "Teléfono"),
                      keyboardType: TextInputType.phone,
                    ),

                    // 🆕 GEOLOCALIZACIÓN MOVIDA AQUÍ
                    const SizedBox(height: 16),
                    _buildGeolocationSection(),

                    // Sección: Datos de la Visita
                    const SizedBox(height: 16),
                    _buildSectionHeader("Datos de la Visita"),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _fechaVisitaController,
                      decoration: const InputDecoration(labelText: 'Fecha de Visita'),
                      readOnly: true,
                      onTap: () => _selectDate(context, _fechaVisitaController),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _htaController,
                            decoration: const InputDecoration(labelText: 'HTA'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _dmController,
                            decoration: const InputDecoration(labelText: 'DM'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _zonaController,
                      decoration: const InputDecoration(labelText: 'Zona/Barrio'),
                    ),

                    // Sección: Signos Vitales
                    const SizedBox(height: 16),
                    _buildSectionHeader('Signos Vitales'),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pesoController,
                            decoration: const InputDecoration(labelText: 'Peso (kg)'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculateIMC(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _tallaController,
                            decoration: const InputDecoration(labelText: 'Talla (cm)'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculateIMC(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'IMC'),
                            readOnly: true,
                            controller: TextEditingController(text: _imcValue?.toStringAsFixed(2) ?? ''),
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _perimetroAbdominalController,
                      decoration: const InputDecoration(labelText: 'Perímetro Abdominal (cm)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _frecuenciaCardiacaController,
                            decoration: const InputDecoration(labelText: 'Frec. Cardiaca'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _frecuenciaRespiratoriaController,
                            decoration: const InputDecoration(labelText: 'Frec. Respiratoria'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _tensionArterialController,
                      decoration: const InputDecoration(labelText: 'Tensión Arterial (mmHg)'),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _glucometriaController,
                            decoration: const InputDecoration(labelText: 'Glucometría (mg/dL)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _temperaturaController,
                            decoration: const InputDecoration(labelText: 'Temperatura (°C)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    // Sección: Evaluación
                    const SizedBox(height: 16),
                    _buildSectionHeader('Evaluación'),
                    const SizedBox(height: 8),

                      // 🆕 Sección de Medicamentos (agregar después de la sección de Evaluación)
                  const SizedBox(height: 16),
                  _buildSectionHeader('Medicamentos'),
                  const SizedBox(height: 8),
                  
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return MedicamentosSelector(
                        selectedMedicamentos: _selectedMedicamentos,
                        onChanged: (medicamentos) {
                          setState(() {
                            _selectedMedicamentos = medicamentos;
                          });
                        },
                        token: authProvider.token,
                      );
                    },
                  ),
                    
                    // Familiar - Selección única (Si/No)
                    _buildSingleSelectionField(
                      title: 'Familiar',
                      value: _familiar,
                      options: ['Si', 'No'],
                      onChanged: (value) => setState(() => _familiar = value),
                    ),
                    const SizedBox(height: 16),

                    // Abandono Social - Selección única (Si/No)
                    _buildSingleSelectionField(
                      title: 'Abandono Social',
                      value: _abandonoSocial,
                      options: ['Si', 'No'],
                      onChanged: (value) => setState(() => _abandonoSocial = value),
                    ),
                    const SizedBox(height: 16),

                    // Riesgo Fotográfico - Tomar foto
                    _buildPhotoSection(),
                    const SizedBox(height: 16),

                    // Motivo de No Asistencia - Selección múltiple
                    _buildMultipleSelectionField(
                      title: 'Motivo de No Asistencia',
                      selectedItems: _motivosNoAsistencia,
                      options: _opcionesMotivosNoAsistencia,
                      onChanged: (selectedList) => setState(() => _motivosNoAsistencia = selectedList),
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Factores de Riesgo - Selección múltiple
                    _buildMultipleSelectionField(
                      title: 'Factores de Riesgo',
                      selectedItems: _factoresRiesgo,
                      options: _opcionesFactoresRiesgo,
                      onChanged: (selectedList) => setState(() => _factoresRiesgo = selectedList),
                    ),
                    const SizedBox(height: 16),

                    // Conductas - Selección múltiple
                    _buildMultipleSelectionField(
                      title: 'Conductas',
                      selectedItems: _conductas,
                      options: _opcionesConductas,
                      onChanged: (selectedList) => setState(() => _conductas = selectedList),
                    ),
                    const SizedBox(height: 16),
                    
                    // Novedades
                    TextFormField(
                      controller: _novedadesController,
                      decoration: const InputDecoration(labelText: 'Novedades'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    
                    // Próximo Control
                    TextFormField(
                      controller: _proximoControlController,
                      decoration: const InputDecoration(labelText: 'Próximo Control'),
                      readOnly: true,
                      onTap: () => _selectDate(context, _proximoControlController),
                    ),
                    const SizedBox(height: 16),

                    // Firma
                    _buildSignatureSection(),

                    // Botones de acción
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text("Limpiar"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveVisita,
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isEditing ? "Actualizar" : "Guardar"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
  // Métodos auxiliares para construir widgets
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: widget.theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: widget.theme.primaryColor,
      ),
    );
  }

  // Widget para selección única (Si/No)
  Widget _buildSingleSelectionField({
    required String title,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: value,
                onChanged: onChanged,
                dense: true,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Widget para selección múltiple
  Widget _buildMultipleSelectionField({
    required String title,
    required List<String> selectedItems,
    required List<String> options,
    required Function(List<String>) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Mostrar elementos seleccionados
        if (selectedItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionados:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: selectedItems.map((item) {
                    return Chip(
                      label: Text(item),
                      onDeleted: () {
                        final newList = List<String>.from(selectedItems);
                        newList.remove(item);
                        onChanged(newList);
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Botón para abrir diálogo de selección
        OutlinedButton.icon(
          onPressed: () => _showMultipleSelectionDialog(
            title: title,
            options: options,
            selectedItems: selectedItems,
            onChanged: onChanged,
          ),
          icon: const Icon(Icons.add),
          label: Text('Seleccionar $title'),
        ),
      ],
    );
  }

  // Diálogo para selección múltiple
  void _showMultipleSelectionDialog({
    required String title,
    required List<String> options,
    required List<String> selectedItems,
    required Function(List<String>) onChanged,
  }) {
    List<String> tempSelected = List.from(selectedItems);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Seleccionar $title'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: tempSelected.contains(option),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        tempSelected.add(option);
                      } else {
                        tempSelected.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() => tempSelected.clear());
              },
              child: const Text('Limpiar Todo'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                onChanged(tempSelected);
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para sección de foto
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riesgo Fotográfico',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_fotoRiesgo != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _fotoRiesgo!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_fotoRiesgo == null ? 'Tomar Foto' : 'Cambiar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_fotoRiesgo != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() {
                  _fotoRiesgo = null;
                  _fotoRiesgoPath = null;
                }),
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Eliminar foto',
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Widget para sección de firma
  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Firma',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_firmaPath != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Image.file(
                  File(_firmaPath!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const Text(
                  'Firma registrada',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _mostrarDialogoFirma,
                icon: const Icon(Icons.edit),
                label: Text(_firmaPath == null ? 'Agregar Firma' : 'Cambiar Firma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_firmaPath != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _firmaPath = null),
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Eliminar firma',
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Widget para geolocalización
  Widget _buildGeolocationSection() {
    return ExpansionTile(
      title: const Text('Geolocalización'),
      leading: Icon(
        Icons.location_on,
        color: widget.theme.primaryColor,
      ),
      trailing: Icon(
        _showGeolocalizacion ? Icons.expand_less : Icons.expand_more,
      ),
      onExpansionChanged: (expanded) {
        setState(() => _showGeolocalizacion = expanded);
      },
      initiallyExpanded: _showGeolocalizacion,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Estado de ubicación
              if (_currentPaciente != null && 
                  _currentPaciente!.latitud != null && 
                  _currentPaciente!.longitud != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ubicación registrada',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Lat: ${_currentPaciente!.latitud!.toStringAsFixed(6)}\n'
                              'Lng: ${_currentPaciente!.longitud!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sin ubicación registrada',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Presione el botón para obtener ubicación actual',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

               const SizedBox(height: 16),

              // Campos de coordenadas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudController,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        prefixIcon: Icon(Icons.location_pin),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudController,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        prefixIcon: Icon(Icons.location_pin),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botones de acción para geolocalización
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.location_on),
                      label: Text(
                        _isGettingLocation 
                            ? 'Obteniendo...' 
                            : 'Obtener Ubicación',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onPressed: _clearGeolocalizacion,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
