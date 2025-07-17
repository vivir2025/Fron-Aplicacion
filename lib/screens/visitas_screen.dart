import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/api/visita_service.dart';
import 'package:fnpv_app/services/sincronizacion_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../models/paciente_model.dart';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';

class VisitasScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const VisitasScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen> {
  // Controladores originales
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
  final _familiarController = TextEditingController();
  final _riesgoFotograficoController = TextEditingController();
  final _abandonoSocialController = TextEditingController();
  final _motivoController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _factoresController = TextEditingController();
  final _conductasController = TextEditingController();
  final _firmaController = TextEditingController();
  final _novedadesController = TextEditingController();
  final _proximoControlController = TextEditingController();

  // Controladores NUEVOS para geo
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  bool _showGeolocalizacion = false;
  bool _isGettingLocation = false;

  List<Visita> _visitas = [];
  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentVisitaId;
  double? _imcValue;
  int? _edad;
  Paciente? _currentPaciente;

  ThemeData get customTheme => ThemeData(
    primarySwatch: Colors.green,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Color(0xFF388E3C)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
  );

  @override
  void initState() {
    super.initState();
    _fechaVisitaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadVisitas();
  }

  @override
  void dispose() {
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
    _familiarController.dispose();
    _riesgoFotograficoController.dispose();
    _abandonoSocialController.dispose();
    _motivoController.dispose();
    _medicamentosController.dispose();
    _factoresController.dispose();
    _conductasController.dispose();
    _novedadesController.dispose();
    _proximoControlController.dispose();
    _firmaController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }
  

