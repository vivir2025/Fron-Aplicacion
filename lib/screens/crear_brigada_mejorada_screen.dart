// screens/crear_brigada_mejorada_screen.dart
// ✅ FLUJO CON PANTALLAS SEPARADAS
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

const Color primaryColor = Color(0xFF1B5E20);

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
              primary: primaryColor,
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

  InputDecoration _buildInputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: icon != null 
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Nueva Brigada',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  primaryColor,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
      ),
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
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Información de la Brigada',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _temaController,
                          decoration: _buildInputDecoration('Tema de la Brigada *', Icons.topic),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _lugarEventoController,
                          decoration: _buildInputDecoration('Lugar del Evento *', Icons.location_on),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        SizedBox(height: 12),
                        
                        InkWell(
                          onTap: _seleccionarFecha,
                          child: InputDecorator(
                            decoration: _buildInputDecoration('Fecha de la Brigada', Icons.calendar_today),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_fechaBrigada),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _nombreConductorController,
                          decoration: _buildInputDecoration('Nombre del Conductor *', Icons.person),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        SizedBox(height: 16),
                        
                        const Divider(),
                        SizedBox(height: 8),
                        Text(
                          'Información de Usuarios',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosHtaController,
                                decoration: _buildInputDecoration('Usuarios HTA *'),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosDnController,
                                decoration: _buildInputDecoration('Usuarios DM *'),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosHtaRcuController,
                                decoration: _buildInputDecoration('HTA RCU'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _usuariosDmRcuController,
                                decoration: _buildInputDecoration('DM RCU'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _observacionesController,
                          decoration: _buildInputDecoration('Observaciones', Icons.note),
                          maxLines: 3,
                        ),
                        SizedBox(height: 24),
                        
                        // Botón Siguiente
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _irAPantallaPacientes,
                            icon: Icon(Icons.arrow_forward),
                            label: Text('Siguiente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.all(16),
                              textStyle: GoogleFonts.roboto(
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
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _eliminarPaciente(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        content: Text(
          '¿Eliminar a ${_pacientesAgregados[index].paciente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pacientesAgregados.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
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
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Seleccionar Pacientes',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  primaryColor,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                      prefixIcon: Icon(Icons.search),
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
                      ? Center(child: Text('No hay pacientes disponibles'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPacientes.length,
                          itemBuilder: (context, index) {
                            final paciente = _filteredPacientes[index];
                            final yaAgregado = _pacientesAgregados
                                .any((p) => p.paciente.id == paciente.id);

                            return Card(
                              color: yaAgregado ? primaryColor.withOpacity(0.1) : null,
                              margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      yaAgregado ? primaryColor : Colors.blue,
                                  child: Text(
                                    paciente.nombreCompleto[0].toUpperCase(),
                                    style: GoogleFonts.roboto(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  paciente.nombreCompleto,
                                  style: GoogleFonts.roboto(
                                    fontWeight: yaAgregado
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
          'ID: ${paciente.identificacion}',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
                                trailing: yaAgregado
                                    ? Icon(Icons.check_circle,
                                        color: primaryColor)
                                    : Icon(Icons.arrow_forward),
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
                            Icon(Icons.people, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '${_pacientesAgregados.length} pacientes agregados',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Lista resumida
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pacientesAgregados.length,
                            itemBuilder: (context, index) {
                              final item = _pacientesAgregados[index];
                              return Card(
                                color: primaryColor.withOpacity(0.05),
                                margin: const EdgeInsets.only(right: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
      ),
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
                                              style: GoogleFonts.roboto(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                size: 18, color: Colors.red),
                                            onPressed: () =>
                                                _eliminarPaciente(index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${item.medicamentos.length} medicamentos',
                                        style: GoogleFonts.roboto(
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

                        SizedBox(height: 12),

                        // Botón guardar brigada
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _guardarBrigadaCompleta,
                            icon: Icon(Icons.save),
                            label: Text('Guardar Brigada Completa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.all(16),
                              textStyle: GoogleFonts.roboto(
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
    final formKey = GlobalKey<FormState>();

    InputDecoration buildInputDecor(String label, IconData icon, {String? hintText}) {
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.roboto(
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medication_liquid_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                med.medicamento.nombmedicamento,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: dosisController,
                style: GoogleFonts.roboto(),
                decoration: buildInputDecor('Dosis *', Icons.medication_liquid, hintText: 'Ej: 500mg'),
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cantidadController,
                style: GoogleFonts.roboto(),
                decoration: buildInputDecor('Cantidad *', Icons.numbers, hintText: 'Ej: 30'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Requerido';
                  if (int.tryParse(v.trim()) == null || int.parse(v.trim()) <= 0) return 'Número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: indicacionesController,
                style: GoogleFonts.roboto(),
                decoration: buildInputDecor('Indicaciones', Icons.note_alt, hintText: 'Opcional'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text('Cancelar', style: GoogleFonts.roboto()),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  med.isSelected = true;
                  med.dosis = dosisController.text.trim();
                  med.cantidad = cantidadController.text.trim();
                  med.indicaciones = indicacionesController.text.trim();
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Por favor, complete los campos correctamente', style: GoogleFonts.roboto()),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Guardar', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            Text('Seleccionar Medicamentos'),
            Text(
              widget.paciente.nombreCompleto,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  primaryColor,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: seleccionados > 0
                          ? Chip(
                              label: Text('$seleccionados'),
                              backgroundColor: primaryColor,
                              elevation: 0,
                              labelStyle:
                                  GoogleFonts.roboto(color: Colors.white),
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
                        color: med.isSelected ? primaryColor.withOpacity(0.05) : null,
                        margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
                          children: [
                            CheckboxListTile(
                              title: Text(
                                med.medicamento.nombmedicamento,
                                style: GoogleFonts.roboto(
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
                              activeColor: primaryColor,
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
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Cantidad: ${med.cantidad}',
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              size: 18),
                                          onPressed: () =>
                                              _mostrarDialogoDetalles(med),
                                        ),
                                      ],
                                    ),
                                    if (med.indicaciones.isNotEmpty)
                                      Text(
                                        'Indicaciones: ${med.indicaciones}',
                                        style: GoogleFonts.roboto(
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
                      icon: Icon(Icons.check),
                      label: Text('Guardar Medicamentos ($seleccionados)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.all(16),
                        textStyle: GoogleFonts.roboto(
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
