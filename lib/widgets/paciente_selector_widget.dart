// lib/widgets/paciente_selector_widget.dart
import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../database/database_helper.dart';

class PacienteSelectorWidget extends StatefulWidget {
  final Function(Paciente) onPacienteSelected;
  final bool enabled;
  final Paciente? pacienteInicial;

  const PacienteSelectorWidget({
    Key? key,
    required this.onPacienteSelected,
    this.enabled = true,
    this.pacienteInicial,
  }) : super(key: key);

  @override
  State<PacienteSelectorWidget> createState() => _PacienteSelectorWidgetState();
}

class _PacienteSelectorWidgetState extends State<PacienteSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  bool _isLoading = false;
  Paciente? _pacienteSeleccionado;

  @override
  void initState() {
    super.initState();
    _pacienteSeleccionado = widget.pacienteInicial;
    if (_pacienteSeleccionado != null) {
      _searchController.text = _pacienteSeleccionado!.nombreCompleto;
    }
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    setState(() => _isLoading = true);
    
    try {
      final pacientes = await DatabaseHelper.instance.readAllPacientes(); // Usar método correcto
      setState(() {
        _pacientes = pacientes;
        _pacientesFiltrados = pacientes;
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
        _pacientesFiltrados = _pacientes;
      } else {
        _pacientesFiltrados = _pacientes.where((paciente) {
          return paciente.nombreCompleto.toLowerCase().contains(query.toLowerCase()) ||
                 paciente.identificacion.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled && _pacienteSeleccionado != null) {
      return _buildPacienteSeleccionado();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda
        TextFormField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar paciente *',
            hintText: 'Nombre o identificación...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            _filtrarPacientes(value);
            // Si el campo se limpia y había un paciente seleccionado, limpiarlo
            if (value.isEmpty && _pacienteSeleccionado != null) {
              setState(() {
                _pacienteSeleccionado = null;
              });
            }
          },
          validator: (value) {
            if (_pacienteSeleccionado == null) {
              return 'Debe seleccionar un paciente';
            }
            return null;
          },
          enabled: widget.enabled,
        ),
        
        const SizedBox(height: 8),
        
        // Lista de pacientes filtrados
        if (_searchController.text.isNotEmpty && _pacienteSeleccionado == null)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _pacientesFiltrados.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No se encontraron pacientes',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _pacientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final paciente = _pacientesFiltrados[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                paciente.nombreCompleto.isNotEmpty 
                                    ? paciente.nombreCompleto.substring(0, 1).toUpperCase()
                                    : 'P',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ),
                            title: Text(paciente.nombreCompleto),
                            subtitle: Text('ID: ${paciente.identificacion}'),
                            onTap: () {
                              setState(() {
                                _pacienteSeleccionado = paciente;
                                _searchController.text = paciente.nombreCompleto;
                                _pacientesFiltrados = []; // Limpiar lista
                              });
                              widget.onPacienteSelected(paciente);
                            },
                          );
                        },
                      ),
          ),
        
        // Paciente seleccionado
        if (_pacienteSeleccionado != null)
          _buildPacienteSeleccionado(),
      ],
    );
  }

  Widget _buildPacienteSeleccionado() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paciente seleccionado:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
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
          if (widget.enabled)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _pacienteSeleccionado = null;
                  _searchController.clear();
                  _pacientesFiltrados = _pacientes;
                });
              },
              tooltip: 'Limpiar selección',
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