  Future<void> _loadVisitas() async {
  setState(() => _isLoading = true);
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = await authProvider.getCurrentUserId();
    
    if (userId == null) {
      throw Exception('Usuario no autenticado. ID de usuario nulo');
    }

    final dbHelper = DatabaseHelper.instance;
    _visitas = await dbHelper.getVisitasByUsuario(userId);
    
    if (_visitas.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay visitas registradas')),
      );
    }
  } catch (e) {
    debugPrint('Error cargando visitas: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      
      // Si es error de autenticación, redirigir
      if (e.toString().contains('no autenticado')) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  // BUSCAR PACIENTE (Actualizado para cargar coords si existen)
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
          _latitudController.text = paciente.latitud?.toString() ?? '';
          _longitudController.text = paciente.longitud?.toString() ?? '';
        });
        _updateEdad();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente no encontrado')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar paciente: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
        data: customTheme.copyWith(
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

  // *** Geolocalización ***
  // --- CHECK PERMISOS ---
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

  // --- GET LOCATION ---
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

      if (_currentPaciente != null) {
        await DatabaseHelper.instance.updatePacienteGeolocalizacion(
          _currentPaciente!.id,
          position.latitude,
          position.longitude,
        );

        _currentPaciente = _currentPaciente!.copyWith(
          latitud: position.latitude,
          longitud: position.longitude,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geolocalización guardada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  // --- CLEAR GEOLOCALIZACIÓN ---
  void _clearGeolocalizacion() {
    _latitudController.clear();
    _longitudController.clear();
    if (_currentPaciente != null) {
      DatabaseHelper.instance.updatePacienteGeolocalizacion(
        _currentPaciente!.id,
        0.0,
        0.0,
      );
      _currentPaciente = _currentPaciente!.copyWith(
        latitud: null,
        longitud: null,
      );
    }
    setState(() {}); // actualizar UI
  }

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

    debugPrint('🔍 DEBUG - UserID: $userId, Token: ${token != null ? "exists" : "null"}');

    if (userId == null) {
      throw Exception('No se pudo obtener el ID del usuario. Vuelva a iniciar sesión.');
    }

    final visita = Visita(
      id: _isEditing ? _currentVisitaId! : VisitaService.generateId(), // ← CAMBIO AQUÍ
      nombreApellido: _nombreApellidoController.text,
      identificacion: _identificacionController.text,
      hta: _htaController.text.isEmpty ? null : _htaController.text,
      dm: _dmController.text.isEmpty ? null : _dmController.text,
      fecha: DateTime.parse(_fechaVisitaController.text),
      telefono: _telefonoController.text.isEmpty ? null : _telefonoController.text,
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
      familiar: _familiarController.text.isEmpty ? null : _familiarController.text,
      riesgoFotografico: _riesgoFotograficoController.text.isEmpty ? null : _riesgoFotograficoController.text,
      abandonoSocial: _abandonoSocialController.text.isEmpty ? null : _abandonoSocialController.text,
      motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      medicamentos: _medicamentosController.text.isEmpty ? null : _medicamentosController.text,
      factores: _factoresController.text.isEmpty ? null : _factoresController.text,
      conductas: _conductasController.text.isEmpty ? null : _conductasController.text,
      novedades: _novedadesController.text.isEmpty ? null : _novedadesController.text,

      proximoControl: _proximoControlController.text.isNotEmpty
          ? DateTime.parse(_proximoControlController.text)
          : null,
      firma: _firmaController.text.isEmpty ? null : _firmaController.text,
      idusuario: userId,
      idpaciente: _currentPaciente!.id,
      syncStatus: 0,
    );

    final success = await SincronizacionService.guardarVisita(visita, token);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visita ${_isEditing ? 'actualizada' : 'guardada'} correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
      _loadVisitas();
      _mostrarEstadoSincronizacion();
    } else {
      throw Exception('No se pudo guardar la visita');
    }
  } catch (e) {
    debugPrint('💥 Error al guardar visita: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// 4. Método para mostrar estado de sincronización
Future<void> _mostrarEstadoSincronizacion() async {
  final estado = await SincronizacionService.obtenerEstadoSincronizacion();
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Estado: ${estado['sincronizadas']} sincronizadas, ${estado['pendientes']} pendientes',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
Future<void> _sincronizarManualmente() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final token = authProvider.token;
  
  if (token == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autenticación requerida')),
      );
    }
    return;
  }

  setState(() => _isLoading = true);
  
  try {
    // Verificación optimizada del servidor
    debugPrint('🔄 Verificando disponibilidad del servidor...');
    final serverAvailable = await ApiService.verificarSaludServidor();
    
    if (!serverAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar con el servidor'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    debugPrint('🔄 Iniciando sincronización...');
    final resultado = await SincronizacionService.sincronizarVisitasPendientes(token)
      .timeout(const Duration(seconds: 30));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sincronización: ${resultado['exitosas']} exitosas, ${resultado['fallidas']} fallidas',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: resultado['fallidas'] == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  } on TimeoutException {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El servidor no respondió a tiempo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } on http.ClientException catch (e) {
    if (mounted) {
      final message = e.message.contains('404') 
          ? 'Recurso no encontrado' 
          : 'Error de comunicación: ${e.message.split(':').first}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    debugPrint('Error completo: $e');
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
      _familiarController.clear();
      _riesgoFotograficoController.clear();
      _abandonoSocialController.clear();
      _motivoController.clear();
      _medicamentosController.clear();
      _factoresController.clear();
      _conductasController.clear();
      _novedadesController.clear();
      _proximoControlController.clear();
      _firmaController.clear();
      _latitudController.clear();
      _longitudController.clear();
    });
  }

  void _editVisita(Visita visita) async {
    setState(() {
      _isEditing = true;
      _currentVisitaId = visita.id;
      _currentPaciente = Paciente(
        id: visita.idpaciente,
        identificacion: visita.identificacion,
        fecnacimiento: DateTime.now(),
        nombre: visita.nombreApellido.split(' ').first,
        apellido: visita.nombreApellido.split(' ').skip(1).join(' '),
        genero: '',
        idsede: '',
      );
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
      _familiarController.text = visita.familiar ?? '';
      _riesgoFotograficoController.text = visita.riesgoFotografico ?? '';
      _abandonoSocialController.text = visita.abandonoSocial ?? '';
      _motivoController.text = visita.motivo ?? '';
      _medicamentosController.text = visita.medicamentos ?? '';
      _factoresController.text = visita.factores ?? '';
      _conductasController.text = visita.conductas ?? '';
      _novedadesController.text = visita.novedades ?? '';
      _proximoControlController.text = visita.proximoControl != null
          ? DateFormat('yyyy-MM-dd').format(visita.proximoControl!)
          : '';
      _firmaController.text = visita.firma ?? '';
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final paciente = await dbHelper.getPacienteById(visita.idpaciente);
      if (paciente != null) {
        setState(() {
          _currentPaciente = paciente;
          _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(paciente.fecnacimiento);
          _latitudController.text = paciente.latitud?.toString() ?? '';
          _longitudController.text = paciente.longitud?.toString() ?? '';
        });
        _updateEdad();
      }
    } catch (e) {
      debugPrint('Error al obtener datos completos del paciente: $e');
    }
    _calculateIMC();
  }

  Future<void> _deleteVisita(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar esta visita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.deleteVisita(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visita eliminada correctamente')),
          );
        }
        _loadVisitas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar visita: ${e.toString()}')),
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
Widget build(BuildContext context) {
  return Theme(
    data: customTheme,
    child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visitas Domiciliarias'),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar manualmente',
              onPressed: _sincronizarManualmente,
            ),
            IconButton(
              icon: const Icon(Icons.refresh), 
              onPressed: _loadVisitas,
              tooltip: 'Recargar visitas',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Listado'),
              Tab(icon: Icon(Icons.add), text: 'Nueva Visita'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVisitasList(),
            _buildVisitaFormModern(),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildVisitasList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_visitas.isEmpty) return const Center(child: Text('No hay visitas registradas'));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _visitas.length,
      itemBuilder: (context, index) {
        final visita = _visitas[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: customTheme.primaryColorLight,
              child: Icon(Icons.person, color: customTheme.primaryColorDark),
            ),
            title: Text(visita.nombreApellido, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${visita.identificacion}', style: const TextStyle(fontSize: 12)),
                Text('Fecha: ${DateFormat('dd/MM/yyyy').format(visita.fecha)}', style: const TextStyle(fontSize: 12)),
                if (visita.motivo != null && visita.motivo!.isNotEmpty)
                  Text('Motivo: ${visita.motivo}', style: const TextStyle(color: Colors.black87, fontSize: 12)),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(icon: const Icon(Icons.info_outline, color: Colors.green), onPressed: () => _showVisitaDetails(visita)),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editVisita(visita)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteVisita(visita.id)),
              ],
            ),
            onTap: () => _showVisitaDetails(visita),
          ),
        );
      }
    );
  }

  Widget _buildVisitaFormModern() {
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text("Datos del Paciente", style: customTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      icon: Icon(Icons.search_rounded, color: customTheme.primaryColor),
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
                        onTap: () => _selectDate(context, _fechaNacimientoController, isNacimiento: true)
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
                TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: "Teléfono"), keyboardType: TextInputType.phone),

                // ------------ GEOLOCALIZACIÓN --------------------
