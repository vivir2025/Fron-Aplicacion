import 'package:flutter/material.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../models/paciente_model.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class PacientesScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const PacientesScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  _PacientesScreenState createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Paciente> _filteredPacientes = [];
  List<Paciente> _uniquePacientes = [];
  bool _isSearching = false;
  
  // Paginación
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  int _totalPages = 1;

  // Colores del tema
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadPacientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPacientes() async {
    final provider = Provider.of<PacienteProvider>(context, listen: false);
    
    // Primero asegurar que las sedes estén cargadas
    if (provider.sedes.isEmpty) {
      await provider.loadSedes();
    }
    
    // Luego cargar pacientes
    await provider.loadPacientes();
    
    // Eliminar duplicados basándose en el ID
    _uniquePacientes = _removeDuplicates(provider.pacientes);
    
    // Actualizar la lista filtrada y paginación
    _updateFilteredList();
  }

  List<Paciente> _removeDuplicates(List<Paciente> pacientes) {
    final Map<String, Paciente> uniqueMap = {};
    for (final paciente in pacientes) {
      uniqueMap[paciente.identificacion] = paciente;
    }
    return uniqueMap.values.toList();
  }

  void _updateFilteredList() {
    if (_searchController.text.isEmpty) {
      _filteredPacientes = _uniquePacientes;
      _isSearching = false;
    } else {
      _filteredPacientes = _uniquePacientes.where((paciente) {
        return paciente.identificacion.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
      _isSearching = true;
    }
    
    // Calcular total de páginas
    _totalPages = (_filteredPacientes.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    
    // Asegurar que la página actual no sea mayor al total
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
    
    setState(() {});
  }

  void _searchPacientes(String query) {
    _currentPage = 1; // Resetear a página 1 cuando se busca
    _updateFilteredList();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentPage = 1;
    _updateFilteredList();
  }

  List<Paciente> _getPaginatedPacientes() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredPacientes.length) return [];
    
    return _filteredPacientes.sublist(
      startIndex,
      endIndex > _filteredPacientes.length ? _filteredPacientes.length : endIndex,
    );
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón Anterior
          TextButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            child: const Text('Anterior'),
          ),
          
          const SizedBox(width: 16),
          
          // Números de página
          ...List.generate(_totalPages, (index) {
            final page = index + 1;
            final isCurrentPage = page == _currentPage;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => _goToPage(page),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentPage ? primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrentPage ? primaryGreen : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    page.toString(),
                    style: TextStyle(
                      color: isCurrentPage ? Colors.white : Colors.black,
                      fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(width: 16),
          
          // Botón Siguiente
          TextButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadPacientes,
          ),
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLogout();
                      },
                      child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPacientes,
              decoration: InputDecoration(
                hintText: 'Buscar por número de identificación...',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Lista de pacientes
          Expanded(
            child: Consumer<PacienteProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.pacientes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pacientesToShow = _getPaginatedPacientes();

                if (_filteredPacientes.isEmpty && _isSearching) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.search_normal, size: 50, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron pacientes con la identificación "${_searchController.text}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (_uniquePacientes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.people, size: 50, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No hay pacientes registrados'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showAddPacienteDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Agregar Paciente'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Info de paginación
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Página $_currentPage de $_totalPages',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_filteredPacientes.length} pacientes total',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de pacientes
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPacientes,
                        child: ListView.builder(
                          itemCount: pacientesToShow.length,
                          itemBuilder: (context, index) {
                            final paciente = pacientesToShow[index];
                            final isOffline = paciente.id.startsWith('offline_');
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [Colors.white, lightGreen.withOpacity(0.05)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: isOffline ? Colors.orange : primaryGreen,
                                    child: Text(
                                      paciente.nombre[0] + paciente.apellido[0],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    paciente.nombreCompleto,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${paciente.identificacion}',
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(paciente.infoBasica),
                                      if (paciente.nombreSede != null) 
                                        Text(
                                          'Sede: ${paciente.nombreSede}',
                                          style: const TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Iconsax.edit, size: 20, color: primaryGreen),
                                        onPressed: () => _showEditPacienteDialog(context, paciente),
                                      ),
                                      IconButton(
                                        icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                                        onPressed: () => _deletePaciente(context, paciente.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Paginación
                    _buildPagination(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Iconsax.add),
        onPressed: () => _showAddPacienteDialog(context),
      ),
    );
  }

  Future<void> _showAddPacienteDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final identificacionController = TextEditingController();
    DateTime? fechaNacimiento;
    String genero = 'Masculino';
    String? sedeSeleccionada;
    bool isSaving = false;

    final provider = Provider.of<PacienteProvider>(context, listen: false);
    
    // Asegurar que las sedes estén cargadas
    if (provider.sedes.isEmpty) {
      await provider.loadSedes();
    }
    
    final sedes = provider.sedes;

    // Si no hay sedes, mostrar mensaje y salir
    if (sedes.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('No se pudieron cargar las sedes. Verifique su conexión.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Si hay un usuario logueado, seleccionar su sede por defecto
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final db = DatabaseHelper.instance;
    final currentUser = await db.getLoggedInUser();
    if (currentUser != null && currentUser['sede_id'] != null && sedeSeleccionada == null) {
      sedeSeleccionada = currentUser['sede_id'];
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Agregar Paciente', style: TextStyle(color: primaryGreen)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: apellidoController,
                        decoration: InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: identificacionController,
                        decoration: InputDecoration(
                          labelText: 'Identificación',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Requerido';
                          // Validar que no existe otro paciente con la misma identificación
                          final existingPaciente = provider.pacientes.firstWhere(
                            (p) => p.identificacion == value,
                            orElse: () => Paciente(
                              id: '',
                              identificacion: '',
                              fecnacimiento: DateTime.now(),
                              nombre: '',
                              apellido: '',
                              genero: '',
                              idsede: '',
                            ),
                          );
                          if (existingPaciente.identificacion == value) {
                            return 'Ya existe un paciente con esta identificación';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: genero,
                        items: ['Masculino', 'Femenino', 'Otro']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => genero = value!),
                        decoration: InputDecoration(
                          labelText: 'Género',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: sedeSeleccionada,
                        items: sedes.map<DropdownMenuItem<String>>((sede) {
                          return DropdownMenuItem<String>(
                            value: sede['id'],
                            child: Text(sede['nombresede'] ?? 'Sede sin nombre'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => sedeSeleccionada = value),
                        decoration: InputDecoration(
                          labelText: 'Sede',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value == null ? 'Seleccione una sede' : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Fecha de Nacimiento'),
                        subtitle: Text(
                          fechaNacimiento == null
                              ? 'Seleccionar fecha'
                              : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                        ),
                        trailing: Icon(Iconsax.calendar, color: primaryGreen),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() => fechaNacimiento = selectedDate);
                          }
                        },
                      ),
                      if (isSaving) 
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate() && 
                              fechaNacimiento != null && 
                              sedeSeleccionada != null) {
                            setState(() => isSaving = true);

                            final nuevoPaciente = Paciente(
                              id: '', // El backend generará el ID
                              identificacion: identificacionController.text.trim(),
                              fecnacimiento: fechaNacimiento!,
                              nombre: nombreController.text.trim(),
                              apellido: apellidoController.text.trim(),
                              genero: genero,
                              idsede: sedeSeleccionada!,
                            );

                            try {
                              await provider.addPaciente(nuevoPaciente);
                              if (mounted) {
                                Navigator.pop(context);
                                _loadPacientes(); // Recargar la lista
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Paciente agregado exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => isSaving = false);
                            }
                          } else {
                            if (fechaNacimiento == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor seleccione la fecha de nacimiento'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPacienteDialog(BuildContext context, Paciente paciente) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: paciente.nombre);
    final apellidoController = TextEditingController(text: paciente.apellido);
    final identificacionController = TextEditingController(text: paciente.identificacion);
    DateTime fechaNacimiento = paciente.fecnacimiento;
    String genero = paciente.genero;
    String? sedeSeleccionada = paciente.idsede;
    bool isSaving = false;

    final provider = Provider.of<PacienteProvider>(context, listen: false);
    
    // Asegurar que las sedes estén cargadas
    if (provider.sedes.isEmpty) {
      await provider.loadSedes();
    }
    
    final sedes = provider.sedes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar Paciente', style: TextStyle(color: primaryGreen)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: apellidoController,
                        decoration: InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: identificacionController,
                        decoration: InputDecoration(
                          labelText: 'Identificación',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Requerido';
                          // Validar que no existe otro paciente con la misma identificación (excepto el actual)
                          final existingPaciente = provider.pacientes.firstWhere(
                            (p) => p.identificacion == value && p.id != paciente.id,
                            orElse: () => Paciente(
                              id: '',
                              identificacion: '',
                              fecnacimiento: DateTime.now(),
                              nombre: '',
                              apellido: '',
                              genero: '',
                              idsede: '',
                            ),
                          );
                          if (existingPaciente.identificacion == value) {
                            return 'Ya existe otro paciente con esta identificación';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: genero,
                        items: ['Masculino', 'Femenino', 'Otro']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => genero = value!),
                        decoration: InputDecoration(
                          labelText: 'Género',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: sedeSeleccionada,
                        items: sedes.map<DropdownMenuItem<String>>((sede) {
                          return DropdownMenuItem<String>(
                            value: sede['id'],
                            child: Text(sede['nombresede'] ?? 'Sede sin nombre'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => sedeSeleccionada = value),
                        decoration: InputDecoration(
                          labelText: 'Sede',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Fecha de Nacimiento'),
                        subtitle: Text(
                          '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}',
                        ),
                        trailing: Icon(Iconsax.calendar, color: primaryGreen),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: fechaNacimiento,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() => fechaNacimiento = selectedDate);
                          }
                        },
                      ),
                      if (isSaving) 
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate() && sedeSeleccionada != null) {
                            setState(() => isSaving = true);

                            final pacienteActualizado = Paciente(
                              id: paciente.id,
                              identificacion: identificacionController.text.trim(),
                              fecnacimiento: fechaNacimiento,
                              nombre: nombreController.text.trim(),
                              apellido: apellidoController.text.trim(),
                              genero: genero,
                              longitud: paciente.longitud,
                              latitud: paciente.latitud,
                              idsede: sedeSeleccionada!,
                              syncStatus: paciente.syncStatus,
                            );

                            try {
                              await provider.updatePaciente(pacienteActualizado);
                              if (mounted) {
                                Navigator.pop(context);
                                _loadPacientes(); // Recargar la lista
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Paciente actualizado exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al actualizar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => isSaving = false);
                            }
                          }
                        },
                  child: const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePaciente(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de que deseas eliminar este paciente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<PacienteProvider>(context, listen: false)
            .deletePaciente(id);
        if (mounted) {
          _loadPacientes(); // Recargar la lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}