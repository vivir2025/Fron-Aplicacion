// afinamiento_paciente_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/afinamiento_model.dart';
import '../services/afinamiento_service.dart';
import '../screens/crear_afinamiento_screen.dart';
import '../screens/detalle_afinamiento_screen.dart';

class AfinamientoPacienteWidget extends StatefulWidget {
  final String pacienteId;
  final String nombrePaciente;

  const AfinamientoPacienteWidget({
    Key? key,
    required this.pacienteId,
    required this.nombrePaciente,
  }) : super(key: key);

  @override
  State<AfinamientoPacienteWidget> createState() => _AfinamientoPacienteWidgetState();
}

class _AfinamientoPacienteWidgetState extends State<AfinamientoPacienteWidget> {
  List<Afinamiento> _afinamientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAfinamientos();
  }

  Future<void> _cargarAfinamientos() async {
    setState(() => _isLoading = true);
    
    try {
      final afinamientos = await AfinamientoService.obtenerAfinamientosPorPaciente(widget.pacienteId);
      setState(() {
        _afinamientos = afinamientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Afinamientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CrearAfinamientoScreen(
                          pacienteId: widget.pacienteId,
                        ),
                      ),
                    );
                    
                    if (result == true) {
                      _cargarAfinamientos();
                    }
                  },
                  tooltip: 'Nuevo afinamiento',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_afinamientos.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      'No hay afinamientos registrados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _afinamientos.take(3).map((afinamiento) {
                  return _buildAfinamientoItem(afinamiento);
                }).toList(),
              ),
            
            if (_afinamientos.length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/afinamientos',
                    arguments: {'pacienteId': widget.pacienteId},
                  );
                },
                child: Text('Ver todos (${_afinamientos.length})'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAfinamientoItem(Afinamiento afinamiento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleAfinamientoScreen(
                afinamientoId: afinamiento.id,
              ),
            ),
          );
          
          if (result == true) {
            _cargarAfinamientos();
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: afinamiento.estaSincronizado ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                afinamiento.estaSincronizado ? Icons.cloud_done : Icons.cloud_upload,
                size: 16,
                color: afinamiento.estaSincronizado ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(afinamiento.fechaTamizaje),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    afinamiento.procedencia,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            if (afinamiento.tienePromedios)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Text(
                  afinamiento.promedioFormateado,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
