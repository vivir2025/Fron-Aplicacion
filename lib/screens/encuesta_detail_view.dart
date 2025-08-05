// views/encuesta_detail_view.dart
import 'package:flutter/material.dart';
import 'package:fnpv_app/models/encuesta_model.dart';

class EncuestaDetailView extends StatelessWidget {
  final Encuesta encuesta;

  const EncuestaDetailView({
    Key? key,
    required this.encuesta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Encuesta'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 20),
            _buildCalificationResponses(),
            const SizedBox(height: 20),
            _buildAdditionalResponses(),
            if (encuesta.sugerencias != null && encuesta.sugerencias!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSuggestions(),
            ],
            const SizedBox(height: 20),
            _buildSyncStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('ID:', encuesta.id),
            _buildInfoRow('Domicilio:', encuesta.domicilio),
            _buildInfoRow('Entidad Afiliada:', encuesta.entidadAfiliada),
            _buildInfoRow('Fecha:', '${encuesta.fecha.day}/${encuesta.fecha.month}/${encuesta.fecha.year}'),
            _buildInfoRow('Paciente ID:', encuesta.idpaciente),
            _buildInfoRow('Sede ID:', encuesta.idsede),
          ],
        ),
      ),
    );
  }

  Widget _buildCalificationResponses() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Respuestas de Calificación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 10),
            ...Encuesta.preguntasCalificacion.asMap().entries.map((entry) {
              int index = entry.key;
              String pregunta = entry.value;
              String respuesta = encuesta.respuestasCalificacion['pregunta_$index'] ?? 'Sin respuesta';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pregunta,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getColorForResponse(respuesta),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        respuesta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalResponses() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Respuestas Adicionales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 10),
            ...Encuesta.preguntasAdicionales.asMap().entries.map((entry) {
              int index = entry.key;
              String pregunta = entry.value;
              String respuesta = encuesta.respuestasAdicionales['pregunta_$index'] ?? 'Sin respuesta';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pregunta,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        respuesta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sugerencias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                encuesta.sugerencias!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Sincronización',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  encuesta.syncStatus == 1 ? Icons.cloud_done : Icons.cloud_upload,
                  color: encuesta.syncStatus == 1 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  encuesta.syncStatus == 1 ? 'Sincronizada' : 'Pendiente de sincronización',
                  style: TextStyle(
                    color: encuesta.syncStatus == 1 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (encuesta.createdAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Creada:', _formatDateTime(encuesta.createdAt!)),
            ],
            if (encuesta.updatedAt != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow('Actualizada:', _formatDateTime(encuesta.updatedAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getColorForResponse(String respuesta) {
    switch (respuesta.toLowerCase()) {
      case 'excelente':
        return Colors.green;
      case 'bueno':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'malo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
