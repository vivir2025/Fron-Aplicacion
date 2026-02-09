// screens/crear_brigada_mejorada_screen.dart
// ✅ FLUJO CON PANTALLAS SEPARADAS
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/brigada_model.dart';
import '../models/paciente_model.dart';
import '../models/medicamento.dart';
import '../services/brigada_service.dart';
import '../services/medicamento_service.dart';
import '../providers/auth_provider.dart';

// 🆕 MODELO PARA DATOS DE LA BRIGADA
class DatosBrigada {
  final String tema;
  final String lugarEvento;
  final DateTime fechaBrigada;
  final String nombreConductor;
  final String usuariosHta;
  final String usuariosDn;
  final String usuariosHtaRcu;
  final String usuariosDmRcu;
  final String? observaciones;

  DatosBrigada({
    required this.tema,
    required this.lugarEvento,
    required this.fechaBrigada,
    required this.nombreConductor,
    required this.usuariosHta,
    required this.usuariosDn,
    required this.usuariosHtaRcu,
    required this.usuariosDmRcu,
    this.observaciones,
  });
}

// 🆕 MODELO PARA PACIENTE CON SUS MEDICAMENTOS
class PacienteConMedicamentos {
  final Paciente paciente;
  final List<MedicamentoAsignado> medicamentos;

  PacienteConMedicamentos({
    required this.paciente,
    required this.medicamentos,
  });
}

class MedicamentoAsignado {
  final Medicamento medicamento;
  bool isSelected;
  String dosis;
  String cantidad;
  String indicaciones;

  MedicamentoAsignado({
    required this.medicamento,
    this.isSelected = false,
    this.dosis = '',
    this.cantidad = '',
    this.indicaciones = '',
  });
}

class CrearBrigadaMejoradaScreen extends StatefulWidget {
  const CrearBrigadaMejoradaScreen({Key? key}) : super(key: key);

  @override
  State<CrearBrigadaMejoradaScreen> createState() => _CrearBrigadaMejoradaScreenState();
}

