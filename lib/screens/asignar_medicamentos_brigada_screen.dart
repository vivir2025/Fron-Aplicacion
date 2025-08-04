import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/paciente_model.dart';
import '../models/medicamento.dart';
import '../services/brigada_service.dart';
import '../services/medicamento_service.dart';
import '../providers/auth_provider.dart';

class AsignarMedicamentosBrigadaScreen extends StatefulWidget {
  final String brigadaId;
  final Paciente paciente;

  const AsignarMedicamentosBrigadaScreen({
    Key? key,
    required this.brigadaId,
    required this.paciente,
  }) : super(key: key);

  @override
  State<AsignarMedicamentosBrigadaScreen> createState() => _AsignarMedicamentosBrigadaScreenState();
}

class _AsignarMedicamentosBrigadaScreenState extends State<AsignarMedicamentosBrigadaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // ✅ CONTROLADOR PARA BÚSQUEDA DE MEDICAMENTOS
  final _searchController = TextEditingController();
  
  List<Medicamento> _allMedicamentos = [];
  List<MedicamentoAsignado> _allMedicamentosAsignados = [];
  List<MedicamentoAsignado> _filteredMedicamentosAsignados = []; // ✅ LISTA FILTRADA
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // ✅ LISTENER PARA BÚSQUEDA EN TIEMPO REAL
    _searchController.addListener(_filtrarMedicamentos);
  }

  @override
  void dispose() {
    _searchController.dispose(); // ✅ DISPOSE DEL CONTROLADOR DE BÚSQUEDA
    super.dispose();
  }

  // ✅ MÉTODO PARA FILTRAR MEDICAMENTOS POR NOMBRE
  void _filtrarMedicamentos() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredMedicamentosAsignados = _allMedicamentosAsignados;
      } else {
        _filteredMedicamentosAsignados = _allMedicamentosAsignados.where((medicamento) {
          final nombreMedicamento = medicamento.medicamento.nombmedicamento.toLowerCase();
          return nombreMedicamento.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await _cargarMedicamentos();
      await _cargarMedicamentosAsignados();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar datos: $e';
      });
      debugPrint('❌ Error cargando datos: $e');
    }
  }

  Future<void> _cargarMedicamentos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await MedicamentoService.ensureMedicamentosLoaded(authProvider.token);
    _allMedicamentos = await _dbHelper.getAllMedicamentos();
    debugPrint('✅ ${_allMedicamentos.length} medicamentos cargados');
  }

  Future<void> _cargarMedicamentosAsignados() async {
    final medicamentosData = await _dbHelper.getMedicamentosDePacienteEnBrigada(
      widget.brigadaId,
      widget.paciente.id,
    );

    _allMedicamentosAsignados = _allMedicamentos.map((medicamento) {
      final asignado = medicamentosData.firstWhere(
        (m) => m['medicamento_id'] == medicamento.id,
        orElse: () => <String, dynamic>{},
      );

      return MedicamentoAsignado(
        medicamento: medicamento,
        isSelected: asignado.isNotEmpty,
        dosis: asignado['dosis']?.toString() ?? '',
        cantidad: asignado['cantidad']?.toString() ?? '',
        indicaciones: asignado['indicaciones']?.toString() ?? '',
      );
    }).toList();

    // ✅ INICIALIZAR LISTA FILTRADA
    _filteredMedicamentosAsignados = _allMedicamentosAsignados;

    debugPrint('✅ Medicamentos asignados cargados: ${_allMedicamentosAsignados.where((m) => m.isSelected).length}');
  }

  // ✅ VALIDACIÓN MEJORADA - Verificar que medicamentos seleccionados tengan dosis y cantidad
  bool _validarMedicamentosSeleccionados() {
    final medicamentosSeleccionados = _allMedicamentosAsignados.where((m) => m.isSelected).toList();
    
    if (medicamentosSeleccionados.isEmpty) {
      _mostrarError('Debe seleccionar al menos un medicamento');
      return false;
    }

    for (final medicamento in medicamentosSeleccionados) {
      if (medicamento.dosis.trim().isEmpty) {
        _mostrarError('El medicamento "${medicamento.medicamento.nombmedicamento}" debe tener una dosis especificada');
        return false;
      }
      
      if (medicamento.cantidad.trim().isEmpty) {
        _mostrarError('El medicamento "${medicamento.medicamento.nombmedicamento}" debe tener una cantidad especificada');
        return false;
      }

      // Validar que la cantidad sea un número válido
      if (int.tryParse(medicamento.cantidad.trim()) == null || int.parse(medicamento.cantidad.trim()) <= 0) {
        _mostrarError('La cantidad del medicamento "${medicamento.medicamento.nombmedicamento}" debe ser un número válido mayor a 0');
        return false;
      }
    }

    return true;
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _guardarMedicamentos() async {
    // ✅ VALIDAR ANTES DE GUARDAR
    if (!_validarMedicamentosSeleccionados()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final medicamentosSeleccionados = _allMedicamentosAsignados
          .where((m) => m.isSelected)
          .map((m) => {
                'medicamento_id': m.medicamento.id,
                'dosis': m.dosis.trim(),
                'cantidad': int.parse(m.cantidad.trim()),
                'indicaciones': m.indicaciones.trim().isNotEmpty ? m.indicaciones.trim() : null,
              })
          .toList();

      final success = await BrigadaService.asignarMedicamentosAPaciente(
        brigadaId: widget.brigadaId,
        pacienteId: widget.paciente.id,
        medicamentos: medicamentosSeleccionados,
        token: authProvider.token,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${medicamentosSeleccionados.length} medicamentos asignados exitosamente',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          _mostrarError('Error al asignar medicamentos');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al guardar medicamentos: $e');
      if (mounted) {
        _mostrarError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ✅ DIÁLOGO MEJORADO CON VALIDACIÓN
  void _mostrarDialogoDetalles(MedicamentoAsignado medicamento) {
    final dosisController = TextEditingController(text: medicamento.dosis);
    final cantidadController = TextEditingController(text: medicamento.cantidad);
    final indicacionesController = TextEditingController(text: medicamento.indicaciones);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medication_liquid_rounded,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                medicamento.medicamento.nombmedicamento,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ CAMPO DOSIS OBLIGATORIO
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: dosisController,
                    decoration: InputDecoration(
                      labelText: 'Dosis *',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Ej: 500mg, 1 tableta, 5ml',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication_liquid,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La dosis es obligatoria';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // ✅ CAMPO CANTIDAD OBLIGATORIO
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: cantidadController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad *',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Ej: 30, 60, 100',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.numbers,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La cantidad es obligatoria';
                      }
                      final cantidad = int.tryParse(value.trim());
                      if (cantidad == null || cantidad <= 0) {
                        return 'Ingrese un número válido mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
               
                
             
                
                // ✅ MENSAJE DE CAMPOS OBLIGATORIOS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los campos marcados con * son obligatorios',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    final index = _allMedicamentosAsignados.indexWhere(
                      (m) => m.medicamento.id == medicamento.medicamento.id,
                    );
                    if (index != -1) {
                      _allMedicamentosAsignados[index] = medicamento.copyWith(
                        dosis: dosisController.text.trim(),
                        cantidad: cantidadController.text.trim(),
                        indicaciones: indicacionesController.text.trim(),
                      );
                      // ✅ ACTUALIZAR TAMBIÉN LA LISTA FILTRADA
                      _filtrarMedicamentos();
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Medicamentos - ${widget.paciente.nombre}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _cargarDatos,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Cargando medicamentos...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_allMedicamentosAsignados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay medicamentos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ✅ INFORMACIÓN DEL PACIENTE MEJORADA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade50,
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade100),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.paciente.nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.paciente.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ID: ${widget.paciente.identificacion}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_allMedicamentosAsignados.where((m) => m.isSelected).length} seleccionados',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // ✅ BARRA DE BÚSQUEDA PROFESIONAL
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar medicamentos',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'Ingrese el nombre del medicamento...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
  borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarMedicamentos();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // ✅ CONTADOR DE RESULTADOS Y SELECCIONADOS
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade50,
                Colors.green.shade50,
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.green.shade100),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mostrando ${_filteredMedicamentosAsignados.length} de ${_allMedicamentosAsignados.length} medicamentos',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Text(
                        'Búsqueda: "${_searchController.text}"',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_allMedicamentosAsignados.where((m) => m.isSelected).length} seleccionados',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // ✅ MENSAJE DE INFORMACIÓN SOBRE CAMPOS OBLIGATORIOS
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade50,
                Colors.orange.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Importante: Todos los medicamentos seleccionados deben tener dosis y cantidad especificadas',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // ✅ LISTA DE MEDICAMENTOS FILTRADOS
        Expanded(
          child: _filteredMedicamentosAsignados.isEmpty && _searchController.text.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron medicamentos',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Intenta con otro término de búsqueda',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blue.shade600],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            _filtrarMedicamentos();
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: const Text('Limpiar búsqueda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredMedicamentosAsignados.length,
                  itemBuilder: (context, index) {
                    final medicamento = _filteredMedicamentosAsignados[index];
                    final originalIndex = _allMedicamentosAsignados.indexWhere(
                      (m) => m.medicamento.id == medicamento.medicamento.id,
                    );
                    return _buildMedicamentoCard(medicamento, originalIndex);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicamentoCard(MedicamentoAsignado medicamento, int originalIndex) {
    // ✅ VALIDAR SI EL MEDICAMENTO TIENE DATOS COMPLETOS
    final bool tieneDetallesCompletos = medicamento.isSelected && 
        medicamento.dosis.trim().isNotEmpty && 
        medicamento.cantidad.trim().isNotEmpty;
    
    final bool necesitaDetalles = medicamento.isSelected && !tieneDetallesCompletos;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // ✅ CAMBIAR COLOR SI FALTAN DETALLES
        color: necesitaDetalles 
            ? Colors.red.shade50 
            : medicamento.isSelected 
                ? Colors.green.shade50 
                : Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: necesitaDetalles 
                  ? Colors.red.withOpacity(0.3)
                  : medicamento.isSelected 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
              width: medicamento.isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              decoration: BoxDecoration(
                color: medicamento.isSelected 
                    ? (necesitaDetalles ? Colors.red : Colors.green)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Checkbox(
                value: medicamento.isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    _allMedicamentosAsignados[originalIndex] = medicamento.copyWith(
                      isSelected: value ?? false,
                    );
                    _filtrarMedicamentos(); // ✅ ACTUALIZAR LISTA FILTRADA
                  });
                  
                  // ✅ ABRIR AUTOMÁTICAMENTE EL DIÁLOGO SI SE SELECCIONA
                  if (value == true) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _mostrarDialogoDetalles(_allMedicamentosAsignados[originalIndex]);
                    });
                  }
                },
                activeColor: Colors.transparent,
                checkColor: Colors.white,
                side: BorderSide.none,
              ),
            ),
            title: Text(
              medicamento.medicamento.nombmedicamento,
              style: TextStyle(
                fontWeight: medicamento.isSelected ? FontWeight.bold : FontWeight.w500,
                color: necesitaDetalles 
                    ? Colors.red.shade700 
                    : medicamento.isSelected 
                        ? Colors.green.shade700 
                        : Colors.black87,
                fontSize: 15,
              ),
            ),
            subtitle: medicamento.isSelected ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (medicamento.dosis.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dosis: ${medicamento.dosis}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                if (medicamento.cantidad.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cantidad: ${medicamento.cantidad}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
               
                
                // ✅ MOSTRAR ADVERTENCIA SI FALTAN DATOS
                if (necesitaDetalles)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade100,
                          Colors.red.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Faltan dosis y/o cantidad - Toque el ícono para completar',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ) : null,
            trailing: medicamento.isSelected
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ INDICADOR VISUAL DE ESTADO
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: necesitaDetalles 
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Icon(
                            necesitaDetalles ? Icons.warning_rounded : Icons.check_circle_rounded,
                            color: necesitaDetalles ? Colors.red.shade600 : Colors.green.shade600,
                            size: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _mostrarDialogoDetalles(medicamento),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.blue.shade600,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            onTap: () {
              setState(() {
                _allMedicamentosAsignados[originalIndex] = medicamento.copyWith(
                  isSelected: !medicamento.isSelected,
                );
                _filtrarMedicamentos(); // ✅ ACTUALIZAR LISTA FILTRADA
              });
              
              // ✅ ABRIR AUTOMÁTICAMENTE EL DIÁLOGO SI SE SELECCIONA
              if (!medicamento.isSelected) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mostrarDialogoDetalles(_allMedicamentosAsignados[originalIndex]);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = _allMedicamentosAsignados.where((m) => m.isSelected).length;
    final incompleteCount = _allMedicamentosAsignados.where((m) => 
        m.isSelected && (m.dosis.trim().isEmpty || m.cantidad.trim().isEmpty)).length;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ MOSTRAR ADVERTENCIA SI HAY MEDICAMENTOS INCOMPLETOS
              if (incompleteCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade50,
                        Colors.red.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$incompleteCount medicamentos necesitan dosis y cantidad',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount medicamentos seleccionados',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          Text(
                            'Mostrando ${_filteredMedicamentosAsignados.length} resultados',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _guardarMedicamentos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Guardando...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.save_rounded,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase auxiliar para manejar medicamentos asignados
class MedicamentoAsignado {
  final Medicamento medicamento;
  final bool isSelected;
  final String dosis;
  final String cantidad;
  final String indicaciones;

  MedicamentoAsignado({
    required this.medicamento,
    required this.isSelected,
    required this.dosis,
    required this.cantidad,
    required this.indicaciones,
  });

  bool get tieneDetalles => dosis.isNotEmpty || cantidad.isNotEmpty || indicaciones.isNotEmpty;

  MedicamentoAsignado copyWith({
    Medicamento? medicamento,
    bool? isSelected,
    String? dosis,
    String? cantidad,
    String? indicaciones,
  }) {
    return MedicamentoAsignado(
      medicamento: medicamento ?? this.medicamento,
      isSelected: isSelected ?? this.isSelected,
      dosis: dosis ?? this.dosis,
      cantidad: cantidad ?? this.cantidad,
      indicaciones: indicaciones ?? this.indicaciones,
    );
  }
}
