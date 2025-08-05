// screens/crear_brigada_screen.dart - VERSIÓN CON OVERFLOW ARREGLADO
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/brigada_model.dart';
import '../models/paciente_model.dart';
import '../services/brigada_service.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrearBrigadaScreen extends StatefulWidget {
  const CrearBrigadaScreen({Key? key}) : super(key: key);

  @override
  State<CrearBrigadaScreen> createState() => _CrearBrigadaScreenState();
}

class _CrearBrigadaScreenState extends State<CrearBrigadaScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Controladores de texto
  final _lugarEventoController = TextEditingController();
  final _nombreConductorController = TextEditingController();
  final _usuariosHtaController = TextEditingController();
  final _usuariosDnController = TextEditingController();
  final _usuariosHtaRcuController = TextEditingController();
  final _usuariosDmRcuController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _temaController = TextEditingController();
  
  // ✅ CONTROLADOR PARA BÚSQUEDA DE PACIENTES
  final _searchController = TextEditingController();
  
  DateTime _fechaBrigada = DateTime.now();
  List<Paciente> _allPacientes = [];
  List<Paciente> _filteredPacientes = []; // ✅ LISTA FILTRADA
  List<Paciente> _selectedPacientes = [];
  bool _isLoading = false;
  bool _isLoadingPacientes = false;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
    // ✅ LISTENER PARA BÚSQUEDA EN TIEMPO REAL
    _searchController.addListener(_filtrarPacientes);
  }

  @override
  void dispose() {
    _lugarEventoController.dispose();
    _nombreConductorController.dispose();
    _usuariosHtaController.dispose();
    _usuariosDnController.dispose();
    _usuariosHtaRcuController.dispose();
    _usuariosDmRcuController.dispose();
    _observacionesController.dispose();
    _temaController.dispose();
    _searchController.dispose(); // ✅ DISPOSE DEL CONTROLADOR DE BÚSQUEDA
    super.dispose();
  }

  Future<void> _cargarPacientes() async {
    setState(() => _isLoadingPacientes = true);
    
    try {
      final pacientes = await _dbHelper.readAllPacientes();
      setState(() {
        _allPacientes = pacientes;
        _filteredPacientes = pacientes; // ✅ INICIALIZAR LISTA FILTRADA
        _isLoadingPacientes = false;
      });
      debugPrint('✅ ${pacientes.length} pacientes cargados');
    } catch (e) {
      setState(() => _isLoadingPacientes = false);
      debugPrint('❌ Error cargando pacientes: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pacientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ MÉTODO PARA FILTRAR PACIENTES POR IDENTIFICACIÓN Y NOMBRE
  void _filtrarPacientes() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredPacientes = _allPacientes;
      } else {
        _filteredPacientes = _allPacientes.where((paciente) {
          final identificacion = paciente.identificacion.toLowerCase();
          final nombreCompleto = paciente.nombreCompleto.toLowerCase();
          
          return identificacion.contains(query) || nombreCompleto.contains(query);
        }).toList();
      }
    });
  }

  // ✅ DATEPICKER CORREGIDO - SIN LOCALE
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaBrigada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // ✅ SIN LOCALE - ESTO EVITA EL ERROR
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldLabelText: 'Ingrese fecha',
      fieldHintText: 'dd/mm/aaaa',
      errorFormatText: 'Formato inválido',
      errorInvalidText: 'Fecha inválida',
      
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green, // Color principal
              onPrimary: Colors.white, // Color del texto en el botón
              surface: Colors.white, // Color de fondo
              onSurface: Colors.black, // Color del texto
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green, // Color de los botones
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _fechaBrigada) {
      setState(() {
        _fechaBrigada = picked;
      });
    }
  }

  // ✅ SELECTOR DE PACIENTES CON OVERFLOW ARREGLADO
  void _mostrarSelectorPacientes() {
    if (_allPacientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay pacientes disponibles. Agregue pacientes primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<Paciente> tempSelected = List.from(_selectedPacientes);
    List<Paciente> dialogFilteredPacientes = List.from(_allPacientes);
    final dialogSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Seleccionar Pacientes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // ✅ BARRA DE BÚSQUEDA PROFESIONAL
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: dialogSearchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por identificación o nombre',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Ej: 12345678 o Juan Pérez',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      suffixIcon: dialogSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                dialogSearchController.clear();
                                setDialogState(() {
                                  dialogFilteredPacientes = _allPacientes;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (query) {
                      setDialogState(() {
                        final searchQuery = query.toLowerCase().trim();
                        if (searchQuery.isEmpty) {
                          dialogFilteredPacientes = _allPacientes;
                        } else {
                          dialogFilteredPacientes = _allPacientes.where((paciente) {
                            final identificacion = paciente.identificacion.toLowerCase();
                            final nombreCompleto = paciente.nombreCompleto.toLowerCase();
                            return identificacion.contains(searchQuery) || 
                                   nombreCompleto.contains(searchQuery);
                          }).toList();
                        }
                      });
                    },
                  ),
                ),

                // ✅ CONTADOR DE RESULTADOS Y SELECCIONADOS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tempSelected.length} pacientes seleccionados',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Mostrando ${dialogFilteredPacientes.length} de ${_allPacientes.length} pacientes',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // ✅ LISTA DE PACIENTES FILTRADOS - SIN OVERFLOW
                Expanded(
                  child: dialogFilteredPacientes.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron pacientes',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Intenta con otro término de búsqueda',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: dialogFilteredPacientes.length,
                          itemBuilder: (context, index) {
                            final paciente = dialogFilteredPacientes[index];
                            final isSelected = tempSelected.any((p) => p.id == paciente.id);
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                ),
                                color: isSelected 
                                    ? Colors.green.withOpacity(0.05)
                                    : Colors.white,
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  paciente.nombreCompleto,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.green.shade700 : Colors.black87,
                                    fontSize: 14, // 🆕 Reducir tamaño de fuente
                                  ),
                                ),
                                // 🆕 SUBTITLE ARREGLADO - SIN OVERFLOW
                                subtitle: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  child: Column( // 🆕 Cambiar a Column para evitar overflow
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 🆕 Primera fila: ID
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ID: ${paciente.identificacion}',
                                          style: TextStyle(
                                            fontSize: 10, // 🆕 Reducir tamaño
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4), // 🆕 Espaciado
                                      // 🆕 Segunda fila: Género - SOLO ICONO Y LETRA
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: paciente.genero == 'M' 
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.pink.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          paciente.genero == 'M' ? '♂ M' : '♀ F', // 🆕 SOLO LETRA
                                          style: TextStyle(
                                            fontSize: 10, // 🆕 Reducir tamaño
                                            fontWeight: FontWeight.w600,
                                            color: paciente.genero == 'M' 
                                                ? Colors.blue.shade600
                                                : Colors.pink.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      tempSelected.add(paciente);
                                    } else {
                                      tempSelected.removeWhere((p) => p.id == paciente.id);
                                    }
                                  });
                                },
                                activeColor: Colors.green,
                                checkColor: Colors.white,
                                controlAffinity: ListTileControlAffinity.trailing,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 🆕 Reducir padding
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            // ✅ BOTÓN LIMPIAR TODO
            TextButton.icon(
              onPressed: () {
                setDialogState(() {
                  tempSelected.clear();
                });
              },
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Limpiar Todo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
            
            // ✅ BOTÓN CANCELAR
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancelar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            
            // ✅ BOTÓN GUARDAR CON CONTADOR
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPacientes = tempSelected;
                  });
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('Guardar (${tempSelected.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _guardarBrigada() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_selectedPacientes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debe seleccionar al menos un paciente'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Crear brigada con ID único
    final brigada = Brigada(
      id: 'brig_${const Uuid().v4()}',
      lugarEvento: _lugarEventoController.text.trim(),
      fechaBrigada: _fechaBrigada,
      nombreConductor: _nombreConductorController.text.trim(),
      usuariosHta: _usuariosHtaController.text.trim(),
      usuariosDn: _usuariosDnController.text.trim(),
      usuariosHtaRcu: _usuariosHtaRcuController.text.trim(),
      usuariosDmRcu: _usuariosDmRcuController.text.trim(),
      observaciones: _observacionesController.text.trim().isNotEmpty 
          ? _observacionesController.text.trim() 
          : null,
      tema: _temaController.text.trim(),
      pacientesIds: _selectedPacientes.map((p) => p.id).toList(),
    );

    // Usar el método completo que guarda y sincroniza todo
    final success = await BrigadaService.crearBrigada(
      brigada: brigada,
      pacientesIds: _selectedPacientes.map((p) => p.id).toList(),
      token: authProvider.token,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brigada creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la brigada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('❌ Error al guardar brigada: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nueva Brigada',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info_outline, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Información Básica',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _temaController,
                      decoration: const InputDecoration(
                        labelText: 'Tema de la Brigada *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.topic),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El tema es requerido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _lugarEventoController,
                      decoration: const InputDecoration(
                        labelText: 'Lugar del Evento *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El lugar es requerido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de la Brigada',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_fechaBrigada),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nombreConductorController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Conductor *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre del conductor es requerido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Información de usuarios
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.group, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Información de Usuarios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usuariosHtaController,
                      decoration: const InputDecoration(
                        labelText: 'Usuarios HTA *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Los usuarios HTA son requeridos';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usuariosDnController,
                      decoration: const InputDecoration(
                        labelText: 'Usuarios DN *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Los usuarios DN son requeridos';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usuariosHtaRcuController,
                      decoration: const InputDecoration(
                        labelText: 'Usuarios HTA RCU *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_heart),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Los usuarios HTA RCU son requeridos';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usuariosDmRcuController,
                      decoration: const InputDecoration(
                        labelText: 'Usuarios DM RCU *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bloodtype),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Los usuarios DM RCU son requeridos';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ✅ PACIENTES ASIGNADOS CON OVERFLOW ARREGLADO
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people, color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pacientes Asignados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoadingPacientes)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_selectedPacientes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedPacientes.length} pacientes seleccionados:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 🆕 LISTA DE PACIENTES SELECCIONADOS - SIN OVERFLOW
                            ...(_selectedPacientes.take(3).map((paciente) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          paciente.nombreCompleto,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // 🆕 INFORMACIÓN DEL PACIENTE - SIN OVERFLOW
                                        Row(
                                          children: [
                                            Flexible( // 🆕 Usar Flexible en lugar de Expanded
                                              child: Text(
                                                'ID: ${paciente.identificacion}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis, // 🆕 Truncar si es muy largo
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 🆕 GÉNERO COMPACTO
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: paciente.genero == 'M' 
                                                    ? Colors.blue.withOpacity(0.2)
                                                    : Colors.pink.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                paciente.genero == 'M' ? '♂' : '♀', // 🆕 SOLO SÍMBOLO
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: paciente.genero == 'M' 
                                                      ? Colors.blue.shade700
                                                      : Colors.pink.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                            if (_selectedPacientes.length > 3)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '... y ${_selectedPacientes.length - 3} pacientes más',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // ✅ BOTÓN PARA ABRIR SELECTOR CON BÚSQUEDA
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingPacientes ? null : _mostrarSelectorPacientes,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _selectedPacientes.isEmpty 
                                ? Icons.person_add_rounded
                                : Icons.edit_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        label: Text(
                          _selectedPacientes.isEmpty 
                              ? 'Seleccionar Pacientes' 
                              : 'Modificar Selección',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    if (_allPacientes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_allPacientes.length} pacientes disponibles en total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Observaciones
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.note_alt, color: Colors.purple),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        hintText: 'Ingrese cualquier observación adicional...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ✅ BOTÓN GUARDAR MEJORADO
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade500,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarBrigada,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Guardando brigada...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.save_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Crear Brigada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
