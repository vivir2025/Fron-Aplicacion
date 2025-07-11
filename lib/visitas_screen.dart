import 'package:flutter/material.dart';

import 'services/api_service.dart';
// ...existing code...// Ajusta la ruta según tu estructura

class VisitasScreen extends StatefulWidget {
  const VisitasScreen({super.key});

  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _nombreController = TextEditingController();
  final _identificacionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _zonaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _tallaController = TextEditingController();
  final _perimetroController = TextEditingController();
  final _frecuenciaCardiacaController = TextEditingController();
  final _frecuenciaRespiratoriaController = TextEditingController();
  final _tensionArterialController = TextEditingController();
  final _glucometriaController = TextEditingController();
  final _temperaturaController = TextEditingController();

  final _motivoController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _factoresController = TextEditingController();
  final _conductasController = TextEditingController();
  final _novedadesController = TextEditingController();
  final _firmaController = TextEditingController();

  String _hta = 'NO';
  String _dm = 'NO';
  String _familiar = 'NO';
  String _abandonoSocial = 'NO';
  String _riesgoFotografico = '';
  DateTime _fechaVisita = DateTime.now();
  DateTime? _proximoControl;
  double _imc = 0.0;

  @override
  void dispose() {
    _nombreController.dispose();
    _identificacionController.dispose();
    _telefonoController.dispose();
    _zonaController.dispose();
    _pesoController.dispose();
    _tallaController.dispose();
    _perimetroController.dispose();
    _frecuenciaCardiacaController.dispose();
    _frecuenciaRespiratoriaController.dispose();
    _tensionArterialController.dispose();
    _glucometriaController.dispose();
    _temperaturaController.dispose();
    _motivoController.dispose();
    _medicamentosController.dispose();
    _factoresController.dispose();
    _conductasController.dispose();
    _novedadesController.dispose();
    _firmaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calcularIMC() {
    if (_pesoController.text.isNotEmpty && _tallaController.text.isNotEmpty) {
      double peso = double.tryParse(_pesoController.text) ?? 0;
      double talla = double.tryParse(_tallaController.text) ?? 0;
      if (peso > 0 && talla > 0) {
        setState(() {
          _imc = peso / (talla * talla);
        });
      }
    }
  }

  void _guardarVisita() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> visitaData = {
        "nombre_apellido": _nombreController.text, // <-- AGREGA ESTA LÍNEA
        "nombre": _nombreController.text,
        "identificacion": _identificacionController.text,
        "telefono": _telefonoController.text,
        "zona": _zonaController.text,
        "fecha": _fechaVisita.toIso8601String(),
        "hta": _hta,
        "dm": _dm,
        "peso": _pesoController.text,
        "talla": _tallaController.text,
        "imc": _imc.toStringAsFixed(1),
        "perimetro_abdominal": _perimetroController.text, // <-- AGREGAR ESTA LÍNEA
        "frecuencia_cardiaca": _frecuenciaCardiacaController.text,
        "frecuencia_respiratoria": _frecuenciaRespiratoriaController.text,
        "tension_arterial": _tensionArterialController.text,
        "glucometria": _glucometriaController.text,
        "temperatura": _temperaturaController.text,
        "familiar_responsable": _familiar,
        "riesgo_fotografico": _riesgoFotografico,
        "abandono_social": _abandonoSocial,
        "motivo": _motivoController.text,
        "medicamentos": _medicamentosController.text,
        "factores": _factoresController.text,
        "conductas": _conductasController.text,
        "novedades": _novedadesController.text,
        "proximo_control": _proximoControl?.toIso8601String(),
        "firma": _firmaController.text,
      };

      try {
        final response = await ApiService.guardarVisita(visitaData);
        Navigator.of(context).pop();

        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visita guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _limpiarFormulario();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar la visita'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _identificacionController.clear();
    _telefonoController.clear();
    _zonaController.clear();
    _pesoController.clear();
    _tallaController.clear();
    _perimetroController.clear();
    _frecuenciaCardiacaController.clear();
    _frecuenciaRespiratoriaController.clear();
    _tensionArterialController.clear();
    _glucometriaController.clear();
    _temperaturaController.clear();
    _motivoController.clear();
    _medicamentosController.clear();
    _factoresController.clear();
    _conductasController.clear();
    _novedadesController.clear();
    _firmaController.clear();

    setState(() {
      _hta = 'NO';
      _dm = 'NO';
      _familiar = 'NO';
      _abandonoSocial = 'NO';
      _riesgoFotografico = '';
      _fechaVisita = DateTime.now();
      _proximoControl = null;
      _imc = 0.0;
    });
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    String? suffix,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es requerido';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es requerido';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateChanged,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            onDateChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            date != null ? "${date.day}/${date.month}/${date.year}" : "Seleccionar fecha",
            style: TextStyle(
              fontSize: 16,
              color: date != null ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Domiciliarias'),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Datos Personales
                _buildSectionTitle('Datos Personales'),
                _buildTextField(
                  label: 'Nombre y Apellido',
                  controller: _nombreController,
                  required: true,
                ),
                _buildTextField(
                  label: 'Identificación',
                  controller: _identificacionController,
                  keyboardType: TextInputType.number,
                  required: true,
                ),
                _buildTextField(
                  label: 'Teléfono',
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  label: 'Zona',
                  controller: _zonaController,
                ),
                _buildDateField(
                  label: 'Fecha de Visita',
                  date: _fechaVisita,
                  onDateChanged: (date) {
                    setState(() {
                      _fechaVisita = date!;
                    });
                  },
                  required: true,
                ),

                // Antecedentes Médicos
                _buildSectionTitle('Antecedentes Médicos'),
                _buildDropdown(
                  label: 'Hipertensión Arterial (HTA)',
                  value: _hta,
                  items: ['SI', 'NO'],
                  onChanged: (value) {
                    setState(() {
                      _hta = value ?? 'NO';
                    });
                  },
                  required: true,
                ),
                _buildDropdown(
                  label: 'Diabetes Mellitus (DM)',
                  value: _dm,
                  items: ['SI', 'NO'],
                  onChanged: (value) {
                    setState(() {
                      _dm = value ?? 'NO';
                    });
                  },
                  required: true,
                ),

                // Datos Antropométricos
                _buildSectionTitle('Datos Antropométricos'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Peso',
                        controller: _pesoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffix: 'kg',
                        onChanged: (value) => _calcularIMC(),
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Talla',
                        controller: _tallaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffix: 'm',
                        onChanged: (value) => _calcularIMC(),
                        required: true,
                      ),
                    ),
                  ],
                ),
                if (_imc > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'IMC: ${_imc.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _buildTextField(
                  label: 'Perímetro Abdominal',
                  controller: _perimetroController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'cm',
                  required: true,
                ),

