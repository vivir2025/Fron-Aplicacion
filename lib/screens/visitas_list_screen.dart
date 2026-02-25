import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Bornive/models/medicamento_con_indicaciones.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/visita_model.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import 'visitas_form_screen.dart';

class VisitasListScreen extends StatefulWidget {
  final ThemeData theme;
  
  const VisitasListScreen({
    Key? key,
    required this.theme,
  }) : super(key: key);

  @override
  State<VisitasListScreen> createState() => _VisitasListScreenState();
}

class _VisitasListScreenState extends State<VisitasListScreen> {
  List<Visita> _visitas = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVisitas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVisitas() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = await authProvider.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('Usuario no autenticado. ID de usuario nulo');
      }

      final dbHelper = DatabaseHelper.instance;
      _visitas = await dbHelper.getVisitasByUsuario(userId);
      
      if (_visitas.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay visitas registradas')),
        );
      }
    } catch (e) {
      debugPrint('Error cargando visitas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        
        if (e.toString().contains('no autenticado')) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Visita> get _filteredVisitas {
    if (_searchQuery.isEmpty) return _visitas;
    
    return _visitas.where((visita) {
      return visita.nombreApellido.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             visita.identificacion.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (visita.motivo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
             (visita.factores?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
             (visita.conductas?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Future<void> _deleteVisita(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar esta visita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.deleteVisita(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visita eliminada correctamente')),
          );
        }
        _loadVisitas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar visita: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _editVisita(Visita visita) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitasFormScreen(
          theme: widget.theme,
          visitaToEdit: visita,
          onVisitaSaved: () {
            _loadVisitas();
          },
        ),
      ),
    );
  }

 void _showVisitaDetails(Visita visita) async {
  // Cargar medicamentos de la visita
  List<MedicamentoConIndicaciones> medicamentosVisita = [];
  try {
    final dbHelper = DatabaseHelper.instance;
    medicamentosVisita = await dbHelper.getMedicamentosDeVisita(visita.id);
  } catch (e) {
    debugPrint('❌ Error cargando medicamentos de visita: $e');
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Visita del ${DateFormat('dd/MM/yyyy').format(visita.fecha)}',
        style: GoogleFonts.roboto(color: const Color(0xFF1B5E20), fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información del paciente
            _buildSectionHeader('Información del Paciente'),
            _buildDetailRow('Paciente', visita.nombreApellido, bold: true),
            _buildDetailRow('Identificación', visita.identificacion),
            if (visita.telefono != null && visita.telefono!.isNotEmpty)
              _buildDetailRow('Teléfono', visita.telefono!),
            
            const SizedBox(height: 16),
            
            // Datos médicos básicos
            _buildSectionHeader('Datos Médicos'),
            if (visita.hta != null && visita.hta!.isNotEmpty)
              _buildDetailRow('HTA', visita.hta!),
            if (visita.dm != null && visita.dm!.isNotEmpty)
              _buildDetailRow('DM', visita.dm!),
            if (visita.zona != null && visita.zona!.isNotEmpty)
              _buildDetailRow('Zona', visita.zona!),
            
            const SizedBox(height: 16),
            
            // Signos vitales
            if (_hasSignosVitales(visita)) ...[
              _buildSectionHeader('Signos Vitales'),
              if (visita.peso != null)
                _buildDetailRow('Peso', '${visita.peso} kg'),
              if (visita.talla != null)
                _buildDetailRow('Talla', '${visita.talla} cm'),
              if (visita.imc != null)
                _buildDetailRow('IMC', visita.imc!.toStringAsFixed(2)),
              if (visita.perimetroAbdominal != null)
                _buildDetailRow('Perímetro Abdominal', '${visita.perimetroAbdominal} cm'),
              if (visita.frecuenciaCardiaca != null)
                _buildDetailRow('Frec. Cardiaca', '${visita.frecuenciaCardiaca} lpm'),
              if (visita.frecuenciaRespiratoria != null)
                _buildDetailRow('Frec. Respiratoria', '${visita.frecuenciaRespiratoria} rpm'),
              if (visita.tensionArterial != null && visita.tensionArterial!.isNotEmpty)
                _buildDetailRow('Tensión Arterial', visita.tensionArterial!),
              if (visita.glucometria != null)
                _buildDetailRow('Glucometría', '${visita.glucometria} mg/dL'),
              if (visita.temperatura != null)
                _buildDetailRow('Temperatura', '${visita.temperatura} °C'),
              const SizedBox(height: 16),
            ],
            
            
            
            // Evaluación
            _buildSectionHeader('Evaluación'),
            if (visita.familiar != null)
              _buildDetailRow('Familiar', visita.familiar!),
            if (visita.abandonoSocial != null)
              _buildDetailRow('Abandono Social', visita.abandonoSocial!),
            
            const SizedBox(height: 12),
            // Sección de Medicamentos (nueva)
            if (medicamentosVisita.isNotEmpty) ...[
              _buildSectionHeader('Medicamentos Prescritos'),
              _buildMedicamentosSection(medicamentosVisita),
              const SizedBox(height: 16),
            ],
            
            // Motivo de No Asistencia
            if (visita.motivo != null && visita.motivo!.isNotEmpty)
              _buildChipSection('Motivo de No Asistencia', visita.motivo!),
            
            // Factores de Riesgo
            if (visita.factores != null && visita.factores!.isNotEmpty)
              _buildChipSection('Factores de Riesgo', visita.factores!),
            
            // Conductas
            if (visita.conductas != null && visita.conductas!.isNotEmpty)
              _buildChipSection('Conductas', visita.conductas!),
            
            const SizedBox(height: 16),
            
            // Riesgo Fotográfico
            if (visita.riesgoFotografico != null && visita.riesgoFotografico!.isNotEmpty)
              _buildPhotoSection('Riesgo Fotográfico', visita.riesgoFotografico!),
            
            // Firma
            if (visita.firma != null && visita.firma!.isNotEmpty)
              _buildPhotoSection('Firma', visita.firma!),
            
            // Novedades y próximo control
            if (visita.novedades != null && visita.novedades!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('Novedades'),
              _buildDetailRow('', visita.novedades!),
            ],
            
            if (visita.proximoControl != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Próximo Control', DateFormat('dd/MM/yyyy').format(visita.proximoControl!)),
            ],
            
            // Geolocalización
            if (visita.latitud != null && visita.longitud != null) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('Geolocalización'),
              _buildDetailRow('Coordenadas', '${visita.latitud!.toStringAsFixed(6)}, ${visita.longitud!.toStringAsFixed(6)}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _editVisita(visita);
          },
          child: Text('Editar', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

  // Método para verificar si hay signos vitales
  bool _hasSignosVitales(Visita visita) {
    return visita.peso != null ||
           visita.talla != null ||
           visita.imc != null ||
           visita.perimetroAbdominal != null ||
           visita.frecuenciaCardiaca != null ||
           visita.frecuenciaRespiratoria != null ||
           (visita.tensionArterial != null && visita.tensionArterial!.isNotEmpty) ||
           visita.glucometria != null ||
           visita.temperatura != null;
  }

  // Widget para encabezados de sección
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: const Color(0xFF1B5E20),
        ),
      ),
    );
  }
  Widget _buildMedicamentosSection(List<MedicamentoConIndicaciones> medicamentos) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  Icon(Icons.medication, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${medicamentos.length} medicamentos prescritos:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...medicamentos.map((medicamentoConIndicaciones) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamentoConIndicaciones.medicamento.nombmedicamento,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (medicamentoConIndicaciones.indicaciones != null &&
                          medicamentoConIndicaciones.indicaciones!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Indicaciones: ${medicamentoConIndicaciones.indicaciones}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    ),
  );
}

  // Widget para mostrar chips de selección múltiple
  Widget _buildChipSection(String title, String values) {
    final items = values.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items.map((item) {
              return Chip(
                label: Text(
                  item,
                  style: GoogleFonts.roboto(fontSize: 12),
                ),
                backgroundColor: widget.theme.primaryColor.withOpacity(0.1),
                side: BorderSide(color: widget.theme.primaryColor.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar fotos/firmas
  Widget _buildPhotoSection(String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: File(imagePath).existsSync()
                  ? Image.file(
                      File(imagePath),
                      height: title == 'Firma' ? 100 : 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      height: title == 'Firma' ? 100 : 200,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Imagen no disponible',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.roboto(color: Colors.black87, fontSize: 14),
          children: [
            if (label.isNotEmpty) ...[
              TextSpan(
                text: '$label: ',
                style: GoogleFonts.roboto(fontWeight: bold ? FontWeight.w600 : FontWeight.w500),
              ),
            ],
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.roboto(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, ID, motivo, factores...',
                hintStyle: GoogleFonts.roboto(color: Colors.grey.shade500, fontSize: 15),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
        
        // Lista de visitas
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredVisitas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No hay visitas registradas'
                                : 'No se encontraron visitas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Text('Limpiar búsqueda'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVisitas,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _filteredVisitas.length,
                        itemBuilder: (context, index) {
                          final visita = _filteredVisitas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: widget.theme.primaryColorLight,
                                child: Icon(
                                  Icons.person,
                                  color: widget.theme.primaryColorDark,
                                ),
                              ),
                              title: Text(
                                visita.nombreApellido,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${visita.identificacion}',
                                    style: GoogleFonts.roboto(
                                      color: const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Fecha: ${DateFormat('dd/MM/yyyy').format(visita.fecha)}',
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // Mostrar resumen de evaluación
                                  if (visita.familiar != null || visita.abandonoSocial != null)
                                    Text(
                                      '${visita.familiar != null ? 'Familiar: ${visita.familiar}' : ''}'
                                      '${visita.familiar != null && visita.abandonoSocial != null ? ' | ' : ''}'
                                      '${visita.abandonoSocial != null ? 'Abandono: ${visita.abandonoSocial}' : ''}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  // Mostrar motivos si existen
                                  if (visita.motivo != null && visita.motivo!.isNotEmpty)
                                    Text(
                                      'Motivos: ${visita.motivo}',
                                      style: GoogleFonts.roboto(
                                        color: Colors.black87,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  // Indicadores visuales para foto y firma
                                  Row(
                                    children: [
                                      if (visita.riesgoFotografico != null && visita.riesgoFotografico!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 4, top: 2),
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 14,
                                            color: Colors.green[600],
                                          ),
                                        ),
                                      if (visita.firma != null && visita.firma!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 4, top: 2),
                                          child: Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.indigo[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showVisitaDetails(visita);
                                      break;
                                    case 'edit':
                                      _editVisita(visita);
                                      break;
                                    case 'delete':
                                      _deleteVisita(visita.id);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Ver detalles'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
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
                              onTap: () => _showVisitaDetails(visita),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}