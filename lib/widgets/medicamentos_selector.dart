// widgets/medicamentos_selector.dart
import 'package:flutter/material.dart';
import '../models/medicamento.dart';
import '../models/medicamento_con_indicaciones.dart';
import '../database/database_helper.dart';
import '../services/medicamento_service.dart';

class MedicamentosSelector extends StatefulWidget {
  final List<MedicamentoConIndicaciones> selectedMedicamentos;
  final Function(List<MedicamentoConIndicaciones>) onChanged;
  final String? token;

  const MedicamentosSelector({
    Key? key,
    required this.selectedMedicamentos,
    required this.onChanged,
    this.token,
  }) : super(key: key);

  @override
  State<MedicamentosSelector> createState() => _MedicamentosSelectorState();
}

class _MedicamentosSelectorState extends State<MedicamentosSelector> {
  List<Medicamento> _allMedicamentos = [];
  List<MedicamentoConIndicaciones> _selectedMedicamentos = [];
  List<Medicamento> _filteredMedicamentos = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedMedicamentos = List.from(widget.selectedMedicamentos);
    _loadMedicamentos();
    debugPrint('🔍 Medicamentos iniciales en MedicamentosSelector: ${_selectedMedicamentos.length}');
  }

  @override
  void didUpdateWidget(MedicamentosSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.selectedMedicamentos != widget.selectedMedicamentos) {
      setState(() {
        _selectedMedicamentos = List.from(widget.selectedMedicamentos);
      });
      debugPrint('🔄 Medicamentos actualizados desde el padre: ${_selectedMedicamentos.length}');
      
      for (var med in _selectedMedicamentos) {
        debugPrint('💊 Medicamento desde padre: ${med.medicamento.nombmedicamento} - Selected: ${med.isSelected}');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicamentos() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      _allMedicamentos = await dbHelper.getAllMedicamentos();
      _filteredMedicamentos = List.from(_allMedicamentos);

      if (_allMedicamentos.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('📋 ${_allMedicamentos.length} medicamentos cargados desde cache local');

        if (widget.token != null) {
          _updateMedicamentosFromServer();
        }
      } else {
        if (widget.token != null) {
          await MedicamentoService.ensureMedicamentosLoaded(widget.token);
          _allMedicamentos = await dbHelper.getAllMedicamentos();
          _filteredMedicamentos = List.from(_allMedicamentos);
        }

        if (_allMedicamentos.isEmpty) {
          setState(() {
            _hasError = true;
            _errorMessage = widget.token != null 
                ? 'No se pudieron cargar los medicamentos. Verifique su conexión a internet.'
                : 'No hay medicamentos disponibles. Se requiere conexión a internet para la primera carga.';
          });
        }

        debugPrint('📋 ${_allMedicamentos.length} medicamentos cargados desde servidor');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error al cargar medicamentos: $e';
      });
      debugPrint('❌ Error cargando medicamentos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateMedicamentosFromServer() async {
    try {
      debugPrint('🔄 Actualizando medicamentos desde servidor en segundo plano...');
      await MedicamentoService.ensureMedicamentosLoaded(widget.token);
      
      final dbHelper = DatabaseHelper.instance;
      final updatedMedicamentos = await dbHelper.getAllMedicamentos();
      
      if (updatedMedicamentos.length != _allMedicamentos.length && mounted) {
        setState(() {
          _allMedicamentos = updatedMedicamentos;
          _filteredMedicamentos = _filterMedicamentos(_searchController.text);
        });
        debugPrint('✅ Medicamentos actualizados: ${updatedMedicamentos.length}');
      }
    } catch (e) {
      debugPrint('⚠️ Error actualizando medicamentos en segundo plano: $e');
    }
  }

  List<Medicamento> _filterMedicamentos(String query) {
    if (query.isEmpty) {
      return List.from(_allMedicamentos);
    }
    
    return _allMedicamentos.where((medicamento) {
      return medicamento.nombmedicamento.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void _showMedicamentosDialog() {
    if (_allMedicamentos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay medicamentos disponibles. Intente recargar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Map<String, MedicamentoConIndicaciones> selectedMap = {};
    for (final selected in _selectedMedicamentos) {
      selectedMap[selected.medicamento.id] = selected;
    }

    List<MedicamentoConIndicaciones> tempSelected = _allMedicamentos.map((medicamento) {
      return selectedMap[medicamento.id] ?? MedicamentoConIndicaciones(
        medicamento: medicamento,
        indicaciones: null,
        isSelected: false,
      );
    }).toList();

    _searchController.clear();
    List<MedicamentoConIndicaciones> filteredTempSelected = List.from(tempSelected);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 🆕 Obtener dimensiones de la pantalla para responsividad
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 600;
          final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 600.0;
          final dialogHeight = isSmallScreen ? screenSize.height * 0.8 : 500.0;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.medication, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Seleccionar Medicamentos',
                    style: TextStyle(fontSize: 16), // 🆕 Tamaño fijo para el título
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use la búsqueda para encontrar medicamentos rápidamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Column(
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar medicamento...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setDialogState(() {
                                  filteredTempSelected = List.from(tempSelected);
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isEmpty) {
                          filteredTempSelected = List.from(tempSelected);
                        } else {
                          filteredTempSelected = tempSelected.where((m) {
                            return m.medicamento.nombmedicamento.toLowerCase().contains(value.toLowerCase());
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Contador de seleccionados - 🆕 Responsivo
                  Container(
                    width: double.infinity, // 🆕 Asegurar que ocupe todo el ancho disponible
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded( // 🆕 Expandir el texto para evitar overflow
                          child: Text(
                            '${tempSelected.where((m) => m.isSelected).length} de ${filteredTempSelected.length} medicamentos seleccionados',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 11 : 12, // 🆕 Tamaño adaptativo
                            ),
                            overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Lista optimizada
                  Expanded(
                    child: filteredTempSelected.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No se encontraron medicamentos',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredTempSelected.length,
                            itemBuilder: (context, index) {
                              final medicamentoConIndicaciones = filteredTempSelected[index];
                              final medicamento = medicamentoConIndicaciones.medicamento;
                              final originalIndex = tempSelected.indexWhere((m) => m.medicamento.id == medicamento.id);
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                elevation: medicamentoConIndicaciones.isSelected ? 2 : 1,
                                child: ListTile(
                                  dense: true,
                                  leading: Checkbox(
                                    value: medicamentoConIndicaciones.isSelected,
                                    onChanged: (bool? value) {
                                      setDialogState(() {
                                        tempSelected[originalIndex] = medicamentoConIndicaciones.copyWith(
                                          isSelected: value ?? false,
                                        );
                                        filteredTempSelected[index] = tempSelected[originalIndex];
                                      });
                                    },
                                  ),
                                  title: Text(
                                    medicamento.nombmedicamento,
                                    style: TextStyle(
                                      fontWeight: medicamentoConIndicaciones.isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: medicamentoConIndicaciones.isSelected 
                                          ? Colors.green.shade700 
                                          : null,
                                      fontSize: isSmallScreen ? 13 : 14, // 🆕 Tamaño adaptativo
                                    ),
                                    overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                  ),
                                  subtitle: medicamentoConIndicaciones.isSelected && 
                                           medicamentoConIndicaciones.indicaciones != null &&
                                           medicamentoConIndicaciones.indicaciones!.isNotEmpty
                                      ? Text(
                                          'Indicaciones: ${medicamentoConIndicaciones.indicaciones}',
                                          style: TextStyle(fontSize: isSmallScreen ? 10 : 11), // 🆕 Tamaño adaptativo
                                          overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                        )
                                      : null,
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelected[originalIndex] = medicamentoConIndicaciones.copyWith(
                                        isSelected: !medicamentoConIndicaciones.isSelected,
                                      );
                                      filteredTempSelected[index] = tempSelected[originalIndex];
                                    });
                                  },
                                  trailing: medicamentoConIndicaciones.isSelected
                                      ? IconButton(
                                          icon: const Icon(Icons.edit, size: 16),
                                          onPressed: () {
                                            _showIndicacionesDialog(
                                              context,
                                              medicamentoConIndicaciones,
                                              (newIndicaciones) {
                                                setDialogState(() {
                                                  tempSelected[originalIndex] = medicamentoConIndicaciones.copyWith(
                                                    indicaciones: newIndicaciones,
                                                  );
                                                  filteredTempSelected[index] = tempSelected[originalIndex];
                                                });
                                              },
                                            );
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              // 🆕 Botones responsivos
              if (isSmallScreen) ...[
                // En pantallas pequeñas, botones en columna
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < tempSelected.length; i++) {
                            tempSelected[i] = tempSelected[i].copyWith(isSelected: false);
                          }
                          filteredTempSelected = tempSelected.where((m) {
                            final query = _searchController.text.toLowerCase();
                            return query.isEmpty || m.medicamento.nombmedicamento.toLowerCase().contains(query);
                          }).toList();
                        });
                      },
                      child: const Text('Limpiar Todo'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedMedicamentos = tempSelected.where((m) => m.isSelected).toList();
                              });
                              widget.onChanged(_selectedMedicamentos);
                              Navigator.of(context).pop();
                            },
                            child: Text('Guardar (${tempSelected.where((m) => m.isSelected).length})'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                // En pantallas medianas/grandes, botones en fila
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      for (int i = 0; i < tempSelected.length; i++) {
                        tempSelected[i] = tempSelected[i].copyWith(isSelected: false);
                      }
                      filteredTempSelected = tempSelected.where((m) {
                        final query = _searchController.text.toLowerCase();
                        return query.isEmpty || m.medicamento.nombmedicamento.toLowerCase().contains(query);
                      }).toList();
                    });
                  },
                  child: const Text('Limpiar Todo'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMedicamentos = tempSelected.where((m) => m.isSelected).toList();
                    });
                    widget.onChanged(_selectedMedicamentos);
                    Navigator.of(context).pop();
                  },
                  child: Text('Guardar (${tempSelected.where((m) => m.isSelected).length})'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showIndicacionesDialog(
    BuildContext context,
    MedicamentoConIndicaciones medicamento,
    Function(String?) onChanged,
  ) {
    final controller = TextEditingController(text: medicamento.indicaciones ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Indicaciones para ${medicamento.medicamento.nombmedicamento}',
          style: const TextStyle(fontSize: 16), // 🆕 Tamaño fijo
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Indicaciones',
            hintText: 'Ej: 1 tableta cada 8 horas con alimentos',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(controller.text.isEmpty ? null : controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Obtener dimensiones para responsividad
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Medicamentos',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16, // 🆕 Tamaño adaptativo
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Mostrar medicamentos seleccionados - 🆕 Completamente responsivo
        if (_selectedMedicamentos.isNotEmpty)
          Container(
            width: double.infinity, // 🆕 Ocupar todo el ancho disponible
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // 🆕 Padding adaptativo
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
                    Expanded( // 🆕 Expandir para evitar overflow
                      child: Text(
                        '${_selectedMedicamentos.length} medicamentos seleccionados:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 13 : 14, // 🆕 Tamaño adaptativo
                        ),
                        overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 🆕 Wrap responsivo con spacing adaptativo
                Wrap(
                  spacing: isSmallScreen ? 4 : 8,
                  runSpacing: isSmallScreen ? 2 : 4,
                  children: _selectedMedicamentos.map((medicamentoConIndicaciones) {
                    return ConstrainedBox( // 🆕 Limitar el ancho máximo de los chips
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.9, // 🆕 Máximo 90% del ancho de pantalla
                      ),
                      child: Chip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicamentoConIndicaciones.medicamento.nombmedicamento,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12, // 🆕 Tamaño adaptativo
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                            ),
                            if (medicamentoConIndicaciones.indicaciones != null &&
                                medicamentoConIndicaciones.indicaciones!.isNotEmpty)
                              Text(
                                medicamentoConIndicaciones.indicaciones!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10, // 🆕 Tamaño adaptativo
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis, // 🆕 Prevenir overflow
                                maxLines: 1, // 🆕 Limitar a una línea
                              ),
                          ],
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedMedicamentos.removeWhere((m) => 
                              m.medicamento.id == medicamentoConIndicaciones.medicamento.id);
                          });
                          widget.onChanged(_selectedMedicamentos);
                        },
                        deleteIcon: Icon(Icons.close, size: isSmallScreen ? 16 : 18), // 🆕 Tamaño adaptativo
                        backgroundColor: Colors.green.shade100,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Botón para seleccionar medicamentos o mensaje de error
        if (_hasError)
          Container(
            width: double.infinity, // 🆕 Ocupar todo el ancho
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // 🆕 Padding adaptativo
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded( // 🆕 Expandir para evitar overflow
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: isSmallScreen ? 12 : 14, // 🆕 Tamaño adaptativo
                    ),
                    overflow: TextOverflow.visible, // 🆕 Permitir múltiples líneas
                  ),
                ),
                IconButton(
                  onPressed: _loadMedicamentos,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reintentar',
                ),
              ],
            ),
          )
        else
          // 🆕 Botones responsivos
          isSmallScreen
              ? Column( // En pantallas pequeñas, botones en columna
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _showMedicamentosDialog,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_selectedMedicamentos.isEmpty 
                          ? 'Seleccionar Medicamentos' 
                          : 'Modificar Selección'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loadMedicamentos,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Actualizar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row( // En pantallas medianas/grandes, botones en fila
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _showMedicamentosDialog,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                        label: Text(_selectedMedicamentos.isEmpty 
                            ? 'Seleccionar Medicamentos' 
                            : 'Modificar Selección'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : _loadMedicamentos,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar lista',
                    ),
                  ],
                ),

        // Información adicional
        if (_allMedicamentos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_allMedicamentos.length} medicamentos disponibles',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12, // 🆕 Tamaño adaptativo
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }
}