                // Signos Vitales
                _buildSectionTitle('Signos Vitales'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Frecuencia Cardíaca',
                        controller: _frecuenciaCardiacaController,
                        keyboardType: TextInputType.number,
                        suffix: 'lpm',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Frecuencia Respiratoria',
                        controller: _frecuenciaRespiratoriaController,
                        keyboardType: TextInputType.number,
                        suffix: 'rpm',
                        required: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Tensión Arterial',
                        controller: _tensionArterialController,
                        suffix: 'mmHg',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Glucometría',
                        controller: _glucometriaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffix: 'mg/dL',
                        required: true,
                      ),
                    ),
                  ],
                ),
                _buildTextField(
                  label: 'Temperatura',
                  controller: _temperaturaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: '°C',
                  required: true,
                ),

                // Información Adicional
                _buildSectionTitle('Información Adicional'),
                _buildDropdown(
                  label: 'Tiene Familiar Responsable',
                  value: _familiar,
                  items: ['SI', 'NO'],
                  onChanged: (value) {
                    setState(() {
                      _familiar = value ?? 'NO';
                    });
                  },
                  required: true,
                ),
                _buildTextField(
                  label: 'Riesgo Fotográfico',
                  controller: TextEditingController(text: _riesgoFotografico),
                  onChanged: (value) {
                    _riesgoFotografico = value;
                  },
                ),
                _buildDropdown(
                  label: 'Abandono Social',
                  value: _abandonoSocial,
                  items: ['SI', 'NO'],
                  onChanged: (value) {
                    setState(() {
                      _abandonoSocial = value ?? 'NO';
                    });
                  },
                  required: true,
                ),

                // Observaciones
                _buildSectionTitle('Observaciones'),
                _buildTextField(
                  label: 'Motivo de la Visita',
                  controller: _motivoController,
                  maxLines: 3,
                ),
                _buildTextField(
                  label: 'Medicamentos',
                  controller: _medicamentosController,
                  maxLines: 3,
                ),
                _buildTextField(
                  label: 'Factores de Riesgo',
                  controller: _factoresController,
                  maxLines: 3,
                ),
                _buildTextField(
                  label: 'Conductas a Seguir',
                  controller: _conductasController,
                  maxLines: 3,
                ),
                _buildTextField(
                  label: 'Novedades',
                  controller: _novedadesController,
                  maxLines: 3,
                ),
                _buildDateField(
                  label: 'Próximo Control',
                  date: _proximoControl,
                  onDateChanged: (date) {
                    setState(() {
                      _proximoControl = date;
                    });
                  },
                ),
                _buildTextField(
                  label: 'Firma del Profesional',
                  controller: _firmaController,
                ),

                // Botones
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _limpiarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarVisita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Guardar Visita'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}