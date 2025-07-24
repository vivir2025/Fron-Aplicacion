import 'package:fnpv_app/database/database_helper.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../models/paciente_model.dart';

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

  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF4CAF50);

  static const double kTabletBreakpoint = 720.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PacienteProvider>(context, listen: false);
      if (!provider.isLoaded) {
        _refreshPacientesFromServer();
      } else {
        _loadPacientesFromProvider();
      }
    });
  }

  void _onSearchChanged() {
    _filterPacientes();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadPacientesFromProvider() {
    if (!mounted) return;

    final provider = Provider.of<PacienteProvider>(context, listen: false);
    final pacientes = _removeDuplicates(provider.pacientes);

    setState(() {
      _uniquePacientes = pacientes;
      _filterPacientes();
    });
  }

  Future<void> _refreshPacientesFromServer() async {
    if (!mounted) return;

    final provider = Provider.of<PacienteProvider>(context, listen: false);
    await provider.forceReloadAll();

    if (mounted) {
      _loadPacientesFromProvider();
    }
  }

  List<Paciente> _removeDuplicates(List<Paciente> pacientes) {
    final Map<String, Paciente> uniqueMap = {};
    for (final paciente in pacientes) {
      uniqueMap[paciente.identificacion] = paciente;
    }
    return uniqueMap.values.toList();
  }

  void _filterPacientes() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredPacientes = _uniquePacientes;
        _isSearching = false;
      } else {
        _filteredPacientes = _uniquePacientes.where((paciente) {
          final nombreCompleto = paciente.nombreCompleto.toLowerCase();
          final identificacion = paciente.identificacion.toLowerCase();
          return nombreCompleto.contains(query) || identificacion.contains(query);
        }).toList();
        _isSearching = true;
      }

      _currentPage = 1;
      _totalPages = (_filteredPacientes.length / _itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  List<Paciente> _getPaginatedPacientes() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredPacientes.length) return [];

    return _filteredPacientes.sublist(
      startIndex,
      endIndex > _filteredPacientes.length
          ? _filteredPacientes.length
          : endIndex,
    );
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Widget _buildPageItem(int page) {
    final isCurrentPage = page == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCurrentPage
                  ? primaryGreen
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            page.toString(),
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.black,
              fontWeight: isCurrentPage
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageItems = [];
    const int maxVisiblePages = 5;

    if (_totalPages <= maxVisiblePages) {
      for (int i = 1; i <= _totalPages; i++) {
        pageItems.add(_buildPageItem(i));
      }
    } else {
      int startPage = (_currentPage - 2).clamp(1, _totalPages);
      int endPage = (_currentPage + 2).clamp(1, _totalPages);

      if (_currentPage < 4) {
        endPage = 4;
      }
      if (_currentPage > _totalPages - 3) {
        startPage = _totalPages - 3;
      }

      if (startPage > 1) {
        pageItems.add(_buildPageItem(1));
        if (startPage > 2) {
          pageItems.add(const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text('...')));
        }
      }

      for (int i = startPage; i <= endPage; i++) {
        pageItems.add(_buildPageItem(i));
      }

      if (endPage < _totalPages) {
        if (endPage < _totalPages - 1) {
          pageItems.add(const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text('...')));
        }
        pageItems.add(_buildPageItem(_totalPages));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed:
                _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            child: const Text('Anterior'),
          ),
          const SizedBox(width: 8),
          ...pageItems,
          const SizedBox(width: 8),
          TextButton(
            onPressed: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    final provider = Provider.of<PacienteProvider>(context, listen: false);
    final isOffline = paciente.syncStatus == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              lightGreen.withOpacity(0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: isOffline
                ? Colors.orange.shade700
                : primaryGreen,
            child: isOffline
                ? const Icon(Iconsax.warning_2,
                    color: Colors.white, size: 20)
                : Text(
                    paciente.nombre[0] +
                        paciente.apellido[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
          ),
          title: Text(
            paciente.nombreCompleto,
            style: const TextStyle(
                fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'ID: ${paciente.identificacion}',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (provider.getSedeById(
                      paciente.idsede) !=
                  null)
                Text(
                  'Sede: ${provider.getSedeById(paciente.idsede)?['nombresede'] ?? 'Desconocida'}',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black54),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Iconsax.edit,
                    size: 20, color: primaryGreen),
                onPressed: () =>
                    _showEditPacienteDialog(
                        context, paciente),
              ),
              IconButton(
                icon: const Icon(Iconsax.trash,
                    size: 20, color: Colors.red),
                onPressed: () => _deletePaciente(
                    context, paciente.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPacientesDisplay(List<Paciente> pacientesToShow, bool isTablet) {
    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: pacientesToShow.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420.0,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 2.8,
        ),
        itemBuilder: (context, index) {
          final paciente = pacientesToShow[index];
          return _buildPacienteCard(paciente);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: pacientesToShow.length,
        itemBuilder: (context, index) {
          final paciente = pacientesToShow[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _buildPacienteCard(paciente),
          );
        },
      );
    }
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
            onPressed: _refreshPacientesFromServer,
          ),
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content:
                      const Text('¿Estás seguro de que quieres cerrar sesión?'),
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
                      child: const Text('Cerrar sesión',
                          style: TextStyle(color: Colors.red)),
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
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o identificación...',
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > kTabletBreakpoint;
                return Consumer<PacienteProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && !provider.isLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pacientesToShow = _getPaginatedPacientes();

                    if (_filteredPacientes.isEmpty && _isSearching) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.search_normal,
                                size: 50, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron pacientes con "${_searchController.text}"',
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
                            const Icon(Iconsax.people,
                                size: 50, color: Colors.grey),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                '${_filteredPacientes.length} de ${_uniquePacientes.length} pacientes',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshPacientesFromServer,
                            child: _buildPacientesDisplay(pacientesToShow, isTablet),
                          ),
                        ),
                        _buildPagination(),
                      ],
                    );
                  },
                );
              }
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
    if (provider.sedes.isEmpty) {
      await provider.loadSedes();
    }
    final sedes = provider.sedes;
    if (sedes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudieron cargar las sedes. Verifique su conexión e intente de nuevo.')));
      }
      return;
    }
    final db = DatabaseHelper.instance;
    final currentUser = await db.getLoggedInUser();
    if (currentUser != null && currentUser['sede_id'] != null) {
      sedeSeleccionada = currentUser['sede_id'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: AlertDialog(
                  title: Text('Agregar Paciente', style: TextStyle(color: primaryGreen)),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                          controller: nombreController,
                          decoration: InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: apellidoController,
                          decoration: InputDecoration(
                              labelText: 'Apellido',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: identificacionController,
                          decoration: InputDecoration(
                              labelText: 'Identificación',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            value: genero,
                            items: ['Masculino', 'Femenino', 'Otro']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => genero = v!),
                            decoration: InputDecoration(
                                labelText: 'Género',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)))),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            value: sedeSeleccionada,
                            items: sedes.map<DropdownMenuItem<String>>((s) =>
                                DropdownMenuItem<String>(
                                    value: s['id'],
                                    child: Text(s['nombresede'] ?? ''))).toList(),
                            onChanged: (v) => setState(() => sedeSeleccionada = v),
                            decoration: InputDecoration(
                                labelText: 'Sede',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            validator: (v) => v == null ? 'Requerido' : null),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Fecha de Nacimiento'),
                          subtitle: Text(fechaNacimiento == null
                              ? 'Seleccionar fecha'
                              : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'),
                          trailing: Icon(Iconsax.calendar, color: primaryGreen),
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now());
                            if (date != null) setState(() => fechaNacimiento = date);
                          },
                        ),
                        if (isSaving)
                          const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: LinearProgressIndicator()),
                      ]),
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white),
                        onPressed: isSaving ? null : () async {
                          if (formKey.currentState!.validate() && fechaNacimiento != null && sedeSeleccionada != null) {
                            setState(() => isSaving = true);
                            final nuevoPaciente = Paciente(
                              id: '',
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
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Paciente agregado exitosamente'),
                                    backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                                    backgroundColor: Colors.red));
                              }
                            } finally {
                              if (mounted) setState(() => isSaving = false);
                            }
                          }
                        },
                        child: const Text('Guardar')),
                  ],
                ),
              ),
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
  
  // Convertir el valor abreviado del género a su forma completa
  String genero = paciente.genero;
  // Mapeo de abreviaturas a valores completos
  if (genero == 'M') genero = 'Masculino';
  if (genero == 'F') genero = 'Femenino';
  if (genero == 'O') genero = 'Otro';
  
  String? sedeSeleccionada = paciente.idsede;
  bool isSaving = false;
  
  // Mostrar indicador de carga mientras se obtienen las sedes
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
  
  final provider = Provider.of<PacienteProvider>(context, listen: false);
  
  try {
    // Forzar la carga de sedes y esperar a que termine
    await provider.loadSedes();
    
    // Cerrar el diálogo de carga
    if (context.mounted) Navigator.of(context).pop();
    
    // Verificar que haya sedes disponibles
    final sedes = provider.sedes;
    
    // Verificar que la sede seleccionada exista en la lista de sedes
    bool sedeExiste = sedes.any((sede) => sede['id'] == sedeSeleccionada);
    if (!sedeExiste && sedes.isNotEmpty) {
      // Si la sede no existe, seleccionar la primera por defecto
      sedeSeleccionada = sedes.first['id'];
    }
    
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            // Definir las opciones de género
            final generoOptions = ['Masculino', 'Femenino', 'Otro'];
            
            // Si el género no está en las opciones, usar el primero por defecto
            if (!generoOptions.contains(genero)) {
              genero = generoOptions.first;
            }
            
            // Construir la lista de DropdownMenuItem de manera segura
            List<DropdownMenuItem<String>> buildSedeItems() {
              if (sedes.isEmpty) return [];
              
              return sedes.map<DropdownMenuItem<String>>((s) {
                // Verificar que 'id' y 'nombresede' no sean nulos
                final id = s['id']?.toString() ?? '';
                final nombre = s['nombresede']?.toString() ?? 'Sede sin nombre';
                
                if (id.isEmpty) return DropdownMenuItem<String>(value: '', child: Text('ID inválido'));
                
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(nombre),
                );
              }).toList();
            }
            
            // Verificar si sedeSeleccionada existe en las opciones disponibles
            void validateSedeSeleccionada() {
              if (sedeSeleccionada == null || sedeSeleccionada!.isEmpty) {
                if (sedes.isNotEmpty) {
                  sedeSeleccionada = sedes.first['id']?.toString() ?? '';
                }
              } else {
                final existe = sedes.any((s) => s['id']?.toString() == sedeSeleccionada);
                if (!existe && sedes.isNotEmpty) {
                  sedeSeleccionada = sedes.first['id']?.toString() ?? '';
                }
              }
            }
            
            // Asegurar que sedeSeleccionada tenga un valor válido
            validateSedeSeleccionada();
            
            // Construir la lista de items para el dropdown
            final sedeItems = buildSedeItems();
            
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: AlertDialog(
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)
                              )
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: apellidoController,
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)
                              )
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: identificacionController,
                            decoration: InputDecoration(
                              labelText: 'Identificación',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)
                              )
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: genero,
                            items: generoOptions
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                            onChanged: (v) => setState(() => genero = v!),
                            decoration: InputDecoration(
                              labelText: 'Género',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)
                              )
                            )
                          ),
                          const SizedBox(height: 16),
                          // Verificar que sedeItems no esté vacío antes de crear el dropdown
                          sedeItems.isNotEmpty
                            ? DropdownButtonFormField<String>(
                                value: sedeSeleccionada,
                                items: sedeItems,
                                onChanged: (v) => setState(() => sedeSeleccionada = v),
                                decoration: InputDecoration(
                                  labelText: 'Sede',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)
                                  )
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No hay sedes disponibles',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Fecha de Nacimiento'),
                            subtitle: Text(
                              '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}'
                            ),
                            trailing: Icon(Iconsax.calendar, color: primaryGreen),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: fechaNacimiento,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now()
                              );
                              if (date != null) setState(() => fechaNacimiento = date);
                            }
                          ),
                          if (isSaving)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: LinearProgressIndicator()
                            ),
                        ]
                      )
                    )
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar')
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white
                      ),
                      onPressed: isSaving || sedeItems.isEmpty ? null : () async {
                        if (formKey.currentState!.validate() && sedeSeleccionada != null) {
                          setState(() => isSaving = true);
                          
                          // Convertir el género de vuelta a su forma abreviada para guardar
                          String generoAbreviado = genero;
                          if (genero == 'Masculino') generoAbreviado = 'M';
                          if (genero == 'Femenino') generoAbreviado = 'F';
                          if (genero == 'Otro') generoAbreviado = 'O';
                          
                          final pacienteActualizado = paciente.copyWith(
                            identificacion: identificacionController.text.trim(),
                            fecnacimiento: fechaNacimiento,
                            nombre: nombreController.text.trim(),
                            apellido: apellidoController.text.trim(),
                            genero: generoAbreviado, // Usar la forma abreviada
                            idsede: sedeSeleccionada!,
                          );
                          try {
                            await provider.updatePaciente(pacienteActualizado);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Paciente actualizado exitosamente'),
                                  backgroundColor: Colors.green
                                )
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                                  backgroundColor: Colors.red
                                )
                              );
                            }
                          } finally {
                            if (context.mounted) setState(() => isSaving = false);
                          }
                        }
                      },
                      child: const Text('Actualizar')
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    }
  } catch (e) {
    // Cerrar el diálogo de carga en caso de error
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las sedes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}




  Future<void> _deletePaciente(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este paciente?'),
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