// screens/findrisk/findrisk_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/paciente_model.dart';
import '../../services/findrisk_service.dart';
import '../../database/database_helper.dart';

class FindriskFormScreen extends StatefulWidget {
  const FindriskFormScreen({Key? key}) : super(key: key);

  @override
  State<FindriskFormScreen> createState() => _FindriskFormScreenState();
}
// Continuación de findrisk_form_screen.dart

class _FindriskFormScreenState extends State<FindriskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  
  // Controladores de texto
  final _identificacionController = TextEditingController();
  final _veredaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _tallaController = TextEditingController();
  final _perimetroController = TextEditingController();
  final _conductaController = TextEditingController();
  final _promotorController = TextEditingController();

  // Variables del formulario
  Paciente? _pacienteSeleccionado;
  String? _sedeSeleccionada;
  List<Map<String, dynamic>> _sedes = [];
  
  // Respuestas del test
  String _actividadFisica = '';
  String _medicamentosHipertension = '';
  String _frecuenciaFrutas = '';
  String _azucarAlto = '';
  String _antecedentesFamiliares = '';
  
  // Estados
  bool _isLoading = false;
  bool _buscandoPaciente = false;
  double _imc = 0;
  int _puntajeCalculado = 0;

  @override
  void initState() {
    super.initState();
    _loadSedes();
    _setupListeners();
  }

  void _setupListeners() {
    _pesoController.addListener(_calcularIMC);
    _tallaController.addListener(_calcularIMC);
  }

  Future<void> _loadSedes() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final sedes = await dbHelper.getSedes();
      setState(() {
        _sedes = sedes;
        if (_sedes.isNotEmpty) {
          _sedeSeleccionada = _sedes.first['id'];
        }
      });
    } catch (e) {
      debugPrint('Error cargando sedes: $e');
    }
  }

  void _calcularIMC() {
    final peso = double.tryParse(_pesoController.text) ?? 0;
    final talla = double.tryParse(_tallaController.text) ?? 0;
    
    if (peso > 0 && talla > 0) {
      final tallaMetros = talla / 100;
      setState(() {
        _imc = double.parse((peso / (tallaMetros * tallaMetros)).toStringAsFixed(2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Test FINDRISK'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousPage,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicador de progreso
            _buildProgressIndicator(),
            
            // Contenido de las páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildPage1(), // Datos del paciente
                  _buildPage2(), // Preguntas 1-3
                  _buildPage3(), // Datos físicos
                  _buildPage4(), // Antecedentes y finalización
                ],
              ),
            ),
            
            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentPage ? Colors.blue[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Página 1: Datos del paciente
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del Paciente',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Búsqueda de paciente
          TextFormField(
            controller: _identificacionController,
            decoration: InputDecoration(
              labelText: 'Identificación del Paciente',
              hintText: 'Ingrese el número de identificación',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _buscandoPaciente
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.person_search),
                      onPressed: _buscarPaciente,
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la identificación';
              }
              return null;
            },
            onFieldSubmitted: (_) => _buscarPaciente(),
          ),
          
          const SizedBox(height: 16),
          
          // Información del paciente encontrado
          if (_pacienteSeleccionado != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Paciente Encontrado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Nombre: ${_pacienteSeleccionado!.nombreCompleto}'),
                  Text('Género: ${_pacienteSeleccionado!.genero}'),
                  Text('Fecha de nacimiento: ${_formatDate(_pacienteSeleccionado!.fecnacimiento)}'),
                  Text('Edad: ${_calcularEdad(_pacienteSeleccionado!.fecnacimiento)} años'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Selección de sede
          DropdownButtonFormField<String>(
            value: _sedeSeleccionada,
            decoration: InputDecoration(
              labelText: 'Sede',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _sedes.map((sede) {
              return DropdownMenuItem<String>(
                value: sede['id'],
                child: Text(sede['nombresede'] ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _sedeSeleccionada = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor seleccione una sede';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campos opcionales
          TextFormField(
            controller: _veredaController,
            decoration: InputDecoration(
              labelText: 'Vereda (Opcional)',
              prefixIcon: const Icon(Icons.place),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _telefonoController,
            decoration: InputDecoration(
              labelText: 'Teléfono (Opcional)',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // Página 2: Preguntas 1-3
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preguntas de Evaluación',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Pregunta 1: Actividad física
          _buildQuestionCard(
            '1. ¿Realiza al menos 30 minutos de actividad física en el trabajo y/o en el tiempo libre?',
            _actividadFisica,
            [
              {'value': 'si', 'text': 'Sí', 'points': 0},
              {'value': 'no', 'text': 'No', 'points': 2},
            ],
            (value) => setState(() => _actividadFisica = value),
          ),
          
          const SizedBox(height: 16),
          
          // Pregunta 2: Medicamentos
          _buildQuestionCard(
            '2. ¿Ha tomado medicamentos para la hipertensión arterial de forma regular?',
            _medicamentosHipertension,
            [
              {'value': 'no', 'text': 'No', 'points': 0},
              {'value': 'si', 'text': 'Sí', 'points': 2},
            ],
            (value) => setState(() => _medicamentosHipertension = value),
          ),
          
          const SizedBox(height: 16),
          
          // Pregunta 3: Frutas y verduras
          _buildQuestionCard(
            '3. ¿Come frutas y verduras todos los días?',
            _frecuenciaFrutas,
            [
              {'value': 'diariamente', 'text': 'Sí, todos los días', 'points': 0},
              {'value': 'no_diariamente', 'text': 'No todos los días', 'points': 1},
            ],
            (value) => setState(() => _frecuenciaFrutas = value),
          ),
          
          const SizedBox(height: 16),
          
          // Pregunta 4: Azúcar alto
          _buildQuestionCard(
            '4. ¿Le han encontrado alguna vez valores de azúcar altos en sangre?',
            _azucarAlto,
            [
              {'value': 'no', 'text': 'No', 'points': 0},
              {'value': 'si', 'text': 'Sí', 'points': 5},
            ],
            (value) => setState(() => _azucarAlto = value),
          ),
        ],
      ),
    );
  }

  // Página 3: Datos físicos
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos Físicos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Peso
          TextFormField(
            controller: _pesoController,
            decoration: InputDecoration(
              labelText: 'Peso (kg)',
              prefixIcon: const Icon(Icons.monitor_weight),
              suffixText: 'kg',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el peso';
              }
              final peso = double.tryParse(value);
              if (peso == null || peso <= 0 || peso > 300) {
                return 'Ingrese un peso válido (1-300 kg)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Talla
          TextFormField(
            controller: _tallaController,
            decoration: InputDecoration(
              labelText: 'Talla (cm)',
              prefixIcon: const Icon(Icons.height),
              suffixText: 'cm',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la talla';
              }
              final talla = double.tryParse(value);
              if (talla == null || talla <= 50 || talla > 250) {
                return 'Ingrese una talla válida (50-250 cm)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // IMC calculado
          if (_imc > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'IMC Calculado: ${_imc.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getIMCCategory(_imc),
                    style: TextStyle(
                      color: _getIMCColor(_imc),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Perímetro abdominal
          TextFormField(
            controller: _perimetroController,
            decoration: InputDecoration(
              labelText: 'Perímetro Abdominal (cm)',
              prefixIcon: const Icon(Icons.straighten),
              suffixText: 'cm',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              helperText: _pacienteSeleccionado != null 
                  ? _getPerimetroHelperText(_pacienteSeleccionado!.genero)
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el perímetro abdominal';
              }
              final perimetro = double.tryParse(value);
              if (perimetro == null || perimetro <= 30 || perimetro > 200) {
                return 'Ingrese un perímetro válido (30-200 cm)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Página 4: Antecedentes y finalización
  Widget _buildPage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antecedentes y Finalización',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Pregunta 5: Antecedentes familiares
          _buildQuestionCard(
            '5. ¿Tiene familiares de primer o segundo grado con diabetes?',
            _antecedentesFamiliares,
            [
              {'value': 'no', 'text': 'No', 'points': 0},
              {'value': 'abuelos_tios_primos', 'text': 'Sí: abuelos, tíos, primos hermanos', 'points': 3},
              {'value': 'padres_hermanos_hijos', 'text': 'Sí: padres, hermanos, hijos', 'points': 5},
            ],
            (value) => setState(() => _antecedentesFamiliares = value),
          ),
          
          const SizedBox(height: 20),
          
          // Conducta (opcional)
          TextFormField(
            controller: _conductaController,
            decoration: InputDecoration(
              labelText: 'Conducta/Recomendaciones (Opcional)',
              prefixIcon: const Icon(Icons.note),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Promotor de vida (opcional)
          TextFormField(
            controller: _promotorController,
            decoration: InputDecoration(
              labelText: 'Promotor de Vida (Opcional)',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Resumen del test (si está completo)
          if (_canCalculateScore()) ...[
            _buildScorePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    String question,
    String currentValue,
    List<Map<String, dynamic>> options,
    Function(String) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option['text']),
                subtitle: Text('Puntos: ${option['points']}'),
                value: option['value'],
                groupValue: currentValue,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePreview() {
    final puntajeTotal = _calculateTotalScore();
    final interpretacion = _getInterpretacion(puntajeTotal);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(interpretacion['color']).withOpacity(0.1),
        border: Border.all(color: Color(interpretacion['color'])),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: Color(interpretacion['color']),
              ),
              const SizedBox(width: 8),
              const Text(
                'Resultado del Test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Puntaje Total: $puntajeTotal puntos',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nivel de Riesgo: ${interpretacion['nivel']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(interpretacion['color']),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Probabilidad: ${interpretacion['riesgo']}',
            style: TextStyle(
              fontSize: 14,
              color: Color(interpretacion['color']),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            interpretacion['descripcion'],
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Anterior'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 3 ? _submitForm : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentPage == 3 ? 'Guardar Test' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        if (_pacienteSeleccionado == null) {
          _showError('Por favor busque y seleccione un paciente');
          return false;
        }
        if (_sedeSeleccionada == null) {
          _showError('Por favor seleccione una sede');
          return false;
        }
        return true;
      case 1:
        if (_actividadFisica.isEmpty || _medicamentosHipertension.isEmpty ||
            _frecuenciaFrutas.isEmpty || _azucarAlto.isEmpty) {
          _showError('Por favor responda todas las preguntas');
          return false;
        }
        return true;
      case 2:
        return _formKey.currentState?.validate() ?? false;
      case 3:
        if (_antecedentesFamiliares.isEmpty) {
          _showError('Por favor responda la pregunta sobre antecedentes familiares');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _buscarPaciente() async {
    final identificacion = _identificacionController.text.trim();
    if (identificacion.isEmpty) {
      _showError('Por favor ingrese un número de identificación');
      return;
    }

    setState(() => _buscandoPaciente = true);

    try {
      final paciente = await FindriskService.buscarPacientePorIdentificacion(identificacion);
      
      setState(() {
        _pacienteSeleccionado = paciente;
        _buscandoPaciente = false;
      });

      if (paciente == null) {
        _showError('No se encontró un paciente con esa identificación');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente encontrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _buscandoPaciente = false);
      _showError('Error al buscar paciente: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentPage()) return;

    setState(() => _isLoading = true);

    try {
      // Obtener token (implementar según tu sistema de autenticación)
      final token = await _getAuthToken();

      final result = await FindriskService.crearFindriskTest(
        pacienteId: _pacienteSeleccionado!.id,
        sedeId: _sedeSeleccionada!,
        vereda: _veredaController.text.trim().isNotEmpty ? _veredaController.text.trim() : null,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        actividadFisica: _actividadFisica,
        medicamentosHipertension: _medicamentosHipertension,
        frecuenciaFrutasVerduras: _frecuenciaFrutas,
        azucarAltoDetectado: _azucarAlto,
        peso: double.parse(_pesoController.text),
        talla: double.parse(_tallaController.text),
        perimetroAbdominal: double.parse(_perimetroController.text),
        antecedentesFamiliares: _antecedentesFamiliares,
        conducta: _conductaController.text.trim().isNotEmpty ? _conductaController.text.trim() : null,
        promotorVida: _promotorController.text.trim().isNotEmpty ? _promotorController.text.trim() : null,
        token: token,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (!mounted) return;
        
        // Mostrar resultado
        await _showResultDialog(result['test']);
        
        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      } else {
        _showError(result['error'] ?? 'Error desconocido al guardar el test');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al guardar el test: $e');
    }
  }

  Future<void> _showResultDialog(dynamic test) async {
    final interpretacion = _getInterpretacion(_calculateTotalScore());
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
            ),
            const SizedBox(width: 8),
            const Text('Test Completado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El test FINDRISK se ha guardado exitosamente.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(interpretacion['color']).withOpacity(0.1),
                border: Border.all(color: Color(interpretacion['color'])),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resultado: ${interpretacion['nivel']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(interpretacion['color']),
                    ),
                  ),
                  Text('Puntaje: ${_calculateTotalScore()} puntos'),
                  Text('Riesgo: ${interpretacion['riesgo']}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Métodos de cálculo
  bool _canCalculateScore() {
    return _pacienteSeleccionado != null &&
           _actividadFisica.isNotEmpty &&
           _medicamentosHipertension.isNotEmpty &&
           _frecuenciaFrutas.isNotEmpty &&
           _azucarAlto.isNotEmpty &&
           _pesoController.text.isNotEmpty &&
           _tallaController.text.isNotEmpty &&
           _perimetroController.text.isNotEmpty &&
           _antecedentesFamiliares.isNotEmpty;
  }

 // Continuación del método _calculateTotalScore()

int _calculateTotalScore() {
    if (!_canCalculateScore()) return 0;

    int total = 0;
    
    // Edad
    final edad = _calcularEdad(_pacienteSeleccionado!.fecnacimiento);
    if (edad < 45) total += 0;
    else if (edad >= 45 && edad <= 54) total += 2;
    else if (edad >= 55 && edad <= 64) total += 3;
    else total += 4; // >= 65
    
    // IMC
    if (_imc < 25) total += 0;
    else if (_imc >= 25 && _imc < 30) total += 1;
    else total += 3; // >= 30
    
    // Perímetro abdominal
    final perimetro = double.tryParse(_perimetroController.text) ?? 0;
    final genero = _pacienteSeleccionado!.genero.toLowerCase();
    if (genero == 'masculino') {
      if (perimetro < 94) total += 0;
      else if (perimetro >= 94 && perimetro <= 102) total += 3;
      else total += 4; // > 102
    } else { // femenino
      if (perimetro < 80) total += 0;
      else if (perimetro >= 80 && perimetro <= 88) total += 3;
      else total += 4; // > 88
    }
    
    // Actividad física
    total += _actividadFisica == 'no' ? 2 : 0;
    
    // Frutas y verduras
    total += _frecuenciaFrutas == 'no_diariamente' ? 1 : 0;
    
    // Medicamentos hipertensión
    total += _medicamentosHipertension == 'si' ? 2 : 0;
    
    // Azúcar alto
    total += _azucarAlto == 'si' ? 5 : 0;
    
    // Antecedentes familiares
    switch (_antecedentesFamiliares) {
      case 'no':
        total += 0;
        break;
      case 'abuelos_tios_primos':
        total += 3;
        break;
      case 'padres_hermanos_hijos':
        total += 5;
        break;
    }
    
    return total;
  }

  Map<String, dynamic> _getInterpretacion(int puntaje) {
    if (puntaje < 7) {
      return {
        'nivel': 'Bajo',
        'riesgo': '1%',
        'descripcion': 'Riesgo bajo de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFF4CAF50, // Verde
      };
    } else if (puntaje >= 7 && puntaje <= 11) {
      return {
        'nivel': 'Ligeramente elevado',
        'riesgo': '4%',
        'descripcion': 'Riesgo ligeramente elevado de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFFFFEB3B, // Amarillo
      };
    } else if (puntaje >= 12 && puntaje <= 14) {
      return {
        'nivel': 'Moderado',
        'riesgo': '17%',
        'descripcion': 'Riesgo moderado de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFFFF9800, // Naranja
      };
    } else if (puntaje >= 15 && puntaje <= 20) {
      return {
        'nivel': 'Alto',
        'riesgo': '33%',
        'descripcion': 'Riesgo alto de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFFF44336, // Rojo
      };
    } else {
      return {
        'nivel': 'Muy alto',
        'riesgo': '50%',
        'descripcion': 'Riesgo muy alto de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFF9C27B0, // Púrpura
      };
    }
  }

  int _calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getIMCCategory(double imc) {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _getIMCColor(double imc) {
    if (imc < 18.5) return Colors.blue;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.orange;
    return Colors.red;
  }

  String _getPerimetroHelperText(String genero) {
    if (genero.toLowerCase() == 'masculino') {
      return 'Hombres: <94cm (0pts), 94-102cm (3pts), >102cm (4pts)';
    } else {
      return 'Mujeres: <80cm (0pts), 80-88cm (3pts), >88cm (4pts)';
    }
  }

  Future<String?> _getAuthToken() async {
    // Implementar según tu sistema de autenticación
    // Por ejemplo, desde SharedPreferences o un provider de estado
    try {
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getLoggedInUser();
      return user?['token'];
    } catch (e) {
      debugPrint('Error obteniendo token: $e');
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _identificacionController.dispose();
    _veredaController.dispose();
    _telefonoController.dispose();
    _pesoController.dispose();
    _tallaController.dispose();
    _perimetroController.dispose();
    _conductaController.dispose();
    _promotorController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
