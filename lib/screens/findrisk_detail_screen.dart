// screens/findrisk/findrisk_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/findrisk_test_model.dart';
import '../../models/paciente_model.dart';
import '../../services/findrisk_service.dart';
import '../../database/database_helper.dart';

const Color primaryColor = Color(0xFF1B5E20);

class FindriskDetailScreen extends StatefulWidget {
  final FindriskTest test;

  const FindriskDetailScreen({
    Key? key,
    required this.test,
  }) : super(key: key);

  @override
  State<FindriskDetailScreen> createState() => _FindriskDetailScreenState();
}

class _FindriskDetailScreenState extends State<FindriskDetailScreen> {
  Paciente? _paciente;
  Map<String, dynamic>? _sede;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // Cargar datos del paciente
      final paciente = await dbHelper.getPacienteById(widget.test.idpaciente);
      
      // Cargar datos de la sede
      final sedes = await dbHelper.getSedes();
      final sede = sedes.firstWhere(
        (s) => s['id'] == widget.test.idsede,
        orElse: () => <String, dynamic>{},
      );

      setState(() {
        _paciente = paciente;
        _sede = sede.isNotEmpty ? sede : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error cargando datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final interpretacion = widget.test.interpretarRiesgo();
    final color = Color(interpretacion['color']);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Detalle Test FINDRISK',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareTest,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _confirmDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resultado principal
                  _buildResultCard(interpretacion, color),
                  
                  SizedBox(height: 16),
                  
                  // Información del paciente
                  _buildPatientInfo(),
                  
                  SizedBox(height: 16),
                  
                  // Detalles del test
                  _buildTestDetails(),
                  
                  SizedBox(height: 16),
                  
                  // Desglose de puntajes
                  _buildScoreBreakdown(),
                  
                  SizedBox(height: 16),
                  
                  // Información adicional
                  _buildAdditionalInfo(),
                  
                  SizedBox(height: 16),
                  
                  // Estado de sincronización
                  _buildSyncStatus(),
                ],
              ),
            ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> interpretacion, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.test.puntajeFinal.toString(),
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Puntaje Total',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${widget.test.puntajeFinal} puntos',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel de Riesgo: ${interpretacion['nivel']}',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Probabilidad: ${interpretacion['riesgo']}',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    interpretacion['descripcion'],
                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    if (_paciente == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600]),
              SizedBox(width: 8),
              Text('No se pudo cargar la información del paciente', style: GoogleFonts.roboto()),
            ],
          ),
        ),
      );
    }

    final edad = DateTime.now().year - _paciente!.fecnacimiento.year;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  'Información del Paciente',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow('Identificación', _paciente!.identificacion),
            _buildInfoRow('Nombre', _paciente!.nombreCompleto),
            _buildInfoRow('Género', _paciente!.genero),
            _buildInfoRow('Edad', '$edad años'),
            _buildInfoRow('Fecha de nacimiento', _formatDate(_paciente!.fecnacimiento)),
            if (_sede != null)
              _buildInfoRow('Sede', _sede!['nombresede'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDetails() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  'Detalles del Test',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Datos físicos
            _buildSectionTitle('Datos Físicos'),
            _buildInfoRow('Peso', '${widget.test.peso} kg'),
            _buildInfoRow('Talla', '${widget.test.talla} cm'),
            _buildInfoRow('IMC', widget.test.imc.toStringAsFixed(2)),
            _buildInfoRow('Perímetro Abdominal', '${widget.test.perimetroAbdominal} cm'),
            
            SizedBox(height: 16),
            
            // Respuestas
            _buildSectionTitle('Respuestas'),
            _buildInfoRow(
              '¿Realiza actividad física?',
              widget.test.actividadFisica == 'si' ? 'Sí' : 'No',
            ),
            _buildInfoRow(
              '¿Medicamentos para hipertensión?',
              widget.test.medicamentosHipertension == 'si' ? 'Sí' : 'No',
            ),
            _buildInfoRow(
              '¿Come frutas y verduras diariamente?',
              widget.test.frecuenciaFrutasVerduras == 'diariamente' ? 'Sí' : 'No',
            ),
            _buildInfoRow(
              '¿Azúcar alto detectado?',
              widget.test.azucarAltoDetectado == 'si' ? 'Sí' : 'No',
            ),
            _buildInfoRow(
              'Antecedentes familiares',
              _getAntecedentesText(widget.test.antecedentesFamiliares),
            ),
            
            if (widget.test.vereda != null) ...[
              SizedBox(height: 16),
              _buildSectionTitle('Información Adicional'),
              _buildInfoRow('Vereda', widget.test.vereda!),
            ],
            
            if (widget.test.telefono != null)
              _buildInfoRow('Teléfono', widget.test.telefono!),
            
            if (widget.test.promotorVida != null)
              _buildInfoRow('Promotor de Vida', widget.test.promotorVida!),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  'Desglose de Puntajes',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            _buildScoreRow('Edad', widget.test.puntajeEdad),
            _buildScoreRow('IMC', widget.test.puntajeImc),
            _buildScoreRow('Perímetro Abdominal', widget.test.puntajePerimetro),
            _buildScoreRow('Actividad Física', widget.test.puntajeActividadFisica),
            _buildScoreRow('Frutas y Verduras', widget.test.puntajeFrutasVerduras),
            _buildScoreRow('Medicamentos', widget.test.puntajeMedicamentos),
            _buildScoreRow('Azúcar Alto', widget.test.puntajeAzucarAlto),
            _buildScoreRow('Antecedentes Familiares', widget.test.puntajeAntecedentes),
            
            const Divider(),
            
            _buildScoreRow(
              'TOTAL',
              widget.test.puntajeFinal,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    if (widget.test.conducta == null || widget.test.conducta!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  'Conducta/Recomendaciones',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              widget.test.conducta!,
              style: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    final isSynced = widget.test.syncStatus == 1;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSynced ? Icons.cloud_done : Icons.sync_problem,
              color: isSynced ? Colors.green[600] : Colors.orange[600],
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSynced ? 'Sincronizado' : 'Pendiente de sincronización',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: isSynced ? Colors.green[600] : Colors.orange[600],
                    ),
                  ),
                  Text(
                    'Creado: ${_formatDateTime(widget.test.createdAt)}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.test.updatedAt != widget.test.createdAt)
                    Text(
                      'Actualizado: ${_formatDateTime(widget.test.updatedAt)}',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey[600],
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
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int points, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isTotal ? primaryColor.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$points pts',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: isTotal ? primaryColor : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAntecedentesText(String antecedentes) {
    switch (antecedentes) {
      case 'no':
        return 'No';
      case 'abuelos_tios_primos':
        return 'Sí: abuelos, tíos, primos hermanos';
      case 'padres_hermanos_hijos':
        return 'Sí: padres, hermanos, hijos';
      default:
        return antecedentes;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareTest() {
    // Implementar funcionalidad de compartir
    final interpretacion = widget.test.interpretarRiesgo();
    final text = '''
Test FINDRISK - Resultado

Puntaje Total: ${widget.test.puntajeFinal} puntos
Nivel de Riesgo: ${interpretacion['nivel']}
Probabilidad: ${interpretacion['riesgo']}

${interpretacion['descripcion']}

Realizado el: ${_formatDateTime(widget.test.createdAt)}
    ''';
    
    // Aquí puedes usar el paquete share_plus para compartir
    debugPrint('Compartir: $text');
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro de que desea eliminar este test FINDRISK? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTest();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTest() async {
    try {
      final success = await FindriskService.eliminarTest(widget.test.id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el test'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
