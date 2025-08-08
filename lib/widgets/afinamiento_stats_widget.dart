import 'package:flutter/material.dart';
import '../services/afinamiento_service.dart';

class AfinamientoStatsWidget extends StatefulWidget {
  final String? usuarioId;
  
  const AfinamientoStatsWidget({
    Key? key,
    this.usuarioId,
  }) : super(key: key);

  @override
  State<AfinamientoStatsWidget> createState() => _AfinamientoStatsWidgetState();
}

class _AfinamientoStatsWidgetState extends State<AfinamientoStatsWidget> {
  Map<String, dynamic> _estadisticas = {
    'total': 0,
    'sincronizados': 0,
    'pendientes': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    
    try {
      final estadisticas = await AfinamientoService.obtenerEstadisticas();
      setState(() {
        _estadisticas = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
                  icon: const Icon(Icons.refresh),
                  onPressed: _cargarEstadisticas,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadistica(
                  'Total',
                  _estadisticas['total'].toString(),
                  Colors.blue,
                  Icons.medical_services,
                ),
                _buildEstadistica(
                  'Sincronizados',
                  _estadisticas['sincronizados'].toString(),
                  Colors.green,
                  Icons.cloud_done,
                ),
                _buildEstadistica(
                  'Pendientes',
                  _estadisticas['pendientes'].toString(),
                  Colors.orange,
                  Icons.cloud_upload,
                ),
              ],
            ),
            
            if (_estadisticas['total'] > 0) ...[
              const SizedBox(height: 16),
              _buildBarraProgreso(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadistica(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBarraProgreso() {
    final total = _estadisticas['total'] as int;
    final sincronizados = _estadisticas['sincronizados'] as int;
    final porcentaje = total > 0 ? (sincronizados / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de Sincronización',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(porcentaje * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: porcentaje,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            porcentaje == 1.0 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }
}
