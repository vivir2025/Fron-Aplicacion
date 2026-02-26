import 'package:Bornive/database/database_helper.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../models/paciente_model.dart';
import '../services/sincronizacion_service.dart';

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

  final Color primaryGreen = const Color(0xFF1B5E20); // Verde premium
  final Color lightGreen = const Color(0xFF4CAF50);
  final Color backgroundColor = const Color(0xFFF0F4F8); // Fondo moderno

  // Breakpoints para diferentes tamaños de pantalla
  static const double kMobileBreakpoint = 600.0;
  static const double kTabletBreakpoint = 900.0;
  static const double kDesktopBreakpoint = 1200.0;

@override
void initState() {
  super.initState();
  _searchController.addListener(_onSearchChanged);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = Provider.of<PacienteProvider>(context, listen: false);
    
    // ✅ SOLO CARGAR DESDE BASE DE DATOS LOCAL
    _loadPacientesFromProvider();
    
    // ✅ VERIFICAR PACIENTES PENDIENTES SIN SINCRONIZAR AUTOMÁTICAMENTE
    _checkPendingPacientesQuietly();
  });
}
// ✅ MÉTODO CORREGIDO EN PACIENTE PROVIDER
Future<void> _checkPendingPacientesQuietly() async {
  final dbHelper = DatabaseHelper.instance;
  
  try {
    // ✅ Solo pacientes con ID temporal offline (creados sin conexión)
    final db = await dbHelper.database;
    final pacientesOffline = await db.query(
      'pacientes',
      where: "id LIKE 'offline_%'",
    );
    
    if (pacientesOffline.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ℹ️ Tienes ${pacientesOffline.length} pacientes sin sincronizar'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'Sincronizar',
            textColor: Colors.white,
            onPressed: _syncPacientesOnly,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
  }
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
// screens/pacientes_screen.dart - MÉTODO MEJORADO
// screens/pacientes_screen.dart - BOTÓN MEJORADO
Future<void> _syncPacientesOnly() async {
  if (!mounted) return;

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  if (!authProvider.isAuthenticated) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay sesión activa'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Sincronizando pacientes...',
            style: TextStyle(color: primaryGreen),
          ),
          const SizedBox(height: 8),
          const Text(
            'Subiendo pacientes offline y descargando faltantes',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  try {
    final resultado = await SincronizacionService.sincronizarSoloPacientes(
      authProvider.token!
    );

    if (mounted) {
      Navigator.of(context).pop();

      final exitosas = resultado['pacientes']['exitosas'] ?? 0;
      final subidos = resultado['pacientes']['subidos'] ?? 0;
      final descargados = resultado['pacientes']['descargados'] ?? 0;
      final fallidas = resultado['pacientes']['fallidas'] ?? 0;
      final tiempo = resultado['tiempo_total'] ?? 0;

      if (resultado['exito_general'] == true) {
        // ✅ RECARGAR SOLO DESDE DB LOCAL
        final provider = Provider.of<PacienteProvider>(context, listen: false);
        await provider.loadPacientesFromDB();
        _loadPacientesFromProvider();
        
        String mensaje = '✅ Sincronización completada en ${tiempo}ms\n';
        if (subidos > 0) mensaje += '📤 $subidos pacientes offline sincronizados\n';
        if (descargados > 0) mensaje += '📥 $descargados pacientes nuevos descargados\n';
        if (subidos == 0 && descargados == 0) mensaje += 'ℹ️ Todo estaba actualizado';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje.trim()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (fallidas > 0) {
        // ✅ MANEJO SEGURO DE ERRORES
        final errores = resultado['pacientes']['errores'];
        String errorMessage = 'Error desconocido';
        
        if (errores is List && errores.isNotEmpty) {
          errorMessage = errores.first.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $fallidas pacientes fallaron: $errorMessage'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ No hay pacientes pendientes por sincronizar'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error de sincronización: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}


  
  // MÉTODO OPCIONAL: Verificar pacientes pendientes al cargar la pantalla
Future<void> _checkPendingPacientes() async {
  final provider = Provider.of<PacienteProvider>(context, listen: false);
  final pendingCount = await provider.getUnsyncedPacientesCount();
  
  if (pendingCount > 0 && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Tienes $pendingCount pacientes pendientes de sincronizar'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Sincronizar',
          textColor: Colors.white,
          onPressed: _syncPacientesOnly,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
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

  // Determinar el tipo de pantalla basado en el ancho
  ScreenType _getScreenType(double width) {
    if (width < kMobileBreakpoint) return ScreenType.mobile;
    if (width < kTabletBreakpoint) return ScreenType.tablet;
    if (width < kDesktopBreakpoint) return ScreenType.desktop;
    return ScreenType.largeDesktop;
  }

  Widget _buildPageItem(int page, ScreenType screenType) {
    final isCurrentPage = page == _currentPage;
    final isCompact = screenType == ScreenType.mobile;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4),
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12, 
            vertical: isCompact ? 6 : 8
          ),
          decoration: BoxDecoration(
            color: isCurrentPage ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCurrentPage ? primaryGreen : Colors.grey.shade300,
            ),
          ),
          child: Text(
            page.toString(),
            style: GoogleFonts.roboto(
              color: isCurrentPage ? Colors.white : Colors.black87,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(ScreenType screenType) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageItems = [];
    final maxVisiblePages = screenType == ScreenType.mobile ? 3 : 5;
    final isCompact = screenType == ScreenType.mobile;

    if (_totalPages <= maxVisiblePages) {
      for (int i = 1; i <= _totalPages; i++) {
        pageItems.add(_buildPageItem(i, screenType));
      }
    } else {
      int startPage = (_currentPage - (maxVisiblePages ~/ 2)).clamp(1, _totalPages);
      int endPage = (startPage + maxVisiblePages - 1).clamp(1, _totalPages);

      if (endPage - startPage < maxVisiblePages - 1) {
        startPage = (endPage - maxVisiblePages + 1).clamp(1, _totalPages);
      }

      if (startPage > 1) {
        pageItems.add(_buildPageItem(1, screenType));
        if (startPage > 2) {
          pageItems.add(Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 4.0 : 8.0, 
              vertical: isCompact ? 6.0 : 8.0
            ),
            child: Text('...', style: TextStyle(fontSize: isCompact ? 12 : 14)),
          ));
        }
      }

      for (int i = startPage; i <= endPage; i++) {
        pageItems.add(_buildPageItem(i, screenType));
      }

      if (endPage < _totalPages) {
        if (endPage < _totalPages - 1) {
          pageItems.add(Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 4.0 : 8.0, 
              vertical: isCompact ? 6.0 : 8.0
            ),
            child: Text('...', style: TextStyle(fontSize: isCompact ? 12 : 14)),
          ));
        }
        pageItems.add(_buildPageItem(_totalPages, screenType));
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 12 : 16, 
        horizontal: isCompact ? 4 : 8
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          if (!isCompact) ...[
            TextButton(
              onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
              child: const Text('Anterior'),
            ),
            const SizedBox(width: 8),
          ],
          ...pageItems,
          if (!isCompact) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
              child: const Text('Siguiente'),
            ),
          ],
        ],
      ),
    );
  }

  // NUEVA FUNCIÓN: Tarjeta optimizada para grid
  Widget _buildPacienteGridCard(Paciente paciente, ScreenType screenType) {
    final provider = Provider.of<PacienteProvider>(context, listen: false);
    final isOffline = paciente.syncStatus == 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(4),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryGreen.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con avatar y acciones
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isOffline ? Colors.orange.shade700 : primaryGreen,
                    child: isOffline
                        ? const Icon(
                            Iconsax.warning_2,
                            color: Colors.white, 
                            size: 16
                          )
                        : Text(
                            paciente.nombre[0] + paciente.apellido[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const Spacer(),
                  _buildActionButtons(paciente, screenType),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información del paciente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente.nombreCompleto,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${paciente.identificacion}',
                      style: GoogleFonts.roboto(
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (provider.getSedeById(paciente.idsede) != null)
                      Expanded(
                        child: Text(
                          'Sede: ${provider.getSedeById(paciente.idsede)?['nombresede'] ?? 'Desconocida'}',
                          style: GoogleFonts.roboto(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta original para lista (mobile)
  Widget _buildPacienteListCard(Paciente paciente, ScreenType screenType) {
    final provider = Provider.of<PacienteProvider>(context, listen: false);
    final isOffline = paciente.syncStatus == 0;
    final isCompact = screenType == ScreenType.mobile;

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16, 
        vertical: isCompact ? 4 : 6
      ),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryGreen.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(isCompact ? 12 : 16),
          leading: CircleAvatar(
            radius: isCompact ? 20 : 24,
            backgroundColor: isOffline ? Colors.orange.shade700 : primaryGreen,
            child: isOffline
                ? Icon(
                    Iconsax.warning_2,
                    color: Colors.white, 
                    size: isCompact ? 16 : 20
                  )
                : Text(
                    paciente.nombre[0] + paciente.apellido[0],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
          ),
          title: Text(
            paciente.nombreCompleto,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 14 : 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'ID: ${paciente.identificacion}',
                style: GoogleFonts.roboto(
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 12 : 14,
                ),
              ),
              if (provider.getSedeById(paciente.idsede) != null)
                Text(
                  'Sede: ${provider.getSedeById(paciente.idsede)?['nombresede'] ?? 'Desconocida'}',
                  style: GoogleFonts.roboto(
                    color: Colors.grey.shade600,
                    fontSize: isCompact ? 11 : 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          trailing: _buildActionButtons(paciente, screenType),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Paciente paciente, ScreenType screenType) {
    final isCompact = screenType == ScreenType.mobile;
    
    if (isCompact) {
      return PopupMenuButton<String>(
        icon: Icon(Iconsax.more, size: 20, color: primaryGreen),
        onSelected: (value) {
          if (value == 'edit') {
            _showEditPacienteDialog(context, paciente);
          } else if (value == 'delete') {
            _deletePaciente(context, paciente.id);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Iconsax.edit, size: 16),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Iconsax.trash, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
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
    );
  }

  // FUNCIÓN CORREGIDA: Ahora usa diferentes tarjetas según el layout
  Widget _buildPacientesDisplay(List<Paciente> pacientesToShow, ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: pacientesToShow.length,
          itemBuilder: (context, index) {
            final paciente = pacientesToShow[index];
            return _buildPacienteListCard(paciente, screenType);
          },
        );
      
      case ScreenType.tablet:
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: pacientesToShow.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 1.4, // Ajustado para mejor proporción
          ),
          itemBuilder: (context, index) {
            final paciente = pacientesToShow[index];
            return _buildPacienteGridCard(paciente, screenType);
          },
        );
      
      case ScreenType.desktop:
        return GridView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: pacientesToShow.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20.0,
            crossAxisSpacing: 20.0,
            childAspectRatio: 1.3, // Ajustado para mejor proporción
          ),
          itemBuilder: (context, index) {
            final paciente = pacientesToShow[index];
            return _buildPacienteGridCard(paciente, screenType);
          },
        );
      
      case ScreenType.largeDesktop:
        return GridView.builder(
          padding: const EdgeInsets.all(32.0),
          itemCount: pacientesToShow.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 24.0,
            crossAxisSpacing: 24.0,
            childAspectRatio: 1.2, // Ajustado para mejor proporción
          ),
          itemBuilder: (context, index) {
            final paciente = pacientesToShow[index];
            return _buildPacienteGridCard(paciente, screenType);
          },
        );
    }
  }

  Widget _buildSearchBar(ScreenType screenType) {
    final isCompact = screenType == ScreenType.mobile;
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.roboto(fontSize: isCompact ? 14 : 15),
        decoration: InputDecoration(
          hintText: isCompact 
            ? 'Buscar paciente...' 
            : 'Buscar por nombre o identificación...',
          hintStyle: GoogleFonts.roboto(color: Colors.grey.shade500, fontSize: isCompact ? 14 : 15),
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16, 
            vertical: isCompact ? 10 : 12
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(ScreenType screenType) {
    final isCompact = screenType == ScreenType.mobile;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16, 
        vertical: isCompact ? 6 : 8
      ),
      child: isCompact 
        ? Column(
            children: [
              Text(
                'Página $_currentPage de $_totalPages',
                style: GoogleFonts.roboto(
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredPacientes.length} de ${_uniquePacientes.length} pacientes',
                style: GoogleFonts.roboto(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Página $_currentPage de $_totalPages',
                style: GoogleFonts.roboto(
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_filteredPacientes.length} de ${_uniquePacientes.length} pacientes',
                style: GoogleFonts.roboto(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
    );
  }

  @override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenType = _getScreenType(constraints.maxWidth);
      final isCompact = screenType == ScreenType.mobile;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          title: Text(
            'Pacientes',
            style: GoogleFonts.roboto(
              fontSize: isCompact ? 18 : 20, 
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            // SOLO EL BOTÓN DE SINCRONIZACIÓN DE PACIENTES
            IconButton(
              icon: const Icon(Iconsax.arrow_swap_horizontal),
              onPressed: _syncPacientesOnly,
              tooltip: 'Sincronizar pacientes pendientes',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(screenType),
            Expanded(
              child: Consumer<PacienteProvider>(
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
                          Icon(
                            Iconsax.search_normal,
                            size: isCompact ? 40 : 50, 
                            color: Colors.grey
                          ),
                          SizedBox(height: isCompact ? 12 : 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No se encontraron pacientes con "${_searchController.text}"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                color: Colors.grey.shade600,
                                fontSize: isCompact ? 14 : 16,
                              ),
                            ),
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
                          Icon(
                            Iconsax.people,
                            size: isCompact ? 40 : 50, 
                            color: Colors.grey
                          ),
                          SizedBox(height: isCompact ? 12 : 16),
                          Text(
                            'No hay pacientes registrados',
                            style: GoogleFonts.roboto(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: isCompact ? 12 : 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddPacienteDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0, // Nuevo diseño
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 16 : 24,
                                vertical: isCompact ? 10 : 14,
                              ),
                            ),
                            icon: const Icon(Iconsax.add, size: 20),
                            label: Text(
                              'Agregar Paciente',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: isCompact ? 14 : 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _buildStatsBar(screenType),
                      Expanded(
                        // ELIMINADO: RefreshIndicator - Sin deslizar para actualizar
                        child: _buildPacientesDisplay(pacientesToShow, screenType),
                      ),
                      _buildPagination(screenType),
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
    },
  );
}


  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: primaryGreen, size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Mantener los métodos de diálogo existentes sin cambios...
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Agregar Paciente', style:GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                          controller: nombreController,
                          decoration: _buildInputDecoration('Nombre', Iconsax.user),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: apellidoController,
                          decoration: _buildInputDecoration('Apellido', Iconsax.user),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: identificacionController,
                          decoration: _buildInputDecoration('Identificación', Iconsax.card),
                          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            value: genero,
                            items: ['Masculino', 'Femenino', 'Otro']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => genero = v!),
                            decoration: _buildInputDecoration('Género', Iconsax.man)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            value: sedeSeleccionada,
                            items: sedes.map<DropdownMenuItem<String>>((s) =>
                                DropdownMenuItem<String>(
                                    value: s['id'],
                                    child: Text(s['nombresede'] ?? ''))).toList(),
                            onChanged: (v) => setState(() => sedeSeleccionada = v),
                            decoration: _buildInputDecoration('Sede', Iconsax.building),
                            validator: (v) => v == null ? 'Requerido' : null),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: primaryGreen,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: primaryGreen,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                            );
                            if (date != null) setState(() => fechaNacimiento = date);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: _buildInputDecoration('Fecha de Nacimiento', Iconsax.calendar),
                            child: Text(
                              fechaNacimiento == null
                                  ? 'Seleccionar fecha'
                                  : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                              style: TextStyle(
                                color: fechaNacimiento == null ? Colors.grey.shade600 : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Editar Paciente', style: GoogleFonts.roboto(color: primaryGreen, fontWeight: FontWeight.w600)),
                    content: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nombreController,
                              decoration: _buildInputDecoration('Nombre', Iconsax.user),
                              validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: apellidoController,
                              decoration: _buildInputDecoration('Apellido', Iconsax.user),
                              validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: identificacionController,
                              decoration: _buildInputDecoration('Identificación', Iconsax.card),
                              validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: genero,
                              items: generoOptions
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                              onChanged: (v) => setState(() => genero = v!),
                              decoration: _buildInputDecoration('Género', Iconsax.man)
                            ),
                            const SizedBox(height: 16),
                            // Verificar que sedeItems no esté vacío antes de crear el dropdown
                            sedeItems.isNotEmpty
                              ? DropdownButtonFormField<String>(
                                  value: sedeSeleccionada,
                                  items: sedeItems,
                                  onChanged: (v) => setState(() => sedeSeleccionada = v),
                                  decoration: _buildInputDecoration('Sede', Iconsax.building),
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
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: fechaNacimiento,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: primaryGreen,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: primaryGreen,
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) setState(() => fechaNacimiento = date);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _buildInputDecoration('Fecha de Nacimiento', Iconsax.calendar),
                                child: Text(
                                  '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
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

// Enum para definir los tipos de pantalla
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

                                