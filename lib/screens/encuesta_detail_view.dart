// views/encuesta_detail_view.dart
import 'package:flutter/material.dart';
import 'package:Bornive/models/encuesta_model.dart';

class EncuestaDetailView extends StatelessWidget {
  final Encuesta encuesta;

  const EncuestaDetailView({
    Key? key,
    required this.encuesta,
  }) : super(key: key);

  // 🎨 TEMA DE COLORES UNIFICADO
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryLightColor = Color(0xFF5E92F3);
  static const Color primaryDarkColor = Color(0xFF003C8F);
  static const Color accentColor = Color(0xFF00C853);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          shadowColor: Colors.black12,
        ),
      ),
      child: Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          title: const Text('Detalle de Encuesta'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  encuesta.syncStatus == 1 ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                  color: encuesta.syncStatus == 1 ? Colors.white : Colors.white70,
                ),
                onPressed: null,
                tooltip: encuesta.syncStatus == 1 ? 'Sincronizada' : 'Pendiente de sincronización',
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildCalificationResponses(),
              const SizedBox(height: 24),
              _buildAdditionalResponses(),
              if (encuesta.sugerencias != null && encuesta.sugerencias!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSuggestions(),
              ],
              const SizedBox(height: 24),
              _buildSyncStatus(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.1),
              primaryLightColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, primaryLightColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Encuesta de Satisfacción',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Text(
                'ID: ${encuesta.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Información Básica', Icons.info_outline, primaryColor),
            const SizedBox(height: 20),
            _buildModernInfoRow(Icons.home_outlined, 'Domicilio', encuesta.domicilio, primaryColor),
            const SizedBox(height: 16),
            _buildModernInfoRow(Icons.business_outlined, 'Entidad Afiliada', encuesta.entidadAfiliada, primaryColor),
            const SizedBox(height: 16),
            _buildModernInfoRow(
              Icons.calendar_today_outlined, 
              'Fecha', 
              '${encuesta.fecha.day.toString().padLeft(2, '0')}/${encuesta.fecha.month.toString().padLeft(2, '0')}/${encuesta.fecha.year}',
              primaryColor,
            ),
           
          ],
        ),
      ),
    );
  }

  Widget _buildCalificationResponses() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Respuestas de Calificación', Icons.star_rate_outlined, accentColor),
            const SizedBox(height: 8),
            const Text(
              'Evaluación de los servicios recibidos',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ...Encuesta.preguntasCalificacion.asMap().entries.map((entry) {
              int index = entry.key;
              String pregunta = entry.value;
              String respuesta = encuesta.respuestasCalificacion['pregunta_$index'] ?? 'Sin respuesta';
              
              return _buildQuestionCard(index + 1, pregunta, respuesta, true);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalResponses() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Respuestas Adicionales', Icons.help_outline, warningColor),
            const SizedBox(height: 8),
            const Text(
              'Preguntas específicas complementarias',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ...Encuesta.preguntasAdicionales.asMap().entries.map((entry) {
              int index = entry.key;
              String pregunta = entry.value;
              String respuesta = encuesta.respuestasAdicionales['pregunta_$index'] ?? 'Sin respuesta';
              
              return _buildQuestionCard(index + 1, pregunta, respuesta, false);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int numero, String pregunta, String respuesta, bool isCalification) {
    final Color cardColor = isCalification ? accentColor : warningColor;
    final Color responseColor = isCalification ? _getColorForResponse(respuesta) : warningColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pregunta,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textPrimaryColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [responseColor, responseColor.withOpacity(0.8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: responseColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForResponse(respuesta, isCalification),
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            respuesta,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Sugerencias y Comentarios', Icons.comment_outlined, Colors.purple[600]!),
            const SizedBox(height: 8),
            const Text(
              'Observaciones adicionales del paciente',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: Colors.purple[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comentario del paciente',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    encuesta.sugerencias!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    final bool isSynced = encuesta.syncStatus == 1;
    final Color statusColor = isSynced ? successColor : warningColor;
    final IconData statusIcon = isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded;
    final String statusText = isSynced ? 'Sincronizada con el servidor' : 'Pendiente de sincronización';
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Estado de Sincronización', Icons.sync_outlined, statusColor),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSynced 
                            ? 'Los datos están actualizados en el servidor'
                            : 'Se sincronizará automáticamente cuando haya conexión',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (encuesta.createdAt != null || encuesta.updatedAt != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  children: [
                    if (encuesta.createdAt != null) ...[
                      _buildTimestampRow(
                        Icons.add_circle_outline,
                        'Fecha de creación',
                        _formatDateTime(encuesta.createdAt!),
                        primaryColor,
                      ),
                    ],
                    if (encuesta.updatedAt != null && encuesta.createdAt != null) ...[
                      const SizedBox(height: 12),
                      Divider(color: dividerColor, height: 1),
                      const SizedBox(height: 12),
                    ],
                    if (encuesta.updatedAt != null) ...[
                      _buildTimestampRow(
                        Icons.update_outlined,
                        'Última actualización',
                        _formatDateTime(encuesta.updatedAt!),
                        accentColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForResponse(String respuesta) {
    switch (respuesta.toLowerCase()) {
      case 'excelente':
        return successColor;
      case 'bueno':
        return primaryColor;
      case 'regular':
        return warningColor;
      case 'malo':
        return errorColor;
      case 'sí':
      case 'si':
        return successColor;
      case 'no':
        return errorColor;
      default:
        return textSecondaryColor;
    }
  }

  IconData _getIconForResponse(String respuesta, bool isCalification) {
    if (isCalification) {
      switch (respuesta.toLowerCase()) {
        case 'excelente':
          return Icons.sentiment_very_satisfied_rounded;
        case 'bueno':
          return Icons.sentiment_satisfied_rounded;
        case 'regular':
          return Icons.sentiment_neutral_rounded;
        case 'malo':
          return Icons.sentiment_dissatisfied_rounded;
        default:
          return Icons.help_outline;
      }
    } else {
      switch (respuesta.toLowerCase()) {
        case 'sí':
        case 'si':
          return Icons.check_circle_outline;
        case 'no':
          return Icons.cancel_outlined;
        default:
          return Icons.radio_button_checked;
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    const List<String> months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
