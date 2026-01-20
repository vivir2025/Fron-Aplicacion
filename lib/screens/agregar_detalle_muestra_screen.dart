// screens/agregar_detalle_muestra_screen.dart - VERSIÓN CORREGIDA SIN VALORES POR DEFECTO
import 'package:flutter/material.dart';
import 'package:Bornive/database/database_helper.dart';
import 'package:Bornive/models/envio_muestra_model.dart';
import 'package:Bornive/models/paciente_model.dart';
import '../providers/paciente_provider.dart';
import '../models/paciente_model.dart';
import 'package:provider/provider.dart';
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
  
  // BÚSQUEDA POR IDENTIFICACIÓN
  final _identificacionController = TextEditingController();
  Paciente? _pacienteSeleccionado;
  bool _buscandoPaciente = false;
  
  // CONTROLADORES SEGÚN LA ESTRUCTURA EXACTA
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
  final _microoController = TextEditingController();
  final _creaoriController = TextEditingController();
  
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

  // ✅ MÉTODO PARA MOSTRAR DIÁLOGO DE AGREGAR PACIENTE
Future<void> _mostrarDialogoAgregarPaciente() async {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final identificacionNuevaController = TextEditingController(
    text: _identificacionController.text.trim() // Pre-llenar con la identificación buscada
  );
  DateTime? fechaNacimiento;
  String genero = 'Masculino';
  String? sedeSeleccionada;
  bool isSaving = false;

  // Obtener provider de pacientes
  final pacienteProvider = Provider.of<PacienteProvider>(context, listen: false);
  
  // Cargar sedes si no están cargadas
  if (pacienteProvider.sedes.isEmpty) {
    await pacienteProvider.loadSedes();
  }
  
  final sedes = pacienteProvider.sedes;
  
  if (sedes.isEmpty) {
    _showModernSnackBar(
      context,
      'No se pudieron cargar las sedes. Verifique su conexión.',
      Color(0xFFEF4444),
      Icons.error_rounded,
      isError: true,
    );
    return;
  }

  // Obtener sede del usuario actual
  final db = DatabaseHelper.instance;
  final currentUser = await db.getLoggedInUser();
  if (currentUser != null && currentUser['sede_id'] != null) {
    sedeSeleccionada = currentUser['sede_id'].toString();
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AlertDialog(
                title: Text(
                  'Crear Nuevo Paciente',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: identificacionNuevaController,
                          decoration: InputDecoration(
                            labelText: 'Identificación *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: genero,
                          items: ['Masculino', 'Femenino', 'Otro']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => genero = v!),
                          decoration: InputDecoration(
                            labelText: 'Género',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: sedeSeleccionada,
                          items: sedes.map<DropdownMenuItem<String>>((s) =>
                              DropdownMenuItem<String>(
                                  value: s['id'].toString(),
                                  child: Text(s['nombresede'] ?? ''))).toList(),
                          onChanged: (v) => setDialogState(() => sedeSeleccionada = v),
                          decoration: InputDecoration(
                            labelText: 'Sede',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (v) => v == null ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Fecha de Nacimiento'),
                          subtitle: Text(fechaNacimiento == null
                              ? 'Seleccionar fecha'
                              : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'),
                          trailing: Icon(Icons.calendar_today, color: Color(0xFF10B981)),
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now());
                            if (date != null) setDialogState(() => fechaNacimiento = date);
                          },
                        ),
                        if (isSaving)
                          const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: LinearProgressIndicator()),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          foregroundColor: Colors.white),
                      onPressed: isSaving ? null : () async {
                        if (formKey.currentState!.validate() && fechaNacimiento != null && sedeSeleccionada != null) {
                          setDialogState(() => isSaving = true);
                          
                          final nuevoPaciente = Paciente(
                            id: '',
                            identificacion: identificacionNuevaController.text.trim(),
                            fecnacimiento: fechaNacimiento!,
                            nombre: nombreController.text.trim(),
                            apellido: apellidoController.text.trim(),
                            genero: genero == 'Masculino' ? 'M' : (genero == 'Femenino' ? 'F' : 'O'),
                            idsede: sedeSeleccionada!,
                          );
                          
                          try {
                            await pacienteProvider.addPaciente(nuevoPaciente);
                            
                            // ✅ BUSCAR EL PACIENTE RECIÉN CREADO Y SELECCIONARLO
                            final pacienteCreado = await DatabaseHelper.instance
                                .getPacienteByIdentificacion(identificacionNuevaController.text.trim());
                            
                            if (mounted) {
                              Navigator.pop(context);
                              
                              // ✅ SELECCIONAR AUTOMÁTICAMENTE EL PACIENTE CREADO
                              setState(() {
                                _pacienteSeleccionado = pacienteCreado;
                              });
                              
                              _showModernSnackBar(
                                context,
                                'Paciente creado y seleccionado exitosamente',
                                Color(0xFF10B981),
                                Icons.check_circle_rounded,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              _showModernSnackBar(
                                context,
                                'Error: ${e.toString().replaceAll("Exception: ", "")}',
                                Color(0xFFEF4444),
                                Icons.error_rounded,
                                isError: true,
                              );
                            }
                          } finally {
                            if (mounted) setDialogState(() => isSaving = false);
                          }
                        }
                      },
                      child: const Text('Crear Paciente')),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  // ✅ FUNCIÓN HELPER PARA VALORES OPCIONALES - SIN VALORES POR DEFECTO
  String? _obtenerValorOpcional(TextEditingController controller) {
    final valor = controller.text.trim();
    return valor.isEmpty ? null : valor;
  }

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
      _microoController.dispose();
      _creaoriController.dispose();
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

  // BÚSQUEDA AUTOMÁTICA POR IDENTIFICACIÓN - MEJORADA
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

  // 🆕 WIDGET PARA CAMPOS OPCIONALES ULTRA MODERNOS - RESPONSIVO
  Widget _buildModernOptionalField(String label, TextEditingController controller, {String? hint, Color? accentColor}) {
    final color = accentColor ?? Color(0xFF6366F1);
    
    // 🆕 Obtener dimensiones para responsividad
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 6 : 8, 
        horizontal: isSmallScreen ? 3 : 6
      ), // 🆕 Margen adaptativo
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: isSmallScreen ? 6 : 8, 
              bottom: isSmallScreen ? 6 : 8
            ), // 🆕 Padding adaptativo
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : (isMediumScreen ? 12 : 13), // 🆕 Tamaño adaptativo
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
              maxLines: 1, // 🆕 Limitar a una línea
            ),
          ),
          Container(
            height: isSmallScreen ? 48 : (isMediumScreen ? 52 : 56), // 🆕 Altura adaptativa
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16), // 🆕 Border radius adaptativo
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
                  blurRadius: isSmallScreen ? 8 : 12, // 🆕 Blur adaptativo
                  offset: Offset(0, isSmallScreen ? 2 : 4), // 🆕 Offset adaptativo
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: isSmallScreen ? 4 : 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint ?? 'Opcional', // ✅ Hint mejorado sin valores por defecto
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isSmallScreen ? 12 : 14, // 🆕 Tamaño adaptativo
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide(color: color, width: 2.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 20, // 🆕 Padding adaptativo
                  vertical: isSmallScreen ? 12 : 16
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              keyboardType: TextInputType.text, // 🔄 Teclado normal
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16, // 🆕 Tamaño adaptativo
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                letterSpacing: 0.3,
              ),
              // ✅ SIN VALIDACIÓN OBLIGATORIA - CAMPOS OPCIONALES
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 TÍTULO PRINCIPAL ULTRA MODERNO CON GRADIENTES - RESPONSIVO
  Widget _buildUltraModernTitle(String title, IconData icon, {required Color primaryColor, required Color secondaryColor}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16, 
        horizontal: isSmallScreen ? 2 : 4
      ), // 🆕 Margen adaptativo
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20), // 🆕 Border radius adaptativo
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
            blurRadius: isSmallScreen ? 12 : 20, // 🆕 Blur adaptativo
            offset: Offset(0, isSmallScreen ? 4 : 8), // 🆕 Offset adaptativo
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isSmallScreen ? 6 : 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : (isMediumScreen ? 20 : 24)), // 🆕 Padding adaptativo
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // 🆕 Padding adaptativo
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14), // 🆕 Border radius adaptativo
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: isSmallScreen ? 6 : 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isSmallScreen ? 20 : 24, // 🆕 Tamaño adaptativo
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16), // 🆕 Espaciado adaptativo
            Expanded( // 🆕 Expandir para evitar overflow
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : (isMediumScreen ? 17 : 18), // 🆕 Tamaño adaptativo
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                maxLines: 2, // 🆕 Permitir hasta 2 líneas en títulos largos
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 SUBTÍTULO MODERNO CON EFECTOS - RESPONSIVO
  Widget _buildModernSubTitle(String title, {required Color color}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 10 : 14, 
        horizontal: isSmallScreen ? 16 : 20
      ), // 🆕 Padding adaptativo
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 10, 
        horizontal: isSmallScreen ? 8 : 12
      ), // 🆕 Margen adaptativo
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14), // 🆕 Border radius adaptativo
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: isSmallScreen ? 6 : 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: isSmallScreen ? 12 : 16, // 🆕 Altura adaptativa
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12), // 🆕 Espaciado adaptativo
          Expanded( // 🆕 Expandir para evitar overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14, // 🆕 Tamaño adaptativo
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 FILA DE CAMPOS CON ESPACIADO PERFECTO - RESPONSIVO
  Widget _buildFieldRow(List<Widget> fields) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 4 : 6, 
        horizontal: isSmallScreen ? 2 : 4
      ), // 🆕 Margen adaptativo
      child: isSmallScreen && fields.length > 2
          ? Column( // 🆕 En pantallas pequeñas, mostrar campos en columna si son más de 2
              children: fields.where((field) => field.runtimeType != Container || (field as Container).child != null).map((field) => 
                Container(
                  width: double.infinity,
                  child: field,
                )
              ).toList(),
            )
          : Row( // 🆕 En pantallas medianas/grandes, mantener en fila
              children: fields.map((field) => Expanded(child: field)).toList(),
            ),
    );
  }

  // 🆕 CARD ULTRA PREMIUM - RESPONSIVO
  Widget _buildPremiumCard({required Widget child, required Color primaryColor, required Color secondaryColor}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16), // 🆕 Margen adaptativo
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24), // 🆕 Border radius adaptativo
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
            blurRadius: isSmallScreen ? 16 : 24, // 🆕 Blur adaptativo
            offset: Offset(0, isSmallScreen ? 4 : 8), // 🆕 Offset adaptativo
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isSmallScreen ? 8 : 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: isSmallScreen ? 6 : 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : (isMediumScreen ? 22 : 28)), // 🆕 Padding adaptativo
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
    // 🆕 Obtener dimensiones para responsividad
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Nueva Muestra #${widget.numeroOrden}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20), // 🆕 Tamaño adaptativo
            letterSpacing: 0.5,
            color: Color(0xFF111827),
          ),
          overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(isSmallScreen ? 6 : 8), // 🆕 Margen adaptativo
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), // 🆕 Border radius adaptativo
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, size: isSmallScreen ? 18 : 20), // 🆕 Tamaño adaptativo
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
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 20, // 🆕 Padding lateral adaptativo
                isSmallScreen ? 100 : 120, // 🆕 Padding superior adaptativo
                isSmallScreen ? 12 : 20, // 🆕 Padding lateral adaptativo
                isSmallScreen ? 120 : 140 // 🆕 Padding inferior adaptativo
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BÚSQUEDA DE PACIENTE ULTRA MODERNA
                  _buildPremiumCard(
                    primaryColor: Color(0xFF10B981),
                    secondaryColor: Color(0xFF059669),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 10 : 14), // 🆕 Padding adaptativo
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16), // 🆕 Border radius adaptativo
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: isSmallScreen ? 8 : 12,
                                    offset: Offset(0, isSmallScreen ? 4 : 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 24 : 28, // 🆕 Tamaño adaptativo
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16), // 🆕 Espaciado adaptativo
                            Expanded( // 🆕 Expandir para evitar overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BUSCAR PACIENTE',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20), // 🆕 Tamaño adaptativo
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                  ),
                                  Text(
                                    'Ingrese la identificación',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14, // 🆕 Tamaño adaptativo
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 24), // 🆕 Espaciado adaptativo
                        
                        Container(
                          width: double.infinity, // 🆕 Asegurar ancho completo
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20), // 🆕 Border radius adaptativo
                            gradient: LinearGradient(
                              colors: [Colors.white, Color(0xFFFAFBFC)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF10B981).withOpacity(0.1),
                                blurRadius: isSmallScreen ? 12 : 16,
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
                                fontSize: isSmallScreen ? 14 : 16, // 🆕 Tamaño adaptativo
                              ),
                              hintText: 'Ej: 1234567890',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                                                fontSize: isSmallScreen ? 13 : 14, // 🆕 Tamaño adaptativo
                              ),
                              prefixIcon: Container(
                                margin: EdgeInsets.all(isSmallScreen ? 10 : 12), // 🆕 Margen adaptativo
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8), // 🆕 Padding adaptativo
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10), // 🆕 Border radius adaptativo
                                ),
                                child: Icon(
                                  Icons.badge_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 20, // 🆕 Tamaño adaptativo
                                ),
                              ),
                              suffixIcon: Container(
                                margin: EdgeInsets.all(isSmallScreen ? 10 : 12), // 🆕 Margen adaptativo
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8), // 🆕 Padding adaptativo
                                decoration: BoxDecoration(
                                  color: _buscandoPaciente 
                                      ? Colors.grey[100] 
                                      : Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10), // 🆕 Border radius adaptativo
                                ),
                                child: _buscandoPaciente 
                                    ? SizedBox(
                                        width: isSmallScreen ? 18 : 20, // 🆕 Tamaño adaptativo
                                        height: isSmallScreen ? 18 : 20, // 🆕 Tamaño adaptativo
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                        ),
                                      )
                                    : Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF10B981),
                                        size: isSmallScreen ? 18 : 20, // 🆕 Tamaño adaptativo
                                      ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                borderSide: BorderSide(color: Color(0xFF10B981), width: 2.5),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 24, // 🆕 Padding adaptativo
                                vertical: isSmallScreen ? 16 : 20 // 🆕 Padding adaptativo
                              ),
                            ),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16, // 🆕 Tamaño adaptativo
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
                          SizedBox(height: isSmallScreen ? 16 : 24), // 🆕 Espaciado adaptativo
                          Container(
                            width: double.infinity, // 🆕 Asegurar ancho completo
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 24), // 🆕 Padding adaptativo
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF10B981).withOpacity(0.1),
                                  Color(0xFF059669).withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(color: Color(0xFF10B981).withOpacity(0.3), width: 2),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20), // 🆕 Border radius adaptativo
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981).withOpacity(0.15),
                                  blurRadius: isSmallScreen ? 12 : 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12), // 🆕 Padding adaptativo
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14), // 🆕 Border radius adaptativo
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981).withOpacity(0.3),
                                        blurRadius: isSmallScreen ? 6 : 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 24 : 28, // 🆕 Tamaño adaptativo
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 16 : 20), // 🆕 Espaciado adaptativo
                                Expanded( // 🆕 Expandir para evitar overflow
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_pacienteSeleccionado?.nombre ?? ''} ${_pacienteSeleccionado?.apellido ?? ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: isSmallScreen ? 15 : 18, // 🆕 Tamaño adaptativo
                                          color: Color(0xFF111827),
                                        ),
                                        overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                        maxLines: 2, // 🆕 Permitir hasta 2 líneas
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'ID: ${_pacienteSeleccionado?.identificacion ?? ''}',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 12 : 14, // 🆕 Tamaño adaptativo
                                        ),
                                        overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ] else if (_identificacionController.text.isNotEmpty && !_buscandoPaciente) ...[
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B).withOpacity(0.1),
                                    Color(0xFFD97706).withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3), width: 2),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                          ),
                                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                                        ),
                                        child: Icon(
                                          Icons.warning_rounded,
                                          color: Colors.white,
                                          size: isSmallScreen ? 24 : 28,
                                        ),
                                      ),
                                      SizedBox(width: isSmallScreen ? 16 : 20),
                                      Expanded(
                                        child: Text(
                                          'Paciente no encontrado con esta identificación',
                                          style: TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w600,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // ✅ BOTÓN PARA AGREGAR NUEVO PACIENTE
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  Container(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _mostrarDialogoAgregarPaciente(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 20 : 24,
                                          vertical: isSmallScreen ? 12 : 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                        ),
                                        elevation: 4,
                                      ),
                                      icon: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.person_add_rounded,
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                      label: Text(
                                        'Crear Nuevo Paciente',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          letterSpacing: 0.5,
                                        ),
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
                  
                  // FORMULARIO PRINCIPAL ULTRA MODERNO
                  _buildPremiumCard(
                    primaryColor: Color(0xFF6366F1),
                    secondaryColor: Color(0xFF4F46E5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DIAGNÓSTICO
                        _buildUltraModernTitle(
                          'DIAGNÓSTICO', 
                          Icons.medical_services_rounded, 
                          primaryColor: Color(0xFFEF4444), 
                          secondaryColor: Color(0xFFDC2626)
                        ),
                        _buildFieldRow([
                          _buildModernOptionalField('DM', _dmController, accentColor: Color(0xFFEF4444)),
                          _buildModernOptionalField('HTA', _htaController, accentColor: Color(0xFFEF4444)),
                        ]),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32), // 🆕 Espaciado adaptativo
                        
                        // # MUESTRAS ENVIADAS
                        _buildUltraModernTitle(
                          'MUESTRAS ENVIADAS', 
                          Icons.inventory_2_rounded, 
                          primaryColor: Color(0xFF8B5CF6), 
                          secondaryColor: Color(0xFF7C3AED)
                        ),
                        _buildFieldRow([
                          _buildModernOptionalField('A', _aController, accentColor: Color(0xFF8B5CF6)),
                          _buildModernOptionalField('M', _mController, accentColor: Color(0xFF8B5CF6)),
                          _buildModernOptionalField('OE', _oeController, accentColor: Color(0xFF8B5CF6)),
                        ]),
                        _buildFieldRow([
                          _buildModernOptionalField('O24H', _o24hController, accentColor: Color(0xFF8B5CF6)),
                          _buildModernOptionalField('PO', _poController, accentColor: Color(0xFF8B5CF6)),
                          Container(), // Espacio vacío
                        ]),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32), // 🆕 Espaciado adaptativo
                        
                        // TUBO LILA
                        _buildUltraModernTitle(
                          'TUBO LILA', 
                          Icons.science_rounded, 
                          primaryColor: Color(0xFFA855F7), 
                          secondaryColor: Color(0xFF9333EA)
                        ),
                        _buildFieldRow([
                          _buildModernOptionalField('H3', _h3Controller, accentColor: Color(0xFFA855F7)),
                          _buildModernOptionalField('HBA1C', _hba1cController, accentColor: Color(0xFFA855F7)),
                          _buildModernOptionalField('PTH', _pthController, accentColor: Color(0xFFA855F7)),
                        ]),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32), // 🆕 Espaciado adaptativo
                        
                        // TUBO AMARILLO
                        _buildUltraModernTitle(
                          'TUBO AMARILLO', 
                          Icons.biotech_rounded, 
                          primaryColor: Color(0xFFF59E0B), 
                          secondaryColor: Color(0xFFD97706)
                        ),
                        _buildFieldRow([
                          _buildModernOptionalField('GLU', _gluController, accentColor: Color(0xFFF59E0B)),
                          _buildModernOptionalField('CREA', _creaController, accentColor: Color(0xFFF59E0B)),
                          _buildModernOptionalField('PL', _plController, accentColor: Color(0xFFF59E0B)),
                        ]),
                        _buildFieldRow([
                          _buildModernOptionalField('AU', _auController, accentColor: Color(0xFFF59E0B)),
                          _buildModernOptionalField('BUN', _bunController, accentColor: Color(0xFFF59E0B)),
                          Container(),
                        ]),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32), // 🆕 Espaciado adaptativo
                        
                        // MUESTRA DE ORINA
                        _buildUltraModernTitle(
                          'MUESTRA DE ORINA', 
                          Icons.water_drop_rounded, 
                          primaryColor: Color(0xFF06B6D4), 
                          secondaryColor: Color(0xFF0891B2)
                        ),
                        
                        _buildModernSubTitle('ORINA ESP', color: Color(0xFF06B6D4)),
                        _buildFieldRow([
                          _buildModernOptionalField('RELACIÓN CREA/ALB', _relacionCreaAlbController, accentColor: Color(0xFF06B6D4)),
                          _buildModernOptionalField('PO', _po2Controller, accentColor: Color(0xFF06B6D4)),
                           _buildModernOptionalField('MICRO', _microoController, accentColor: Color(0xFF06B6D4)),
                            _buildModernOptionalField('CREA/ORINA', _creaoriController, accentColor: Color(0xFF06B6D4)),
                          Container(),
                        ]),
                        
                        _buildModernSubTitle('ORINA 24H', color: Color(0xFF059669)),
                        _buildFieldRow([
                          _buildModernOptionalField('DCRE24H', _dcre24hController, accentColor: Color(0xFF059669)),
                          _buildModernOptionalField('ALB24H', _alb24hController, accentColor: Color(0xFF059669)),
                          _buildModernOptionalField('BUNO24H', _buno24hController, accentColor: Color(0xFF059669)),
                        ]),
                        _buildFieldRow([
                          _buildModernOptionalField('PESO', _pesoController, hint: 'kg', accentColor: Color(0xFF059669)), // ✅ CORREGIDO
                          _buildModernOptionalField('TALLA', _tallaController, hint: 'm', accentColor: Color(0xFF059669)), // ✅ CORREGIDO
                          _buildModernOptionalField('VOLM', _volmController, hint: 'ml', accentColor: Color(0xFF059669)), // ✅ CORREGIDO
                        ]),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32), // 🆕 Espaciado adaptativo
                        
                        // PACIENTES NEFRO
                        _buildUltraModernTitle(
                          'PACIENTES NEFRO', 
                          Icons.local_hospital_rounded, 
                          primaryColor: Color(0xFF10B981), 
                          secondaryColor: Color(0xFF059669)
                        ),
                        
                        _buildModernSubTitle('TUBO AMARILLO', color: Color(0xFF10B981)),
                        _buildFieldRow([
                          _buildModernOptionalField('FER', _ferController, accentColor: Color(0xFF10B981)),
                          _buildModernOptionalField('TRA', _traController, accentColor: Color(0xFF10B981)),
                          _buildModernOptionalField('FOSFAT', _fosfatController, accentColor: Color(0xFF10B981)),
                        ]),
                        _buildFieldRow([
                          _buildModernOptionalField('ALB', _albController, accentColor: Color(0xFF10B981)),
                          _buildModernOptionalField('FE', _feController, accentColor: Color(0xFF10B981)),
                          _buildModernOptionalField('TSH', _tshController, accentColor: Color(0xFF10B981)),
                        ]),
                        _buildFieldRow([
                          _buildModernOptionalField('P', _pController, accentColor: Color(0xFF10B981)),
                          _buildModernOptionalField('IONOGRAMA', _ionogramaController, accentColor: Color(0xFF10B981)),
                          Container(),
                        ]),
                        
                        _buildModernSubTitle('FORRADOS', color: Color(0xFF6B7280)),
                        _buildFieldRow([
                          _buildModernOptionalField('B12', _b12Controller, accentColor: Color(0xFF6B7280)),
                          _buildModernOptionalField('Á. FÓLICO', _acidoFolicoController, accentColor: Color(0xFF6B7280)),
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24), // 🆕 Border radius adaptativo
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
              blurRadius: isSmallScreen ? 16 : 20, // 🆕 Blur adaptativo
              offset: Offset(0, isSmallScreen ? 8 : 10), // 🆕 Offset adaptativo
            ),
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.2),
              blurRadius: isSmallScreen ? 32 : 40,
              offset: Offset(0, isSmallScreen ? 16 : 20),
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
                  
                  // ✅ CAMPOS OPCIONALES - PUEDEN SER NULL
                  dm: _obtenerValorOpcional(_dmController),
                  hta: _obtenerValorOpcional(_htaController),
                  numMuestrasEnviadas: null,
                  tuboLila: null,
                  tuboAmarillo: null,
                  tuboAmarilloForrado: null,
                  orinaEsp: _obtenerValorOpcional(_relacionCreaAlbController),
                  orina24h: null,
                  a: _obtenerValorOpcional(_aController),
                  m: _obtenerValorOpcional(_mController),
                  oe: _obtenerValorOpcional(_oeController),
                  o24h: _obtenerValorOpcional(_o24hController),
                  po: _obtenerValorOpcional(_poController),
                  h3: _obtenerValorOpcional(_h3Controller),
                  hba1c: _obtenerValorOpcional(_hba1cController),
                  pth: _obtenerValorOpcional(_pthController),
                  glu: _obtenerValorOpcional(_gluController),
                  crea: _obtenerValorOpcional(_creaController),
                  pl: _obtenerValorOpcional(_plController),
                  au: _obtenerValorOpcional(_auController),
                  bun: _obtenerValorOpcional(_bunController),
                  relacionCreaAlb: _obtenerValorOpcional(_relacionCreaAlbController),
                  dcre24h: _obtenerValorOpcional(_dcre24hController),
                  alb24h: _obtenerValorOpcional(_alb24hController),
                  buno24h: _obtenerValorOpcional(_buno24hController),
                  fer: _obtenerValorOpcional(_ferController),
                  tra: _obtenerValorOpcional(_traController),
                  fosfat: _obtenerValorOpcional(_fosfatController),
                  alb: _obtenerValorOpcional(_albController),
                  fe: _obtenerValorOpcional(_feController),
                  tsh: _obtenerValorOpcional(_tshController),
                  p: _obtenerValorOpcional(_pController),
                  ionograma: _obtenerValorOpcional(_ionogramaController),
                  b12: _obtenerValorOpcional(_b12Controller),
                  acidoFolico: _obtenerValorOpcional(_acidoFolicoController),
                  
                  // ✅ CAMPOS NUMÉRICOS OPCIONALES - PUEDEN SER NULL
                  peso: _obtenerValorOpcional(_pesoController),
                  talla: _obtenerValorOpcional(_tallaController),
                  volumen: _obtenerValorOpcional(_volmController),
                  microo: _obtenerValorOpcional(_microoController),
                  creaori: _obtenerValorOpcional(_creaoriController),
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
            padding: EdgeInsets.all(isSmallScreen ? 3 : 4), // 🆕 Padding adaptativo
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10), // 🆕 Border radius adaptativo
            ),
            child: Icon(
              Icons.save_rounded,
              size: isSmallScreen ? 20 : 24, // 🆕 Tamaño adaptativo
              color: Colors.white,
            ),
          ),
          label: Text(
            isSmallScreen ? 'Guardar' : 'Guardar Muestra', // 🆕 Texto adaptativo
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16, // 🆕 Tamaño adaptativo
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

  // 🆕 SNACKBAR ULTRA MODERNO - RESPONSIVO
  void _showModernSnackBar(BuildContext context, String message, Color color, IconData icon, {bool isError = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8), // 🆕 Padding adaptativo
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8), // 🆕 Padding adaptativo
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10), // 🆕 Border radius adaptativo
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24, // 🆕 Tamaño adaptativo
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16), // 🆕 Espaciado adaptativo
              Expanded( // 🆕 Expandir para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isSmallScreen ? 14 : 16, // 🆕 Tamaño adaptativo
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.visible, // 🆕 Permitir múltiples líneas
                    ),
                    if (!isError && _pacienteSeleccionado != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Paciente: ${_pacienteSeleccionado?.nombre} ${_pacienteSeleccionado?.apellido}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13, // 🆕 Tamaño adaptativo
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16), // 🆕 Border radius adaptativo
        ),
        margin: EdgeInsets.all(isSmallScreen ? 16 : 20), // 🆕 Margen adaptativo
        duration: Duration(seconds: isError ? 4 : 3),
        elevation: 8,
      ),
    );
  }
}
