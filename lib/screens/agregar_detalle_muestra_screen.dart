// screens/agregar_detalle_muestra_screen.dart - VERSIÓN CON ESTILO PREMIUM
import 'package:flutter/material.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/models/envio_muestra_model.dart';
import 'package:fnpv_app/models/paciente_model.dart';
import 'package:uuid/uuid.dart';

class AgregarDetalleMuestraScreen extends StatefulWidget {
  final List<Paciente> pacientes;
  final int numeroOrden;
  final Function(DetalleEnvioMuestra) onAgregar;

  const AgregarDetalleMuestraScreen({
    Key? key,
    required this.pacientes,
    required this.numeroOrden,
    required this.onAgregar,
  }) : super(key: key);

  @override
  _AgregarDetalleMuestraScreenState createState() => _AgregarDetalleMuestraScreenState();
}

class _AgregarDetalleMuestraScreenState extends State<AgregarDetalleMuestraScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // ✅ BÚSQUEDA POR IDENTIFICACIÓN
  final _identificacionController = TextEditingController();
  Paciente? _pacienteSeleccionado;
  bool _buscandoPaciente = false;
  
  // ✅ CONTROLADORES SEGÚN LA ESTRUCTURA EXACTA
  // DIAGNÓSTICO
  final _dmController = TextEditingController();
  final _htaController = TextEditingController();
  
  // # MUESTRAS ENVIADAS
  final _aController = TextEditingController();
  final _mController = TextEditingController();
  final _oeController = TextEditingController();
  final _o24hController = TextEditingController();
  final _poController = TextEditingController();
  
  // TUBO LILA
  final _h3Controller = TextEditingController();
  final _hba1cController = TextEditingController();
  final _pthController = TextEditingController();
  
  // TUBO AMARILLO
  final _gluController = TextEditingController();
  final _creaController = TextEditingController();
  final _plController = TextEditingController();
  final _auController = TextEditingController();
  final _bunController = TextEditingController();
  final _po2Controller = TextEditingController();
  
  // MUESTRA DE ORINA - ORINA ESP
  final _relacionCreaAlbController = TextEditingController();
  
  // MUESTRA DE ORINA - ORINA24H
  final _dcre24hController = TextEditingController();
  final _alb24hController = TextEditingController();
  final _buno24hController = TextEditingController();
  
  // PACIENTES NEFRO - TUBO AMARILLO
  final _pesoController = TextEditingController();
  final _tallaController = TextEditingController();
  final _volmController = TextEditingController();
  final _ferController = TextEditingController();
  final _traController = TextEditingController();
  final _fosfatController = TextEditingController();
  final _albController = TextEditingController();
  final _feController = TextEditingController();
  final _tshController = TextEditingController();
  final _pController = TextEditingController();
  final _ionogramaController = TextEditingController();
  
  // PACIENTES NEFRO - FORRADOS
  final _b12Controller = TextEditingController();
  final _acidoFolicoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
    _slideController.forward();
    _identificacionController.addListener(_buscarPacientePorIdentificacion);
  }

  @override
  void dispose() {
    try {
      _animationController.dispose();
      _slideController.dispose();
      _identificacionController.removeListener(_buscarPacientePorIdentificacion);
      _identificacionController.dispose();
      _dmController.dispose();
      _htaController.dispose();
      _aController.dispose();
      _mController.dispose();
      _oeController.dispose();
      _o24hController.dispose();
      _poController.dispose();
      _h3Controller.dispose();
      _hba1cController.dispose();
      _pthController.dispose();
      _gluController.dispose();
      _creaController.dispose();
      _plController.dispose();
      _auController.dispose();
      _bunController.dispose();
      _po2Controller.dispose();
      _relacionCreaAlbController.dispose();
      _dcre24hController.dispose();
      _alb24hController.dispose();
      _buno24hController.dispose();
      _pesoController.dispose();
      _tallaController.dispose();
      _volmController.dispose();
      _ferController.dispose();
      _traController.dispose();
      _fosfatController.dispose();
      _albController.dispose();
      _feController.dispose();
      _tshController.dispose();
      _pController.dispose();
      _ionogramaController.dispose();
      _b12Controller.dispose();
      _acidoFolicoController.dispose();
    } catch (e) {
      debugPrint('❌ Error en dispose: $e');
    }
    super.dispose();
  }

  // ✅ BÚSQUEDA AUTOMÁTICA POR IDENTIFICACIÓN - MEJORADA
  void _buscarPacientePorIdentificacion() async {
    final identificacion = _identificacionController.text.trim();
    
    if (identificacion.isEmpty) {
      if (mounted) {
        setState(() {
          _pacienteSeleccionado = null;
          _buscandoPaciente = false;
        });
      }
      return;
    }

    if (identificacion.length >= 3) {
      if (mounted) {
        setState(() => _buscandoPaciente = true);
      }
      
      try {
        final dbHelper = DatabaseHelper.instance;
        final paciente = await dbHelper.getPacienteByIdentificacion(identificacion);
        
        if (mounted) {
          setState(() {
            _pacienteSeleccionado = paciente;
            _buscandoPaciente = false;
          });
        }
        
        if (paciente != null) {
          debugPrint('✅ Paciente encontrado: ${paciente.nombre} ${paciente.apellido}');
        }
      } catch (e) {
        debugPrint('❌ Error buscando paciente: $e');
        if (mounted) {
          setState(() => _buscandoPaciente = false);
        }
      }
    }
  }

  // ✅ WIDGET PARA CAMPOS NUMÉRICOS ULTRA MODERNOS
  Widget _buildModernNumericField(String label, TextEditingController controller, {String? hint, Color? accentColor}) {
    final color = accentColor ?? Color(0xFF6366F1);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFFAFBFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint ?? '0',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: color, width: 2.5),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                filled: true,
                fillColor: Colors.transparent,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ TÍTULO PRINCIPAL ULTRA MODERNO CON GRADIENTES
  Widget _buildUltraModernTitle(String title, IconData icon, {required Color primaryColor, required Color secondaryColor}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SUBTÍTULO MODERNO CON EFECTOS
  Widget _buildModernSubTitle(String title, {required Color color}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FILA DE CAMPOS CON ESPACIADO PERFECTO
  Widget _buildFieldRow(List<Widget> fields) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: fields.map((field) => Expanded(child: field)).toList(),
      ),
    );
  }

  // ✅ CARD ULTRA PREMIUM
  Widget _buildPremiumCard({required Widget child, required Color primaryColor, required Color secondaryColor}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFFDFDFD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.02),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Nueva Muestra #${widget.numeroOrden}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 120, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ BÚSQUEDA DE PACIENTE ULTRA MODERNA
                  _buildPremiumCard(
                    primaryColor: Color(0xFF10B981),
                    secondaryColor: Color(0xFF059669),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BUSCAR PACIENTE',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Ingrese la identificación',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [Colors.white, Color(0xFFFAFBFC)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF10B981).withOpacity(0.1),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _identificacionController,
                            decoration: InputDecoration(
                              labelText: 'Número de Identificación',
                              labelStyle: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              hintText: 'Ej: 1234567890',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Container(
                                margin: EdgeInsets.all(12),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.badge_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              suffixIcon: Container(
                                margin: EdgeInsets.all(12),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _buscandoPaciente 
                                      ? Colors.grey[100] 
                                      : Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _buscandoPaciente 
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                        ),
                                      )
                                    : Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF10B981),
                                        size: 20,
                                      ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Color(0xFF10B981), width: 2.5),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese la identificación del paciente';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        if (_pacienteSeleccionado != null) ...[
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF10B981).withOpacity(0.1),
                                  Color(0xFF059669).withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(color: Color(0xFF10B981).withOpacity(0.3), width: 2),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981).withOpacity(0.15),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_pacienteSeleccionado?.nombre ?? ''} ${_pacienteSeleccionado?.apellido ?? ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'ID: ${_pacienteSeleccionado?.identificacion ?? ''}',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
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
                        ] else if (_identificacionController.text.isNotEmpty && !_buscandoPaciente) ...[
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B).withOpacity(0.1),
                                  Color(0xFFD97706).withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3), width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    'Paciente no encontrado con esta identificación',
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // ✅ FORMULARIO PRINCIPAL ULTRA MODERNO
                  _buildPremiumCard(
                    primaryColor: Color(0xFF6366F1),
                    secondaryColor: Color(0xFF4F46E5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ DIAGNÓSTICO
                        _buildUltraModernTitle(
                          'DIAGNÓSTICO', 
                          Icons.medical_services_rounded, 
                          primaryColor: Color(0xFFEF4444), 
                          secondaryColor: Color(0xFFDC2626)
                        ),
                        _buildFieldRow([
                          _buildModernNumericField('DM', _dmController, accentColor: Color(0xFFEF4444)),
                          _buildModernNumericField('HTA', _htaController, accentColor: Color(0xFFEF4444)),
                        ]),
                        
                        SizedBox(height: 32),
                        
                        // ✅ # MUESTRAS ENVIADAS
                                                _buildUltraModernTitle(
                          'MUESTRAS ENVIADAS', 
                          Icons.inventory_2_rounded, 
                          primaryColor: Color(0xFF8B5CF6), 
                          secondaryColor: Color(0xFF7C3AED)
                        ),
                        _buildFieldRow([
                          _buildModernNumericField('A', _aController, accentColor: Color(0xFF8B5CF6)),
                          _buildModernNumericField('M', _mController, accentColor: Color(0xFF8B5CF6)),
                          _buildModernNumericField('OE', _oeController, accentColor: Color(0xFF8B5CF6)),
                        ]),
                        _buildFieldRow([
                          _buildModernNumericField('O24H', _o24hController, accentColor: Color(0xFF8B5CF6)),
                          _buildModernNumericField('PO', _poController, accentColor: Color(0xFF8B5CF6)),
                          Container(), // Espacio vacío
                        ]),
                        
                        SizedBox(height: 32),
                        
                        // ✅ TUBO LILA
                        _buildUltraModernTitle(
                          'TUBO LILA', 
                          Icons.science_rounded, 
                          primaryColor: Color(0xFFA855F7), 
                          secondaryColor: Color(0xFF9333EA)
                        ),
                        _buildFieldRow([
                          _buildModernNumericField('H3', _h3Controller, accentColor: Color(0xFFA855F7)),
                          _buildModernNumericField('HBA1C', _hba1cController, accentColor: Color(0xFFA855F7)),
                          _buildModernNumericField('PTH', _pthController, accentColor: Color(0xFFA855F7)),
                        ]),
                        
                        SizedBox(height: 32),
                        
                        // ✅ TUBO AMARILLO
                        _buildUltraModernTitle(
                          'TUBO AMARILLO', 
                          Icons.biotech_rounded, 
                          primaryColor: Color(0xFFF59E0B), 
                          secondaryColor: Color(0xFFD97706)
                        ),
                        _buildFieldRow([
                          _buildModernNumericField('GLU', _gluController, accentColor: Color(0xFFF59E0B)),
                          _buildModernNumericField('CREA', _creaController, accentColor: Color(0xFFF59E0B)),
                          _buildModernNumericField('PL', _plController, accentColor: Color(0xFFF59E0B)),
                        ]),
                        _buildFieldRow([
                          _buildModernNumericField('AU', _auController, accentColor: Color(0xFFF59E0B)),
                          _buildModernNumericField('BUN', _bunController, accentColor: Color(0xFFF59E0B)),
                          Container(),
                        ]),
                        
                        SizedBox(height: 32),
                        
                        // ✅ MUESTRA DE ORINA
                        _buildUltraModernTitle(
                          'MUESTRA DE ORINA', 
                          Icons.water_drop_rounded, 
                          primaryColor: Color(0xFF06B6D4), 
                          secondaryColor: Color(0xFF0891B2)
                        ),
                        
                        _buildModernSubTitle('ORINA ESP', color: Color(0xFF06B6D4)),
                        _buildFieldRow([
                          _buildModernNumericField('RELACIÓN CREA/ALB', _relacionCreaAlbController, accentColor: Color(0xFF06B6D4)),
                          _buildModernNumericField('PO', _po2Controller, accentColor: Color(0xFF06B6D4)),
                          Container(),
                        ]),
                        
                        _buildModernSubTitle('ORINA 24H', color: Color(0xFF059669)),
                        _buildFieldRow([
                          _buildModernNumericField('DCRE24H', _dcre24hController, accentColor: Color(0xFF059669)),
                          _buildModernNumericField('ALB24H', _alb24hController, accentColor: Color(0xFF059669)),
                          _buildModernNumericField('BUNO24H', _buno24hController, accentColor: Color(0xFF059669)),
                        ]),
                        _buildFieldRow([
                          _buildModernNumericField('PESO', _pesoController, hint: 'kg', accentColor: Color(0xFF059669)),
                          _buildModernNumericField('TALLA', _tallaController, hint: 'm', accentColor: Color(0xFF059669)),
                          _buildModernNumericField('VOLM', _volmController, hint: 'ml', accentColor: Color(0xFF059669)),
                        ]),
                        
                        SizedBox(height: 32),
                        
                        // ✅ PACIENTES NEFRO
                        _buildUltraModernTitle(
                          'PACIENTES NEFRO', 
                          Icons.local_hospital_rounded, 
                          primaryColor: Color(0xFF10B981), 
                          secondaryColor: Color(0xFF059669)
                        ),
                        
                        _buildModernSubTitle('TUBO AMARILLO', color: Color(0xFF10B981)),
                        _buildFieldRow([
                          _buildModernNumericField('FER', _ferController, accentColor: Color(0xFF10B981)),
                          _buildModernNumericField('TRA', _traController, accentColor: Color(0xFF10B981)),
                          _buildModernNumericField('FOSFAT', _fosfatController, accentColor: Color(0xFF10B981)),
                        ]),
                        _buildFieldRow([
                          _buildModernNumericField('ALB', _albController, accentColor: Color(0xFF10B981)),
                          _buildModernNumericField('FE', _feController, accentColor: Color(0xFF10B981)),
                          _buildModernNumericField('TSH', _tshController, accentColor: Color(0xFF10B981)),
                        ]),
                        _buildFieldRow([
                          _buildModernNumericField('P', _pController, accentColor: Color(0xFF10B981)),
                          _buildModernNumericField('IONOGRAMA', _ionogramaController, accentColor: Color(0xFF10B981)),
                          Container(),
                        ]),
                        
                        _buildModernSubTitle('FORRADOS', color: Color(0xFF6B7280)),
                        _buildFieldRow([
                          _buildModernNumericField('B12', _b12Controller, accentColor: Color(0xFF6B7280)),
                          _buildModernNumericField('Á. FÓLICO', _acidoFolicoController, accentColor: Color(0xFF6B7280)),
                          Container(),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF4F46E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.2),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (_pacienteSeleccionado == null) {
                _showModernSnackBar(
                  context,
                  'Debe seleccionar un paciente válido',
                  Color(0xFFEF4444),
                  Icons.error_rounded,
                  isError: true,
                );
                return;
              }

              try {
                final detalle = DetalleEnvioMuestra(
                  id: DetalleEnvioMuestra.generarIdCorto(),
                  envioMuestraId: '',
                  pacienteId: _pacienteSeleccionado?.id ?? '',
                  numeroOrden: widget.numeroOrden,
                  dm: _dmController.text.isEmpty ? null : _dmController.text,
                  hta: _htaController.text.isEmpty ? null : _htaController.text,
                  numMuestrasEnviadas: null,
                  tuboLila: null,
                  tuboAmarillo: null,
                  tuboAmarilloForrado: null,
                  orinaEsp: _relacionCreaAlbController.text.isEmpty ? null : _relacionCreaAlbController.text,
                  orina24h: null,
                  a: _aController.text.isEmpty ? null : _aController.text,
                  m: _mController.text.isEmpty ? null : _mController.text,
                  oe: _oeController.text.isEmpty ? null : _oeController.text,
                  o24h: _o24hController.text.isEmpty ? null : _o24hController.text,
                  po: _poController.text.isEmpty ? null : _poController.text,
                  h3: _h3Controller.text.isEmpty ? null : _h3Controller.text,
                  hba1c: _hba1cController.text.isEmpty ? null : _hba1cController.text,
                  pth: _pthController.text.isEmpty ? null : _pthController.text,
                  glu: _gluController.text.isEmpty ? null : _gluController.text,
                  crea: _creaController.text.isEmpty ? null : _creaController.text,
                  pl: _plController.text.isEmpty ? null : _plController.text,
                  au: _auController.text.isEmpty ? null : _auController.text,
                  bun: _bunController.text.isEmpty ? null : _bunController.text,
                  relacionCreaAlb: _relacionCreaAlbController.text.isEmpty ? null : _relacionCreaAlbController.text,
                  dcre24h: _dcre24hController.text.isEmpty ? null : _dcre24hController.text,
                  alb24h: _alb24hController.text.isEmpty ? null : _alb24hController.text,
                  buno24h: _buno24hController.text.isEmpty ? null : _buno24hController.text,
                  fer: _ferController.text.isEmpty ? null : _ferController.text,
                  tra: _traController.text.isEmpty ? null : _traController.text,
                  fosfat: _fosfatController.text.isEmpty ? null : _fosfatController.text,
                  alb: _albController.text.isEmpty ? null : _albController.text,
                  fe: _feController.text.isEmpty ? null : _feController.text,
                  tsh: _tshController.text.isEmpty ? null : _tshController.text,
                  p: _pController.text.isEmpty ? null : _pController.text,
                  ionograma: _ionogramaController.text.isEmpty ? null : _ionogramaController.text,
                  b12: _b12Controller.text.isEmpty ? null : _b12Controller.text,
                  acidoFolico: _acidoFolicoController.text.isEmpty ? null : _acidoFolicoController.text,
                  peso: _pesoController.text.isEmpty ? null : _pesoController.text,
                  talla: _tallaController.text.isEmpty ? null : _tallaController.text,
                  volumen: _volmController.text.isEmpty ? null : _volmController.text,
                );
                
                widget.onAgregar(detalle);
                
                _showModernSnackBar(
                  context,
                  'Muestra guardada exitosamente',
                  Color(0xFF10B981),
                  Icons.check_circle_rounded,
                );
                
                Navigator.of(context).pop();
              } catch (e) {
                debugPrint('❌ Error creando detalle: $e');
                _showModernSnackBar(
                  context,
                  'Error al guardar la muestra',
                  Color(0xFFEF4444),
                  Icons.error_rounded,
                  isError: true,
                );
              }
            }
          },
          icon: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.save_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          label: Text(
            'Guardar Muestra',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  // ✅ SNACKBAR ULTRA MODERNO
  void _showModernSnackBar(BuildContext context, String message, Color color, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (!isError && _pacienteSeleccionado != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Paciente: ${_pacienteSeleccionado?.nombre} ${_pacienteSeleccionado?.apellido}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: isError ? 4 : 3),
        elevation: 8,
      ),
    );
  }
}
