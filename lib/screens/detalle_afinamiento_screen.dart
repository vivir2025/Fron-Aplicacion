import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/afinamiento_model.dart';
import '../models/paciente_model.dart';
import '../services/afinamiento_service.dart';
import '../database/database_helper.dart';
import 'crear_afinamiento_screen.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF1B5E20);

class DetalleAfinamientoScreen extends StatefulWidget {
  final String afinamientoId;

  const DetalleAfinamientoScreen({
    Key? key,
    required this.afinamientoId,
  }) : super(key: key);

  @override
  State<DetalleAfinamientoScreen> createState() => _DetalleAfinamientoScreenState();
}

class _DetalleAfinamientoScreenState extends State<DetalleAfinamientoScreen> {
  Afinamiento? _afinamiento;
  Paciente? _paciente;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final afinamiento = await AfinamientoService.obtenerAfinamientoPorId(widget.afinamientoId);
      
      if (afinamiento == null) {
        setState(() {
          _error = 'Afinamiento no encontrado';
          _isLoading = false;
        });
        return;
      }

      final paciente = await DatabaseHelper.instance.getPacienteById(afinamiento.idpaciente);

      setState(() {
        _afinamiento = afinamiento;
        _paciente = paciente;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Detalle del Afinamiento',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_afinamiento != null)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrearAfinamientoScreen(
                      afinamientoExistente: _afinamiento,
                    ),
                  ),
                );
                
                if (result == true) {
                  _cargarDatos();
                }
              },
              tooltip: 'Editar',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _afinamiento == null
                  ? _buildNotFoundState()
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Estado de sincronización
                            _buildEstadoSincronizacion(),
                            
                            SizedBox(height: 16),
                            
                            // Información del paciente
                            if (_paciente != null) _buildInformacionPaciente(),
                            
                            SizedBox(height: 16),
                            
                            // Información del tamizaje
                            _buildInformacionTamizaje(),
                            
                            SizedBox(height: 16),
                            
                            // Afinamientos realizados
                            _buildAfinamientosRealizados(),
                            
                            SizedBox(height: 16),
                            
                            // Promedios
                            if (_afinamiento!.tienePromedios) _buildPromedios(),
                            
                            SizedBox(height: 16),
                            
                            // Conducta
                            if (_afinamiento!.conducta != null && _afinamiento!.conducta!.isNotEmpty)
                              _buildConducta(),
                            
                            SizedBox(height: 16),
                            
                            // Información adicional
                            _buildInformacionAdicional(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarDatos,
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Afinamiento no encontrado',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoSincronizacion() {
    final estaSincronizado = _afinamiento!.estaSincronizado;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estaSincronizado ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estaSincronizado ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            estaSincronizado ? Icons.cloud_done : Icons.cloud_upload,
            color: estaSincronizado ? Colors.green[700] : Colors.orange[700],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estaSincronizado ? 'Sincronizado' : 'Pendiente de sincronización',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: estaSincronizado ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  estaSincronizado
                      ? 'Los datos están guardados en el servidor'
                      : 'Los datos se sincronizarán cuando haya conexión',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionPaciente() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Paciente',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Icon(Icons.person, color: primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paciente!.nombreCompleto,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Identificación: ${_paciente!.identificacion}',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Género: ${_paciente!.genero}',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacionTamizaje() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Tamizaje',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildInfoRow(
              Icons.location_on,
              'Procedencia',
              _afinamiento!.procedencia,
            ),
            
            SizedBox(height: 12),
            
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de Tamizaje',
              DateFormat('dd/MM/yyyy').format(_afinamiento!.fechaTamizaje),
            ),
            
            SizedBox(height: 12),
            
            _buildInfoRow(
              Icons.favorite,
              'Presión Arterial Tamizaje',
              _afinamiento!.presionArterialTamiz,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfinamientosRealizados() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Afinamientos Realizados',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Primer afinamiento
            if (_afinamiento!.primerAfinamientoFecha != null)
              _buildAfinamientoDetalle(
                numero: 1,
                fecha: _afinamiento!.primerAfinamientoFecha!,
                sistolica: _afinamiento!.presionSistolica1,
                diastolica: _afinamiento!.presionDiastolica1,
              ),
            
            // Segundo afinamiento
            if (_afinamiento!.segundoAfinamientoFecha != null) ...[
              SizedBox(height: 12),
              _buildAfinamientoDetalle(
                numero: 2,
                fecha: _afinamiento!.segundoAfinamientoFecha!,
                sistolica: _afinamiento!.presionSistolica2,
                diastolica: _afinamiento!.presionDiastolica2,
              ),
            ],
            
            // Tercer afinamiento
            if (_afinamiento!.tercerAfinamientoFecha != null) ...[
              SizedBox(height: 12),
              _buildAfinamientoDetalle(
                numero: 3,
                fecha: _afinamiento!.tercerAfinamientoFecha!,
                sistolica: _afinamiento!.presionSistolica3,
                diastolica: _afinamiento!.presionDiastolica3,
              ),
            ],
            
            if (_afinamiento!.primerAfinamientoFecha == null &&
                _afinamiento!.segundoAfinamientoFecha == null &&
                _afinamiento!.tercerAfinamientoFecha == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text(
                      'No se han realizado afinamientos aún',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
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

  Widget _buildAfinamientoDetalle({
    required int numero,
    required DateTime fecha,
    required int? sistolica,
    required int? diastolica,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                numero.toString(),
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Afinamiento $numero',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(fecha),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          if (sistolica != null && diastolica != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor),
              ),
              child: Text(
                '$sistolica/$diastolica',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            )
          else
            Text(
              'Sin datos',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromedios() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promedios Calculados',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
                           padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.05), primaryColor.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: Colors.red[600],
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sistólica',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _afinamiento!.presionSistolicaPromedio!.toStringAsFixed(1),
                        style: GoogleFonts.roboto(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'mmHg',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  Container(
                    width: 2,
                    height: 80,
                    color: primaryColor,
                  ),
                  
                  Column(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: primaryColor,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Diastólica',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _afinamiento!.presionDiastolicaPromedio!.toStringAsFixed(1),
                        style: GoogleFonts.roboto(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'mmHg',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Interpretación de los valores
            _buildInterpretacionPresion(),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretacionPresion() {
    final sistolica = _afinamiento!.presionSistolicaPromedio!;
    final diastolica = _afinamiento!.presionDiastolicaPromedio!;
    
    String categoria;
    Color color;
    IconData icono;
    
    if (sistolica < 120 && diastolica < 80) {
      categoria = 'Normal';
      color = Colors.green;
      icono = Icons.check_circle;
    } else if (sistolica < 130 && diastolica < 80) {
      categoria = 'Elevada';
      color = Colors.yellow[700]!;
      icono = Icons.warning;
    } else if ((sistolica >= 130 && sistolica < 140) || (diastolica >= 80 && diastolica < 90)) {
      categoria = 'Hipertensión Estadio 1';
      color = Colors.orange;
      icono = Icons.error_outline;
    } else if (sistolica >= 140 || diastolica >= 90) {
      categoria = 'Hipertensión Estadio 2';
      color = Colors.red;
      icono = Icons.error;
    } else {
      categoria = 'Crisis Hipertensiva';
      color = Colors.red[900]!;
      icono = Icons.emergency;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            'Clasificación: $categoria',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConducta() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conducta',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services, color: Colors.green[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _afinamiento!.conducta!,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        height: 1.5,
                      ),
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

  Widget _buildInformacionAdicional() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildInfoRow(
              Icons.fingerprint,
              'ID del Afinamiento',
              _afinamiento!.id,
            ),
            
            SizedBox(height: 12),
            
            if (_afinamiento!.createdAt != null)
              _buildInfoRow(
                Icons.access_time,
                'Fecha de Creación',
                DateFormat('dd/MM/yyyy HH:mm').format(_afinamiento!.createdAt!),
              ),
            
            if (_afinamiento!.updatedAt != null && _afinamiento!.createdAt != _afinamiento!.updatedAt) ...[
              SizedBox(height: 12),
              _buildInfoRow(
                Icons.update,
                'Última Actualización',
                DateFormat('dd/MM/yyyy HH:mm').format(_afinamiento!.updatedAt!),
              ),
            ],
            
            SizedBox(height: 12),
            
            _buildInfoRow(
              Icons.summarize,
              'Resumen de Presiones',
              _afinamiento!.resumenPresiones.isNotEmpty 
                  ? _afinamiento!.resumenPresiones 
                  : 'Sin mediciones registradas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

