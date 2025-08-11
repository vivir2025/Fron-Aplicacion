// screens/tamizaje_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tamizaje_model.dart';
import '../models/paciente_model.dart';
import '../services/tamizaje_service.dart';
import '../services/sincronizacion_service.dart';
import '../database/database_helper.dart';

class TamizajeScreen extends StatefulWidget {
  const TamizajeScreen({Key? key}) : super(key: key);

  @override
  State<TamizajeScreen> createState() => _TamizajeScreenState();
}

class _TamizajeScreenState extends State<TamizajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificacionController = TextEditingController();
  final _veredaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _sistolicaController = TextEditingController();
  final _diastolicaController = TextEditingController();
  final _conductaController = TextEditingController();

  Paciente? _pacienteSeleccionado;
  String _brazoToma = 'derecho';
  String _posicionPersona = 'sentado';
  String _reposoCincoMinutos = 'si';
  DateTime _fechaToma = DateTime.now();
  bool _isLoading = false;
  bool _buscandoPaciente = false;

  @override
  void dispose() {
    _identificacionController.dispose();
    _veredaController.dispose();
    _telefonoController.dispose();
    _sistolicaController.dispose();
    _diastolicaController.dispose();
    _conductaController.dispose();
    super.dispose();
  }

  Future<void> _buscarPaciente() async {
    if (_identificacionController.text.trim().isEmpty) {
      _mostrarError('Ingrese el número de identificación');
      return;
    }

    setState(() {
      _buscandoPaciente = true;
      _pacienteSeleccionado = null;
    });

    try {
      final paciente = await TamizajeService.buscarPacientePorIdentificacion(
        _identificacionController.text.trim()
      );

      if (paciente != null) {
        setState(() {
          _pacienteSeleccionado = paciente;
        });
        _mostrarExito('Paciente encontrado');
      } else {
        _mostrarError('Paciente no encontrado con esa identificación');
      }
    } catch (e) {
      _mostrarError('Error al buscar paciente: $e');
    } finally {
      setState(() {
        _buscandoPaciente = false;
      });
    }
  }

  Future<void> _guardarTamizaje() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pacienteSeleccionado == null) {
      _mostrarError('Debe seleccionar un paciente');
      return;
    }

    final sistolica = int.tryParse(_sistolicaController.text) ?? 0;
    final diastolica = int.tryParse(_diastolicaController.text) ?? 0;

    // Validar datos
    final errores = TamizajeService.validarDatosTamizaje(
      veredaResidencia: _veredaController.text.trim(),
      telefono: _telefonoController.text.trim(),
      paSistolica: sistolica,
      paDiastolica: diastolica,
    );

    if (errores.isNotEmpty) {
      _mostrarError(errores.values.first!);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener usuario actual
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      if (usuario == null) {
        _mostrarError('No hay usuario autenticado');
        return;
      }

      final resultado = await TamizajeService.crearTamizaje(
        pacienteId: _pacienteSeleccionado!.id,
        usuarioId: usuario['id'],
        veredaResidencia: _veredaController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        brazoToma: _brazoToma,
        posicionPersona: _posicionPersona,
        reposoCincoMinutos: _reposoCincoMinutos,
        fechaPrimeraToma: _fechaToma,
        paSistolica: sistolica,
        paDiastolica: diastolica,
        conducta: _conductaController.text.trim().isEmpty ? null : _conductaController.text.trim(),
        token: usuario['token'],
      );

      if (resultado['success']) {
        final synced = resultado['synced'] ?? false;
        
        _mostrarExito(
          synced 
            ? 'Tamizaje guardado y sincronizado exitosamente'
            : 'Tamizaje guardado. Se sincronizará cuando haya conexión.'
        );
        
        // ← CAMBIO PRINCIPAL: Regresar inmediatamente con resultado exitoso
        // Esperar un momento para que se vea el mensaje de éxito
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Regresar a la pantalla anterior con resultado exitoso
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _mostrarError(resultado['message']);
      }
    } catch (e) {
      _mostrarError('Error al guardar tamizaje: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _limpiarFormulario() {
    _identificacionController.clear();
    _veredaController.clear();
    _telefonoController.clear();
    _sistolicaController.clear();
    _diastolicaController.clear();
    _conductaController.clear();
    
    setState(() {
      _pacienteSeleccionado = null;
      _brazoToma = 'derecho';
      _posicionPersona = 'sentado';
      _reposoCincoMinutos = 'si';
      _fechaToma = DateTime.now();
    });
  }

  // ← FUNCIÓN ELIMINADA: _mostrarResultadoTamizaje ya no se usa

  Color _getColorClasificacion(String clasificacion) {
    switch (clasificacion) {
      case 'NORMAL':
        return Colors.green;
      case 'ELEVADA':
        return Colors.orange;
      case 'HIPERTENSIÓN ESTADIO 1':
        return Colors.red[300]!;
      case 'HIPERTENSIÓN ESTADIO 2':
        return Colors.red;
      default:
        return Colors.red[900]!;
    }
  }

  String _getRecomendacion(String clasificacion) {
    switch (clasificacion) {
      case 'NORMAL':
        return 'Presión arterial normal. Mantener hábitos saludables.';
      case 'ELEVADA':
        return 'Presión elevada. Modificar estilo de vida.';
      case 'HIPERTENSIÓN ESTADIO 1':
        return 'Hipertensión Estadio 1. Consultar con médico.';
      case 'HIPERTENSIÓN ESTADIO 2':
        return 'Hipertensión Estadio 2. Atención médica urgente.';
      default:
        return 'Crisis hipertensiva. Atención médica inmediata.';
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamizaje de Presión Arterial'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _sincronizar,
            tooltip: 'Sincronizar',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.pushNamed(context, '/tamizajes_lista'),
            tooltip: 'Ver tamizajes',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de búsqueda de paciente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscar Paciente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _identificacionController,
                              decoration: const InputDecoration(
                                labelText: 'Número de Identificación',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el número de identificación';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _buscandoPaciente ? null : _buscarPaciente,
                            child: _buscandoPaciente
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información del paciente
              if (_pacienteSeleccionado != null) ...[
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Paciente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Nombre y Apellido:', _pacienteSeleccionado!.nombreCompleto),
                        _buildInfoRow('Identificación:', _pacienteSeleccionado!.identificacion),
                        _buildInfoRow('Fecha de Nacimiento:', _formatearFecha(_pacienteSeleccionado!.fecnacimiento)),
                        _buildInfoRow('Edad:', '${_calcularEdad(_pacienteSeleccionado!.fecnacimiento)} años'),
                        _buildInfoRow('Sexo:', _pacienteSeleccionado!.genero),
                        _buildInfoRow('Municipio de Residencia:', _pacienteSeleccionado!.nombreSede ?? 'No disponible'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Formulario de tamizaje
              if (_pacienteSeleccionado != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos del Tamizaje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vereda de residencia
                        TextFormField(
                          controller: _veredaController,
                          decoration: const InputDecoration(
                            labelText: 'Vereda de Residencia *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La vereda de residencia es requerida';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 16),

                        // Brazo de toma
                        const Text('Brazo de Toma *'),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'izquierdo',
                              groupValue: _brazoToma,
                              onChanged: (value) {
                                setState(() {
                                  _brazoToma = value!;
                                });
                              },
                            ),
                            const Text('Izquierdo'),
                            Radio<String>(
                              value: 'derecho',
                              groupValue: _brazoToma,
                              onChanged: (value) {
                                setState(() {
                                  _brazoToma = value!;
                                });
                              },
                            ),
                            const Text('Derecho'),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Posición de la persona
                        const Text('Posición de la Persona *'),
                        Wrap(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'de_pie',
                                  groupValue: _posicionPersona,
                                  onChanged: (value) {
                                    setState(() {
                                      _posicionPersona = value!;
                                    });
                                  },
                                ),
                                const Text('De pie'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'acostado',
                                  groupValue: _posicionPersona,
                                  onChanged: (value) {
                                    setState(() {
                                      _posicionPersona = value!;
                                    });
                                  },
                                ),
                                const Text('Acostado'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'sentado',
                                  groupValue: _posicionPersona,
                                  onChanged: (value) {
                                    setState(() {
                                      _posicionPersona = value!;
                                    });
                                  },
                                ),
                                const Text('Sentado'),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Reposo de cinco minutos
                        const Text('¿Reposo de 5 minutos? *'),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'si',
                              groupValue: _reposoCincoMinutos,
                              onChanged: (value) {
                                setState(() {
                                  _reposoCincoMinutos = value!;
                                });
                              },
                            ),
                            const Text('Sí'),
                            Radio<String>(
                              value: 'no',
                              groupValue: _reposoCincoMinutos,
                              onChanged: (value) {
                                setState(() {
                                  _reposoCincoMinutos = value!;
                                });
                              },
                            ),
                            const Text('No'),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Fecha de primera toma
                        InkWell(
                          onTap: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaToma,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              setState(() {
                                _fechaToma = fecha;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                Text('Fecha de Toma: ${_formatearFecha(_fechaToma)}'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Presión arterial
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sistolicaController,
                                decoration: const InputDecoration(
                                  labelText: 'Presión Sistólica *',
                                  border: OutlineInputBorder(),
                                  suffixText: 'mmHg',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  final sistolica = int.tryParse(value);
                                  if (sistolica == null || sistolica < 50 || sistolica > 300) {
                                    return 'Entre 50-300';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _diastolicaController,
                                decoration: const InputDecoration(
                                  labelText: 'Presión Diastólica *',
                                  border: OutlineInputBorder(),
                                  suffixText: 'mmHg',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  final diastolica = int.tryParse(value);
                                  if (diastolica == null || diastolica < 30 || diastolica > 200) {
                                    return 'Entre 30-200';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Conducta
                        TextFormField(
                          controller: _conductaController,
                          decoration: const InputDecoration(
                            labelText: 'Conducta/Observaciones',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),

                        // Botón guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarTamizaje,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Guardando...'),
                                    ],
                                  )
                                : const Text(
                                    'Guardar Tamizaje',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
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
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
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

  Future<void> _sincronizar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      if (usuario == null || usuario['token'] == null) {
        _mostrarError('No hay usuario autenticado');
        return;
      }

      final resultado = await SincronizacionService.sincronizarTamizajesPendientes(
        usuario['token']
      );

      final exitosas = resultado['exitosas'] ?? 0;
      final fallidas = resultado['fallidas'] ?? 0;

      if (exitosas > 0) {
        _mostrarExito('$exitosas tamizajes sincronizados exitosamente');
      } else if (fallidas > 0) {
        _mostrarError('Error al sincronizar tamizajes');
      } else {
        _mostrarExito('No hay tamizajes pendientes de sincronización');
      }
    } catch (e) {
      _mostrarError('Error en la sincronización: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