ExpansionTile(
  title: const Text('Geolocalización'),
  trailing: Icon(
    _showGeolocalizacion ? Icons.expand_less : Icons.expand_more,
  ),
  onExpansionChanged: (expanded) {
    setState(() => _showGeolocalizacion = expanded);
  },
  initiallyExpanded: _showGeolocalizacion,
  children: [
    // Verificación segura para mostrar ubicación actual
    if (_currentPaciente != null && 
        _currentPaciente!.latitud != null && 
        _currentPaciente!.longitud != null)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Ubicación actual: ${_currentPaciente!.latitud!.toStringAsFixed(6)}, ${_currentPaciente!.longitud!.toStringAsFixed(6)}',
          style: TextStyle(color: Colors.green[700]),
        ),
      ),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _latitudController,
            decoration: const InputDecoration(labelText: 'Latitud'),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _longitudController,
            decoration: const InputDecoration(labelText: 'Longitud'),
            readOnly: true,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            icon: const Icon(Icons.location_on),
            label: _isGettingLocation
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                : const Text('Obtener Ubicación'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearGeolocalizacion,
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
  ],
),
                // ---------/GEO---------------------------

const Divider(height: 28),

Text("Datos de la Visita", style: customTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
const Divider(height: 28),
Text('Signos Vitales', style: customTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
const Divider(height: 28),
Text('Evaluación', style: customTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
TextFormField(
  controller: _familiarController,
  decoration: const InputDecoration(labelText: 'Familiar'),
  maxLines: 2,
),
const SizedBox(height: 8),
TextFormField(
  controller: _riesgoFotograficoController,
  decoration: const InputDecoration(labelText: 'Riesgo Fotográfico'),
  maxLines: 2,
),
const SizedBox(height: 8),
TextFormField(
  controller: _abandonoSocialController,
  decoration: const InputDecoration(labelText: 'Abandono Social'),
  maxLines: 2,
),
const SizedBox(height: 8),
TextFormField(
  controller: _motivoController,
  decoration: const InputDecoration(labelText: 'Motivo de la Visita'),
  maxLines: 3,
  validator: (value) {
    if (value == null || value.isEmpty) return 'Ingrese el motivo de la visita';
    return null;
  },
),
const SizedBox(height: 8),
TextFormField(
  controller: _medicamentosController,
  decoration: const InputDecoration(labelText: 'Medicamentos'),
  maxLines: 3,
),
const SizedBox(height: 8),
TextFormField(
  controller: _factoresController,
  decoration: const InputDecoration(labelText: 'Factores de Riesgo'),
  maxLines: 3,
),
const SizedBox(height: 8),
TextFormField(
  controller: _conductasController,
  decoration: const InputDecoration(labelText: 'Conductas'),
  maxLines: 3,
),
const SizedBox(height: 8),
TextFormField(
  controller: _novedadesController,
  decoration: const InputDecoration(labelText: 'Novedades'),
  maxLines: 3,
),
const SizedBox(height: 8),
TextFormField(
  controller: _proximoControlController,
  decoration: const InputDecoration(labelText: 'Próximo Control'),
  readOnly: true,
  onTap: () => _selectDate(context, _proximoControlController),
),
const SizedBox(height: 8),
TextFormField(
  controller: _firmaController,
  decoration: const InputDecoration(labelText: 'Firma'),
  maxLines: 3,
),
const SizedBox(height: 22),
Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: _resetForm,
        icon: const Icon(Icons.clear_rounded),
        label: const Text("Limpiar"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          textStyle: customTheme.textTheme.bodyMedium,
        ),
      ),
    ),
    const SizedBox(width: 18),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveVisita,
        icon: const Icon(Icons.save),
        label: _isLoading
          ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
          : Text(_isEditing ? "Actualizar" : "Guardar"),
      ),
    ),
  ],
),  
              ],
            ),
          ),
        ),
      ),
    );
  }
 void _showVisitaDetails(Visita visita) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Visita del ${DateFormat('dd/MM/yyyy').format(visita.fecha)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paciente: ${visita.nombreApellido}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Identificación: ${visita.identificacion}'),
            const SizedBox(height: 10),
            if (visita.hta != null && visita.hta!.isNotEmpty)
              Text('HTA: ${visita.hta}'),
            if (visita.dm != null && visita.dm!.isNotEmpty)
              Text('DM: ${visita.dm}'),
            if (visita.zona != null && visita.zona!.isNotEmpty)
              Text('Zona: ${visita.zona}'),
            if (visita.telefono != null && visita.telefono!.isNotEmpty)
              Text('Teléfono: ${visita.telefono}'),
            // CORRECCIÓN: Verificación segura para geolocalización
            if (_currentPaciente != null && 
                _currentPaciente!.latitud != null && 
                _currentPaciente!.longitud != null)
              Text('Geolocalización: ${_currentPaciente!.latitud}, ${_currentPaciente!.longitud}'),
            const SizedBox(height: 10),
            const Text('Signos Vitales:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (visita.peso != null)
              Text('Peso: ${visita.peso} kg'),
            if (visita.talla != null)
              Text('Talla: ${visita.talla} cm'),
            if (visita.imc != null)
              Text('IMC: ${visita.imc!.toStringAsFixed(2)}'),
            if (visita.perimetroAbdominal != null)
              Text('Perímetro Abdominal: ${visita.perimetroAbdominal} cm'),
            if (visita.frecuenciaCardiaca != null)
              Text('Frec. Cardiaca: ${visita.frecuenciaCardiaca} lpm'),
            if (visita.frecuenciaRespiratoria != null)
              Text('Frec. Respiratoria: ${visita.frecuenciaRespiratoria} rpm'),
            if (visita.tensionArterial != null && visita.tensionArterial!.isNotEmpty)
              Text('Tensión Arterial: ${visita.tensionArterial}'),
            if (visita.glucometria != null)
              Text('Glucometría: ${visita.glucometria} mg/dL'),
            if (visita.temperatura != null)
              Text('Temperatura: ${visita.temperatura} °C'),
            const SizedBox(height: 10),
            if (visita.motivo != null && visita.motivo!.isNotEmpty)
              Text('Motivo: ${visita.motivo}'),
            if (visita.medicamentos != null && visita.medicamentos!.isNotEmpty)
              Text('Medicamentos: ${visita.medicamentos}'),
            if (visita.factores != null && visita.factores!.isNotEmpty)
              Text('Factores de Riesgo: ${visita.factores}'),
            if (visita.conductas != null && visita.conductas!.isNotEmpty)
              Text('Conductas: ${visita.conductas}'),
            if (visita.novedades != null && visita.novedades!.isNotEmpty)
              Text('Novedades: ${visita.novedades}'),
            if (visita.proximoControl != null)
              Text('Próximo Control: ${DateFormat('dd/MM/yyyy').format(visita.proximoControl!)}'),
            if (visita.firma != null && visita.firma!.isNotEmpty)
              Text('Firma: ${visita.firma}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
}