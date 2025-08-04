import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/brigada_model.dart';
import '../models/paciente_model.dart';
import '../models/medicamento.dart';
import '../models/medicamento_con_indicaciones.dart';
import '../services/brigada_service.dart';
import '../providers/auth_provider.dart';
import 'asignar_medicamentos_brigada_screen.dart';

class DetalleBrigadaScreen extends StatefulWidget {
  final String brigadaId;

  const DetalleBrigadaScreen({
    Key? key,
    required this.brigadaId,
  }) : super(key: key);

  @override
  State<DetalleBrigadaScreen> createState() => _DetalleBrigadaScreenState();
}

class _DetalleBrigadaScreenState extends State<DetalleBrigadaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  Brigada? _brigada;
  List<Paciente> _pacientes = [];
  Map<String, List<Map<String, dynamic>>> _medicamentosPorPaciente = {};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarDetalleBrigada();
  }

  Future<void> _cargarDetalleBrigada() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Cargar brigada
      final brigada = await _dbHelper.getBrigadaById(widget.brigadaId);
      if (brigada == null) {
        throw Exception('Brigada no encontrada');
      }

      // Cargar pacientes de la brigada
      final pacientes = await _dbHelper.getPacientesDeBrigada(widget.brigadaId);

      // Cargar medicamentos por paciente
      Map<String, List<Map<String, dynamic>>> medicamentos = {};
      for (Paciente paciente in pacientes) {
        final medicamentosPaciente = await _dbHelper.getMedicamentosDePacienteEnBrigada(
          widget.brigadaId,
          paciente.id,
        );
        medicamentos[paciente.id] = medicamentosPaciente;
      }

      setState(() {
        _brigada = brigada;
        _pacientes = pacientes;
        _medicamentosPorPaciente = medicamentos;
        _isLoading = false;
      });

      debugPrint('✅ Detalle de brigada cargado: ${pacientes.length} pacientes');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar detalle: $e';
      });
      debugPrint('❌ Error cargando detalle de brigada: $e');
    }
  }

  Future<void> _asignarMedicamentosAPaciente(Paciente paciente) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AsignarMedicamentosBrigadaScreen(
          brigadaId: widget.brigadaId,
          paciente: paciente,
        ),
      ),
    );

    if (result == true) {
      _cargarDetalleBrigada();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_brigada?.tema ?? 'Detalle de Brigada'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _cargarDetalleBrigada,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando detalle de brigada...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDetalleBrigada,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_brigada == null) {
      return const Center(
        child: Text('Brigada no encontrada'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDetalleBrigada,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBrigada(),
          const SizedBox(height: 16),
          _buildPacientesSection(),
        ],
      ),
    );
  }

  Widget _buildInfoBrigada() {
    final formatter = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Información de la Brigada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _brigada!.syncStatus == 1 
                        ? Colors.green.shade100 
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _brigada!.syncStatus == 1 
                            ? Icons.cloud_done 
                            : Icons.cloud_upload,
                        size: 14,
                        color: _brigada!.syncStatus == 1 
                            ? Colors.green.shade700 
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _brigada!.syncStatus == 1 ? 'Sincronizada' : 'Pendiente',
                        style: TextStyle(
                          fontSize: 10,
                          color: _brigada!.syncStatus == 1 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Tema', _brigada!.tema),
            _buildInfoRow('Lugar', _brigada!.lugarEvento),
            _buildInfoRow('Fecha', formatter.format(_brigada!.fechaBrigada)),
            _buildInfoRow('Conductor', _brigada!.nombreConductor),
            _buildInfoRow('Usuarios HTA', _brigada!.usuariosHta),
            _buildInfoRow('Usuarios DN', _brigada!.usuariosDn),
            _buildInfoRow('Usuarios HTA RCU', _brigada!.usuariosHtaRcu),
            _buildInfoRow('Usuarios DM RCU', _brigada!.usuariosDmRcu),
            
            if (_brigada!.observaciones != null && _brigada!.observaciones!.isNotEmpty)
              _buildInfoRow('Observaciones', _brigada!.observaciones!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacientesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Pacientes Asignados (${_pacientes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_pacientes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No hay pacientes asignados a esta brigada',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_pacientes.map((paciente) => _buildPacienteCard(paciente))),
          ],
        ),
      ),
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    final medicamentos = _medicamentosPorPaciente[paciente.id] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    paciente.nombre[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
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
                        paciente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${paciente.identificacion} | ${paciente.genero}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _asignarMedicamentosAPaciente(paciente),
                  icon: const Icon(Icons.medication),
                  tooltip: 'Asignar medicamentos',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            
            if (medicamentos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${medicamentos.length} medicamentos asignados:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...medicamentos.map((med) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med['nombmedicamento'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (med['dosis'] != null && med['dosis'].toString().isNotEmpty)
                                  Text(
                                    'Dosis: ${med['dosis']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (med['cantidad'] != null)
                                  Text(
                                    'Cantidad: ${med['cantidad']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (med['indicaciones'] != null && med['indicaciones'].toString().isNotEmpty)
                                  Text(
                                    'Indicaciones: ${med['indicaciones']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sin medicamentos asignados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _asignarMedicamentosAPaciente(paciente),
                      child: const Text('Asignar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

        