class _CrearBrigadaMejoradaScreenState extends State<CrearBrigadaMejoradaScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Controladores de texto para la brigada
  final _lugarEventoController = TextEditingController();
  final _nombreConductorController = TextEditingController();
  final _usuariosHtaController = TextEditingController();
  final _usuariosDnController = TextEditingController();
  final _usuariosHtaRcuController = TextEditingController();
  final _usuariosDmRcuController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _temaController = TextEditingController();
  
  DateTime _fechaBrigada = DateTime.now();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con "0"
    _usuariosHtaRcuController.text = '0';
    _usuariosDmRcuController.text = '0';
  }

  @override
  void dispose() {
    _temaController.dispose();
    _lugarEventoController.dispose();
    _nombreConductorController.dispose();
    _usuariosHtaController.dispose();
    _usuariosDnController.dispose();
    _usuariosHtaRcuController.dispose();
    _usuariosDmRcuController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaBrigada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _fechaBrigada = picked);
    }
  }

  // ✅ Ir a la pantalla de selección de pacientes
  Future<void> _irAPantallaPacientes() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete todos los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Navegar a la pantalla de pacientes
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaPacientesBrigada(
          datosBrigada: DatosBrigada(
            tema: _temaController.text.trim(),
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
          ),
        ),
      ),
    );
    
    // Si guardó la brigada, cerrar esta pantalla también
    if (resultado == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nueva Brigada - Paso 1/3'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
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
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Información de la Brigada',
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
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _lugarEventoController,
                          decoration: const InputDecoration(
                            labelText: 'Lugar del Evento *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _nombreConductorController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Conductor *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Información de Usuarios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosHtaController,
                                decoration: const InputDecoration(
                                  labelText: 'Usuarios HTA *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosDnController,
                                decoration: const InputDecoration(
                                  labelText: 'Usuarios DM *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosHtaRcuController,
                                decoration: const InputDecoration(
                                  labelText: 'HTA RCU',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosDmRcuController,
                                decoration: const InputDecoration(
                                  labelText: 'DM RCU',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _observacionesController,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        
                        // Botón Siguiente
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _irAPantallaPacientes,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Siguiente: Seleccionar Pacientes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ========================================
// 🆕 PANTALLA 2: SELECCIONAR PACIENTES
// ========================================
class PantallaPacientesBrigada extends StatefulWidget {
  final DatosBrigada datosBrigada;

  const PantallaPacientesBrigada({
    Key? key,
    required this.datosBrigada,
  }) : super(key: key);

  @override
  State<PantallaPacientesBrigada> createState() => _PantallaPacientesBrigadaState();
}

class _PantallaPacientesBrigadaState extends State<PantallaPacientesBrigada> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  
  List<Paciente> _allPacientes = [];
  List<Paciente> _filteredPacientes = [];
  List<PacienteConMedicamentos> _pacientesAgregados = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPacientes() async {
    setState(() => _isLoading = true);
    try {
      final pacientes = await _dbHelper.readAllPacientes();
      setState(() {
        _allPacientes = pacientes;
        _filteredPacientes = pacientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error cargando pacientes: $e');
    }
  }

  void _filtrarPacientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPacientes = _allPacientes;
      } else {
        _filteredPacientes = _allPacientes.where((p) {
          return p.identificacion.toLowerCase().contains(query.toLowerCase()) ||
                 p.nombreCompleto.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Navegar a pantalla de medicamentos
  Future<void> _seleccionarPaciente(Paciente paciente) async {
    // Verificar si ya fue agregado
    if (_pacientesAgregados.any((p) => p.paciente.id == paciente.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este paciente ya fue agregado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar a pantalla de medicamentos
    final medicamentosAsignados = await Navigator.push<List<MedicamentoAsignado>>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaMedicamentosPaciente(
          paciente: paciente,
        ),
      ),
    );

    // Si agregó medicamentos, guardar en la lista
    if (medicamentosAsignados != null && medicamentosAsignados.isNotEmpty) {
      setState(() {
        _pacientesAgregados.add(
          PacienteConMedicamentos(
            paciente: paciente,
            medicamentos: medicamentosAsignados,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${paciente.nombreCompleto} agregado con ${medicamentosAsignados.length} medicamentos',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _eliminarPaciente(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
          '¿Eliminar a ${_pacientesAgregados[index].paciente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pacientesAgregados.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarBrigadaCompleta() async {
    if (_pacientesAgregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos un paciente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que todos los medicamentos tengan cantidades válidas
    for (final pacienteConMed in _pacientesAgregados) {
      for (final med in pacienteConMed.medicamentos) {
        if (med.cantidad.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El medicamento "${med.medicamento.nombmedicamento}" del paciente "${pacienteConMed.paciente.nombreCompleto}" debe tener una cantidad especificada'
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (int.tryParse(med.cantidad.trim()) == null || int.tryParse(med.cantidad.trim())! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'La cantidad del medicamento "${med.medicamento.nombmedicamento}" del paciente "${pacienteConMed.paciente.nombreCompleto}" debe ser un número válido mayor a 0'
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final brigada = Brigada(
        id: 'brig_${const Uuid().v4()}',
        lugarEvento: widget.datosBrigada.lugarEvento,
        fechaBrigada: widget.datosBrigada.fechaBrigada,
        nombreConductor: widget.datosBrigada.nombreConductor,
        usuariosHta: widget.datosBrigada.usuariosHta,
        usuariosDn: widget.datosBrigada.usuariosDn,
        usuariosHtaRcu: widget.datosBrigada.usuariosHtaRcu,
        usuariosDmRcu: widget.datosBrigada.usuariosDmRcu,
        observaciones: widget.datosBrigada.observaciones,
        tema: widget.datosBrigada.tema,
        pacientesIds: _pacientesAgregados.map((p) => p.paciente.id).toList(),
      );

      final brigadaCreada = await BrigadaService.crearBrigada(
        brigada: brigada,
        pacientesIds: _pacientesAgregados.map((p) => p.paciente.id).toList(),
        token: authProvider.token,
      );

      if (!brigadaCreada) {
        throw Exception('Error al crear la brigada');
      }

      // Asignar medicamentos a cada paciente
      for (final pacienteConMed in _pacientesAgregados) {
        final medicamentosData = pacienteConMed.medicamentos
            .map((m) => {
                  'medicamento_id': m.medicamento.id,
                  'dosis': m.dosis.trim(),
                  'cantidad': int.tryParse(m.cantidad.trim()) ?? 0,
                  'indicaciones': m.indicaciones.trim().isNotEmpty
                      ? m.indicaciones.trim()
                      : null,
                })
            .toList();

        await BrigadaService.asignarMedicamentosAPaciente(
          brigadaId: brigada.id,
          pacienteId: pacienteConMed.paciente.id,
          medicamentos: medicamentosData,
          token: authProvider.token,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Brigada creada con ${_pacientesAgregados.length} pacientes',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error: $e');
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
        title: const Text('Paso 2/3: Seleccionar Pacientes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Buscador
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar paciente',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _filtrarPacientes,
                  ),
                ),

                // Lista de pacientes
                Expanded(
                  child: _filteredPacientes.isEmpty
                      ? const Center(child: Text('No hay pacientes disponibles'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPacientes.length,
                          itemBuilder: (context, index) {
                            final paciente = _filteredPacientes[index];
                            final yaAgregado = _pacientesAgregados
                                .any((p) => p.paciente.id == paciente.id);

                            return Card(
                              color: yaAgregado ? Colors.green[100] : null,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      yaAgregado ? Colors.green : Colors.blue,
                                  child: Text(
                                    paciente.nombreCompleto[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  paciente.nombreCompleto,
                                  style: TextStyle(
                                    fontWeight: yaAgregado
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('ID: ${paciente.identificacion}'),
                                trailing: yaAgregado
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.arrow_forward),
                                onTap: () => _seleccionarPaciente(paciente),
                              ),
                            );
                          },
                        ),
                ),

                // Resumen de pacientes agregados
                if (_pacientesAgregados.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              '${_pacientesAgregados.length} pacientes agregados',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Lista resumida
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pacientesAgregados.length,
                            itemBuilder: (context, index) {
                              final item = _pacientesAgregados[index];
                              return Card(
                                color: Colors.green[50],
                                margin: const EdgeInsets.only(right: 8),
                                child: Container(
                                  width: 200,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.paciente.nombreCompleto,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 18, color: Colors.red),
                                            onPressed: () =>
                                                _eliminarPaciente(index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.medicamentos.length} medicamentos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botón guardar brigada
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _guardarBrigadaCompleta,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar Brigada Completa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ========================================
// 🆕 PANTALLA 3: MEDICAMENTOS DEL PACIENTE
// ========================================
class PantallaMedicamentosPaciente extends StatefulWidget {
  final Paciente paciente;

  const PantallaMedicamentosPaciente({
    Key? key,
    required this.paciente,
  }) : super(key: key);

  @override
  State<PantallaMedicamentosPaciente> createState() =>
      _PantallaMedicamentosPacienteState();
}

class _PantallaMedicamentosPacienteState
    extends State<PantallaMedicamentosPaciente> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();

  List<MedicamentoAsignado> _medicamentos = [];
  List<MedicamentoAsignado> _filteredMedicamentos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarMedicamentos() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await MedicamentoService.ensureMedicamentosLoaded(authProvider.token);

      final medicamentosDB = await _dbHelper.getAllMedicamentos();
      setState(() {
        _medicamentos = medicamentosDB
            .map((m) => MedicamentoAsignado(medicamento: m))
            .toList();
        _filteredMedicamentos = _medicamentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error: $e');
    }
  }

  void _filtrarMedicamentos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedicamentos = _medicamentos;
      } else {
        _filteredMedicamentos = _medicamentos.where((m) {
          return m.medicamento.nombmedicamento
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _mostrarDialogoDetalles(MedicamentoAsignado med) {
    final dosisController = TextEditingController(text: med.dosis);
    final cantidadController = TextEditingController(text: med.cantidad);
    final indicacionesController =
        TextEditingController(text: med.indicaciones);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(med.medicamento.nombmedicamento),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dosisController,
              decoration: const InputDecoration(
                labelText: 'Dosis *',
                hintText: 'Ej: 500mg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad *',
                hintText: 'Ej: 30',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: indicacionesController,
              decoration: const InputDecoration(
                labelText: 'Indicaciones',
                hintText: 'Opcional',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dosisController.text.trim().isEmpty ||
                  cantidadController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dosis y cantidad son requeridos'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() {
                med.isSelected = true;
                med.dosis = dosisController.text.trim();
                med.cantidad = cantidadController.text.trim();
                med.indicaciones = indicacionesController.text.trim();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _guardarMedicamentos() {
    final seleccionados =
        _medicamentos.where((m) => m.isSelected).toList();

    if (seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un medicamento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop(seleccionados);
  }

  @override
  Widget build(BuildContext context) {
    final seleccionados = _medicamentos.where((m) => m.isSelected).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paso 3/3: Medicamentos'),
            Text(
              widget.paciente.nombreCompleto,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Buscador
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar medicamento',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: seleccionados > 0
                          ? Chip(
                              label: Text('$seleccionados'),
                              backgroundColor: Colors.green,
                              labelStyle:
                                  const TextStyle(color: Colors.white),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _filtrarMedicamentos,
                  ),
                ),

                // Lista de medicamentos
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMedicamentos.length,
                    itemBuilder: (context, index) {
                      final med = _filteredMedicamentos[index];

                      return Card(
                        color: med.isSelected ? Colors.green[50] : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: Text(
                                med.medicamento.nombmedicamento,
                                style: TextStyle(
                                  fontWeight: med.isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              value: med.isSelected,
                              onChanged: (value) {
                                if (value == true) {
                                  _mostrarDialogoDetalles(med);
                                } else {
                                  setState(() {
                                    med.isSelected = false;
                                    med.dosis = '';
                                    med.cantidad = '';
                                    med.indicaciones = '';
                                  });
                                }
                              },
                              activeColor: Colors.green,
                            ),

                            if (med.isSelected)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Dosis: ${med.dosis}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Cantidad: ${med.cantidad}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 18),
                                          onPressed: () =>
                                              _mostrarDialogoDetalles(med),
                                        ),
                                      ],
                                    ),
                                    if (med.indicaciones.isNotEmpty)
                                      Text(
                                        'Indicaciones: ${med.indicaciones}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Botón guardar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarMedicamentos,
                      icon: const Icon(Icons.check),
                      label: Text('Guardar Medicamentos ($seleccionados)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
