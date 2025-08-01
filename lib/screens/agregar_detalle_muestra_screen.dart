// screens/agregar_detalle_muestra_screen.dart - VERSIÓN CORREGIDA
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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
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
  final _o24hController = TextEditingController(); // ✅ CORRECTO: o24h internamente
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
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _identificacionController.addListener(_buscarPacientePorIdentificacion);
  }

  @override
  void dispose() {
    try {
      _animationController.dispose();
      _identificacionController.removeListener(_buscarPacientePorIdentificacion);
      _identificacionController.dispose();
      _dmController.dispose();
      _htaController.dispose();
      _aController.dispose();
      _mController.dispose();
      _oeController.dispose();
      _o24hController.dispose(); // ✅ CORRECTO
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

  // ✅ WIDGET PARA CAMPOS NUMÉRICOS PROFESIONALES
  Widget _buildNumericField(String label, TextEditingController controller, {String? hint}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE8EAF0), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ TÍTULO PRINCIPAL PROFESIONAL CON ICONOS
  Widget _buildMainTitle(String title, IconData icon, {Color? color}) {
    final primaryColor = color ?? Color(0xFF2C3E50);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SUBTÍTULO ELEGANTE PROFESIONAL
  Widget _buildSubTitle(String title, {Color? color}) {
    final titleColor = color ?? Color(0xFF7F8C8D);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            titleColor.withOpacity(0.1),
            titleColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: titleColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: titleColor,
          letterSpacing: 0.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ✅ FILA DE CAMPOS CON ESPACIADO PERFECTO
  Widget _buildFieldRow(List<Widget> fields) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: fields.map((field) => Expanded(child: field)).toList(),
      ),
    );
  }

  // ✅ CARD PROFESIONAL MEJORADA
  Widget _buildProfessionalCard({required Widget child, Color? borderColor}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor?.withOpacity(0.2) ?? Color(0xFFE8EAF0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Nueva Muestra #${widget.numeroOrden}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFE8EAF0),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ BÚSQUEDA DE PACIENTE PROFESIONAL
                _buildProfessionalCard(
                  borderColor: Color(0xFF16A085),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFF16A085).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_search_rounded,
                              color: Color(0xFF16A085),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'BUSCAR PACIENTE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A085),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _identificacionController,
                          decoration: InputDecoration(
                            labelText: 'Número de Identificación',
                            labelStyle: TextStyle(
                              color: Color(0xFF7F8C8D),
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: 'Ingrese la identificación del paciente',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Color(0xFFE8EAF0), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Color(0xFF16A085), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            suffixIcon: Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _buscandoPaciente 
                                    ? Colors.grey[100] 
                                    : Color(0xFF16A085).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _buscandoPaciente 
                                  ? Padding(
                                      padding: EdgeInsets.all(8),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF16A085),
                                      size: 24,
                                    ),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C3E50),
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
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF27AE60).withOpacity(0.1),
                                Color(0xFF2ECC71).withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(color: Color(0xFF27AE60).withOpacity(0.3), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF27AE60),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_pacienteSeleccionado?.nombre ?? ''} ${_pacienteSeleccionado?.apellido ?? ''}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF27AE60),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'ID: ${_pacienteSeleccionado?.identificacion ?? ''}',
                                      style: TextStyle(
                                        color: Color(0xFF27AE60).withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_identificacionController.text.isNotEmpty && !_buscandoPaciente) ...[
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFF39C12).withOpacity(0.1),
                                Color(0xFFE67E22).withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(color: Color(0xFFF39C12).withOpacity(0.3), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF39C12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Paciente no encontrado con esta identificación',
                                  style: TextStyle(
                                    color: Color(0xFFF39C12),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
                
                // ✅ FORMULARIO PRINCIPAL PROFESIONAL
                _buildProfessionalCard(
                  borderColor: Color(0xFF3498DB),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ DIAGNÓSTICO
                      _buildMainTitle('DIAGNÓSTICO', Icons.medical_services_rounded, color: Color(0xFFE74C3C)),
                      _buildFieldRow([
                        _buildNumericField('DM', _dmController),
                        _buildNumericField('HTA', _htaController),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // ✅ # MUESTRAS ENVIADAS - ✅ CORREGIDO CON O24H
                      _buildMainTitle('MUESTRAS ENVIADAS', Icons.inventory_2_rounded, color: Color(0xFF9B59B6)),
                      _buildFieldRow([
                        _buildNumericField('A', _aController),
                        _buildNumericField('M', _mController),
                        _buildNumericField('OE', _oeController),
                      ]),
                      _buildFieldRow([
                        _buildNumericField('O24H', _o24hController), // ✅ MOSTRAR COMO O24H (más legible)
                        _buildNumericField('PO', _poController),
                        Container(), // Espacio vacío
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // ✅ TUBO LILA
                      _buildMainTitle('TUBO LILA', Icons.science_rounded, color: Color(0xFF8E44AD)),
                      _buildFieldRow([
                        _buildNumericField('H3', _h3Controller),
                        _buildNumericField('HBA1C', _hba1cController),
                        _buildNumericField('PTH', _pthController),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // ✅ TUBO AMARILLO
                      _buildMainTitle('TUBO AMARILLO', Icons.biotech_rounded, color: Color(0xFFF39C12)),
                      _buildFieldRow([
                        _buildNumericField('GLU', _gluController),
                        _buildNumericField('CREA', _creaController),
                        _buildNumericField('PL', _plController),
                      ]),
                      _buildFieldRow([
                        _buildNumericField('AU', _auController),
                        _buildNumericField('BUN', _bunController),
                        Container(),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // ✅ MUESTRA DE ORINA
                      _buildMainTitle('MUESTRA DE ORINA', Icons.water_drop_rounded, color: Color(0xFF17A2B8)),
                      
                      _buildSubTitle('ORINA ESP', color: Color(0xFF17A2B8)),
                      _buildFieldRow([
                        _buildNumericField('RELACIÓN CREA/ALB', _relacionCreaAlbController),
                        _buildNumericField('PO', _po2Controller),
                        Container(),
                      ]),
                      
                      _buildSubTitle('ORINA 24H', color: Color(0xFF20C997)),
                      _buildFieldRow([
                        _buildNumericField('DCRE24H', _dcre24hController),
                        _buildNumericField('ALB24H', _alb24hController),
                        _buildNumericField('BUNO24H', _buno24hController),
                      ]),
                      _buildFieldRow([
                        _buildNumericField('PESO', _pesoController, hint: 'kg'),
                        _buildNumericField('TALLA', _tallaController, hint: 'm'),
                        _buildNumericField('VOLM', _volmController, hint: 'ml'),
                      ]),
                      
                      SizedBox(height: 24),
                      
                      // ✅ PACIENTES NEFRO
                      _buildMainTitle('PACIENTES NEFRO', Icons.local_hospital_rounded, color: Color(0xFF28A745)),
                      
                      _buildSubTitle('TUBO AMARILLO', color: Color(0xFF28A745)),
                      _buildFieldRow([
                        _buildNumericField('FER', _ferController),
                        _buildNumericField('TRA', _traController),
                        _buildNumericField('FOSFAT', _fosfatController),
                      ]),
                      _buildFieldRow([
                        _buildNumericField('ALB', _albController),
                        _buildNumericField('FE', _feController),
                        _buildNumericField('TSH', _tshController),
                      ]),
                      _buildFieldRow([
                        _buildNumericField('P', _pController),
                        _buildNumericField('IONOGRAMA', _ionogramaController),
                        Container(),
                      ]),
                      
                      _buildSubTitle('FORRADOS', color: Color(0xFF6C757D)),
                      _buildFieldRow([
                        _buildNumericField('B12', _b12Controller),
                        _buildNumericField('Á. FÓLICO', _acidoFolicoController),
                        Container(),
                      ]),
                    ],
                  ),
                ),
                
                SizedBox(height: 120), // Espacio para el botón flotante
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Color(0xFF3498DB),
              Color(0xFF2980B9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3498DB).withOpacity(0.4),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (_pacienteSeleccionado == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Debe seleccionar un paciente válido',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFFE74C3C),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.all(16),
                  ),
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
                  o24h: _o24hController.text.isEmpty ? null : _o24hController.text, // ✅ CORRECTO: Usar o24h internamente
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
                
                // ✅ FEEDBACK VISUAL DE ÉXITO
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Muestra guardada exitosamente',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFF27AE60),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                Navigator.of(context).pop();
              } catch (e) {
                debugPrint('❌ Error creando detalle: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error al guardar la muestra: $e',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFFE74C3C),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.all(16),
                  ),
                );
              }
            }
          },
          icon: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.save_rounded,
              size: 22,
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
}

                // ✅
