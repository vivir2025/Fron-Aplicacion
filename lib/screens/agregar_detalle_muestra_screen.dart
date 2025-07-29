// screens/agregar_detalle_muestra_screen.dart
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

class _AgregarDetalleMuestraScreenState extends State<AgregarDetalleMuestraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  
  // ✅ BÚSQUEDA POR IDENTIFICACIÓN
  final _identificacionController = TextEditingController();
  Paciente? _pacienteSeleccionado;
  bool _buscandoPaciente = false;
  
  // ✅ DIAGNÓSTICO
  final _dmController = TextEditingController();
  final _htaController = TextEditingController();
  
  // ✅ # MUESTRAS ENVIADAS
  final _numMuestrasController = TextEditingController();
  
  // ✅ TUBO LILA
  final _tuboLilaController = TextEditingController();
  
  // ✅ TUBO AMARILLO
  final _tuboAmarilloController = TextEditingController();
  
  // ✅ TUBO AMARILLO FORRADO
  final _tuboAmarilloForradoController = TextEditingController();
  
  // ✅ MUESTRA DE ORINA
  final _orinaEspController = TextEditingController();
  final _orina24hController = TextEditingController();
  
  // ✅ PACIENTES NEFRO (SEGÚN EL ORDEN EXACTO)
  final _aController = TextEditingController();
  final _mController = TextEditingController();
  final _oeController = TextEditingController();
  final _o24hController = TextEditingController(); // 024H
  final _poController = TextEditingController();
  final _h3Controller = TextEditingController();
  final _hba1cController = TextEditingController();
  final _pthController = TextEditingController();
  final _gluController = TextEditingController();
  final _creaController = TextEditingController();
  final _plController = TextEditingController();
  final _auController = TextEditingController();
  final _bunController = TextEditingController();
  final _po2Controller = TextEditingController(); // PO (segundo)
  final _relacionCreaAlbController = TextEditingController();
  final _dcre24hController = TextEditingController();
  final _alb24hController = TextEditingController();
  final _buno24hController = TextEditingController();
  final _pesoController = TextEditingController();
  final _tallaController = TextEditingController();
  final _volmController = TextEditingController(); // VOLM
  final _ferController = TextEditingController();
  final _traController = TextEditingController();
  final _fosfatController = TextEditingController();
  final _albController = TextEditingController();
  final _feController = TextEditingController();
  final _tshController = TextEditingController();
  final _pController = TextEditingController();
  final _ionogramaController = TextEditingController();
  final _b12Controller = TextEditingController();
  final _acidoFolicoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _identificacionController.addListener(_buscarPacientePorIdentificacion);
  }

  @override
  void dispose() {
    // Dispose todos los controladores
    _identificacionController.dispose();
    _dmController.dispose();
    _htaController.dispose();
    _numMuestrasController.dispose();
    _tuboLilaController.dispose();
    _tuboAmarilloController.dispose();
    _tuboAmarilloForradoController.dispose();
    _orinaEspController.dispose();
    _orina24hController.dispose();
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
    super.dispose();
  }

  // ✅ BÚSQUEDA AUTOMÁTICA POR IDENTIFICACIÓN
  void _buscarPacientePorIdentificacion() async {
    final identificacion = _identificacionController.text.trim();
    
    if (identificacion.isEmpty) {
      setState(() {
        _pacienteSeleccionado = null;
        _buscandoPaciente = false;
      });
      return;
    }

    if (identificacion.length >= 3) {
      setState(() => _buscandoPaciente = true);
      
      try {
        final dbHelper = DatabaseHelper.instance;
        final paciente = await dbHelper.getPacienteByIdentificacion(identificacion);
        
        setState(() {
          _pacienteSeleccionado = paciente;
          _buscandoPaciente = false;
        });
        
        if (paciente != null) {
          debugPrint('✅ Paciente encontrado: ${paciente.nombre} ${paciente.apellido}');
        }
      } catch (e) {
        debugPrint('❌ Error buscando paciente: $e');
        setState(() => _buscandoPaciente = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(
          color: isRequired ? Colors.red[700] : null,
          fontWeight: isRequired ? FontWeight.bold : null,
        ),
      ),
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      } : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Muestra #${widget.numeroOrden}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ BÚSQUEDA DE PACIENTE
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('BUSCAR PACIENTE'),
                      
                      TextFormField(
                        controller: _identificacionController,
                        decoration: InputDecoration(
                          labelText: 'Número de Identificación *',
                          hintText: 'Ingrese la identificación del paciente',
                          border: OutlineInputBorder(),
                          suffixIcon: _buscandoPaciente 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.search),
                        ),
                                                validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la identificación del paciente';
                          }
                          return null;
                        },
                      ),
                      
                      if (_pacienteSeleccionado != null) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_pacienteSeleccionado!.nombre} ${_pacienteSeleccionado!.apellido}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('ID: ${_pacienteSeleccionado!.identificacion}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_identificacionController.text.isNotEmpty && !_buscandoPaciente) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Paciente no encontrado con esta identificación'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // ✅ DIAGNÓSTICO
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('DIAGNÓSTICO'),
                      
                      Row(
                        children: [
                          Expanded(child: _buildTextField('DM', _dmController, hint: 'Ej: Tipo 1, Tipo 2, Controlada')),
                          SizedBox(width: 12),
                          Expanded(child: _buildTextField('HTA', _htaController, hint: 'Ej: Controlada, No controlada')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // ✅ # MUESTRAS ENVIADAS
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('# MUESTRAS ENVIADAS'),
                      
                      _buildTextField('Número de Muestras', _numMuestrasController, hint: 'Ej: 1, 2, 3, etc.'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // ✅ TUBO LILA
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('TUBO LILA'),
                      
                      _buildTextField('TUBO LILA', _tuboLilaController, hint: 'Ej: 1 tubo, 2 tubos, etc.'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // ✅ TUBO AMARILLO
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('TUBO AMARILLO'),
                      
                      _buildTextField('TUBO AMARILLO', _tuboAmarilloController, hint: 'Ej: 1 tubo, 2 tubos, etc.'),
                      SizedBox(height: 12),
                      _buildTextField('TUBO AMARILLO FORRADO', _tuboAmarilloForradoController, hint: 'Ej: 1 tubo, 2 tubos, etc.'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // ✅ MUESTRA DE ORINA
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('MUESTRA DE ORINA'),
                      
                      Row(
                        children: [
                          Expanded(child: _buildTextField('ORINA ESP', _orinaEspController, hint: 'Ej: 50ml, 100ml')),
                          SizedBox(width: 12),
                          Expanded(child: _buildTextField('ORINA 24H', _orina24hController, hint: 'Ej: 2000ml, 1500ml')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // ✅ PACIENTES NEFRO (ORGANIZADO SEGÚN LA TABLA)
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('PACIENTES NEFRO'),
                      
                      // Primera fila: A, M, OE, 024H, PO, H3
                      Row(
                        children: [
                          Expanded(child: _buildTextField('A', _aController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('M', _mController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('OE', _oeController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('024H', _o24hController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('PO', _poController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('H3', _h3Controller)),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Segunda fila: HBA1C, PTH, GLU, CREA, PL, AU
                      Row(
                        children: [
                          Expanded(child: _buildTextField('HBA1C', _hba1cController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('PTH', _pthController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('GLU', _gluController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('CREA', _creaController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('PL', _plController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('AU', _auController)),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Tercera fila: BUN, PO (segundo), RELACION CREA/ALB
                      Row(
                        children: [
                          Expanded(child: _buildTextField('BUN', _bunController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('PO', _po2Controller)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('RELACIÓN CREA/ALB', _relacionCreaAlbController)),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Cuarta fila: DCRE24H, ALB24H, BUNO24H
                      Row(
                        children: [
                          Expanded(child: _buildTextField('DCRE24H', _dcre24hController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('ALB24H', _alb24hController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('BUNO24H', _buno24hController)),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Quinta fila: PESO, TALLA, VOLM
                      Row(
                        children: [
                          Expanded(child: _buildTextField('PESO', _pesoController, hint: 'kg')),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('TALLA', _tallaController, hint: 'm')),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('VOLM', _volmController, hint: 'ml')),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Sexta fila: FER, TRA, FOSFAT, ALB
                      Row(
                        children: [
                          Expanded(child: _buildTextField('FER', _ferController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('TRA', _traController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('FOSFAT', _fosfatController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('ALB', _albController)),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Séptima fila: FE, TSH, P, IONOGRAMA
                      Row(
                        children: [
                          Expanded(child: _buildTextField('FE', _feController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('TSH', _tshController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('P', _pController)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('IONOGRAMA', _ionogramaController)),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      // Octava fila: B12, Á. FOL
                      Row(
                        children: [
                          Expanded(child: _buildTextField('B12', _b12Controller)),
                          SizedBox(width: 8),
                          Expanded(child: _buildTextField('Á. FÓLICO', _acidoFolicoController)),
                          SizedBox(width: 8),
                          Expanded(child: Container()), // Espacio vacío
                          SizedBox(width: 8),
                          Expanded(child: Container()), // Espacio vacío
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 80), // Espacio para el botón flotante
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            if (_pacienteSeleccionado == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Debe seleccionar un paciente válido'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final detalle = DetalleEnvioMuestra(
              id: DetalleEnvioMuestra.generarIdCorto(),
              envioMuestraId: '',
              pacienteId: _pacienteSeleccionado!.id,
              numeroOrden: widget.numeroOrden,
              dm: _dmController.text.isEmpty ? null : _dmController.text,
              hta: _htaController.text.isEmpty ? null : _htaController.text,
              numMuestrasEnviadas: _numMuestrasController.text.isEmpty ? null : _numMuestrasController.text,
              tuboLila: _tuboLilaController.text.isEmpty ? null : _tuboLilaController.text,
              tuboAmarillo: _tuboAmarilloController.text.isEmpty ? null : _tuboAmarilloController.text,
              tuboAmarilloForrado: _tuboAmarilloForradoController.text.isEmpty ? null : _tuboAmarilloForradoController.text,
              orinaEsp: _orinaEspController.text.isEmpty ? null : _orinaEspController.text,
              orina24h: _orina24hController.text.isEmpty ? null : _orina24hController.text,
              a: _aController.text.isEmpty ? null : _aController.text,
              m: _mController.text.isEmpty ? null : _mController.text,
              oe: _oeController.text.isEmpty ? null : _oeController.text,
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
            Navigator.of(context).pop();
          }
        },
        icon: Icon(Icons.save),
        label: Text('Guardar Muestra'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
    );
  }
}
