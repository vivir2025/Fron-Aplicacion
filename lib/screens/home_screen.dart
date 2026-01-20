import 'package:flutter/material.dart';
import 'package:Bornive/screens/afinamientos_screen.dart';
import 'package:Bornive/screens/brigadas_screen.dart';
import 'package:Bornive/screens/encuestas_list_view.dart';
import 'package:Bornive/screens/envio_muestras_screen.dart';
import 'package:Bornive/screens/findrisk_list_screen.dart';
import 'package:Bornive/screens/tamizaje_screen.dart';
import 'package:Bornive/screens/tamizajes_lista_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/sincronizacion_service.dart';
import '../services/estadisticas_service.dart'; // 🆕 Servicio de estadísticas
import '../database/database_helper.dart';
import 'pacientes_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSyncing = false;
  
  // 📊 Variables de estadísticas
  Map<String, dynamic> _estadisticas = {};
  bool _cargandoEstadisticas = false;
  bool _estadisticasExpandidas = false; // Para el panel desplegable
  String _origenEstadisticas = 'local'; // 'local' o 'api'
  DateTime? _fechaInicioFiltro;
  DateTime? _fechaFinFiltro;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 📊 Cargar estadísticas híbridas (API + Local)
  Future<void> _cargarEstadisticas() async {
    setState(() {
      _cargandoEstadisticas = true;
    });

    try {
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      final token = usuario?['token'];

      // Obtener estadísticas híbridas (intenta API, fallback a local)
      final estadisticas = await EstadisticasService.getEstadisticasHibridas(
        token: token,
        fechaInicio: _fechaInicioFiltro,
        fechaFin: _fechaFinFiltro,
      );

      setState(() {
        _estadisticas = estadisticas;
        _origenEstadisticas = estadisticas['origen'] ?? 'local';
        _cargandoEstadisticas = false;
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      setState(() {
        _cargandoEstadisticas = false;
      });
    }
  }

  /// 📅 Seleccionar rango de fechas
  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fechaInicioFiltro != null && _fechaFinFiltro != null
          ? DateTimeRange(start: _fechaInicioFiltro!, end: _fechaFinFiltro!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaInicioFiltro = picked.start;
        _fechaFinFiltro = picked.end;
      });
      await _cargarEstadisticas();
    }
  }

  /// 🗑️ Limpiar filtros de fecha
  void _limpiarFiltros() {
    setState(() {
      _fechaInicioFiltro = null;
      _fechaFinFiltro = null;
    });
    _cargarEstadisticas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/borniveicoo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.business,
                  size: 24,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Bornive',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón de sincronización
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _sincronizar,
            tooltip: 'Sincronizar datos',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Perfil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E7D32).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _cargarEstadisticas,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(_getResponsivePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mensaje de bienvenida mejorado
                      _buildWelcomeCard(auth),
                      
                      SizedBox(height: _getResponsiveSpacing(context, 24)),
                      
                      // 🆕 Panel de estadísticas desplegable
                      _buildEstadisticasPanel(),
                      
                      SizedBox(height: _getResponsiveSpacing(context, 24)),
                      
                      // Título de opciones
                      Row(
                        children: [
                          Icon(
                            Icons.dashboard,
                            color: Colors.grey.shade700,
                            size: _getResponsiveFontSize(context, 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Módulos del Sistema',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 22),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: _getResponsiveSpacing(context, 16)),
                      
                      // Grid responsive de opciones mejorado
                      _buildModulesGrid(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_getResponsivePadding(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: _getResponsiveIconSize(context) * 0.8,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido de vuelta!',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      auth.user?['nombre'] ?? '',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 18),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Organizacion comunitaria llegando a tu vida',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 12),
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Panel de estadísticas desplegable profesional
  Widget _buildEstadisticasPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _estadisticasExpandidas,
          onExpansionChanged: (expanded) {
            setState(() {
              _estadisticasExpandidas = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              // Badge indicador de origen
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _origenEstadisticas == 'api' 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _origenEstadisticas == 'api' ? Icons.cloud_done : Icons.storage,
                      size: 12,
                      color: _origenEstadisticas == 'api' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _origenEstadisticas == 'api' ? 'En línea' : 'Local',
                      style: TextStyle(
                        fontSize: 10,
                        color: _origenEstadisticas == 'api' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: _fechaInicioFiltro != null && _fechaFinFiltro != null
              ? Text(
                  'Filtrado: ${_formatearFecha(_fechaInicioFiltro!)} - ${_formatearFecha(_fechaFinFiltro!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                )
              : Text(
                  'Toca para ver estadísticas detalladas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
          trailing: _cargandoEstadisticas
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                )
              : Icon(
                  _estadisticasExpandidas 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF2E7D32),
                ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botones de filtro
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarRangoFechas,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: const Text('Filtrar por fecha'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (_fechaInicioFiltro != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _limpiarFiltros,
                          icon: const Icon(Icons.clear),
                          color: Colors.red,
                          tooltip: 'Limpiar filtros',
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _cargarEstadisticas,
                        icon: const Icon(Icons.refresh),
                        color: const Color(0xFF2E7D32),
                        tooltip: 'Refrescar',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Grid de estadísticas
                  _buildEstadisticasGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Grid de estadísticas detalladas
  Widget _buildEstadisticasGrid() {
    if (_cargandoEstadisticas) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Map<String, dynamic>> stats = [
      {
        'label': 'Pacientes',
        'value': _estadisticas['pacientes'] ?? 0,
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'label': 'Visitas',
        'value': _estadisticas['visitas'] ?? 0,
        'icon': Icons.home_work,
        'color': Colors.green,
      },
      {
        'label': 'Laboratorios',
        'value': _estadisticas['laboratorios'] ?? 0,
        'icon': Icons.science,
        'color': Colors.teal,
      },
      {
        'label': 'Encuestas',
        'value': _estadisticas['encuestas'] ?? 0,
        'icon': Icons.poll,
        'color': Colors.indigo,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(MediaQuery.of(context).size.width),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['label'],
          stat['value'].toString(),
          stat['icon'],
          stat['color'],
        );
      },
    );
  }

  /// 📊 Tarjeta individual de estadística
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 📅 Formatear fecha
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Widget _buildModulesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        double childAspectRatio = _getChildAspectRatio(constraints.maxWidth);
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: _getResponsiveSpacing(context, 16),
          mainAxisSpacing: _getResponsiveSpacing(context, 16),
          childAspectRatio: childAspectRatio,
          children: [
            _buildMenuCard(
              context,
              icon: Icons.people,
              title: 'Pacientes',
              subtitle: 'Gestionar información de pacientes',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PacientesScreen(onLogout: widget.onLogout),
                  ),
                );
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.monitor_heart,
              title: 'Tamizajes',
              subtitle: 'Tamizaje de presión arterial',
              color: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TamizajesListaScreen(),
                  ),
                );
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.home_work,
              title: 'Visitas Domiciliarias',
              subtitle: 'Programar y gestionar visitas',
              color: Colors.green,
              onTap: () {
                Navigator.of(context).pushNamed('/visitas');
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.medical_services,
              title: 'Medicamentos',
              subtitle: 'Gestionar medicamentos pendientes',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BrigadasScreen(),
                  ),
                );
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.assessment,
              title: 'Test FINDRISK',
              subtitle: 'Evaluaciones de riesgo diabético',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindriskListScreen(),
                  ),
                );
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.tune,
              title: 'Afinamientos',
              subtitle: 'Afinamientos de presión arterial',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AfinamientosScreen(),
                  ),
                );
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.poll,
              title: 'Encuestas',
              subtitle: 'Completar encuestas de salud',
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EncuestasListView(),
                  ),
                );
              },
            ),
            
            _buildMenuCard(
              context,
              icon: Icons.local_shipping,
              title: 'Envío de Muestras',
              subtitle: 'Gestionar envío de muestras',
              color: Colors.brown,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EnvioMuestrasScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 900;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: _getResponsiveIconSize(context) * 0.8,
                  color: color,
                ),
              ),
              
              SizedBox(height: _getResponsiveSpacing(context, 12)),
              
              Text(
                title,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: color.shade800 ?? color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: _getResponsiveSpacing(context, 4)),
              
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sincronizar() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      if (usuario == null || usuario['token'] == null) {
        _mostrarError('No hay usuario autenticado');
        return;
      }

      final resultado = await SincronizacionService.sincronizacionCompleta(
        usuario['token']
      );

      if (resultado['exito_general']) {
        _mostrarExito('Sincronización completada exitosamente');
        await _cargarEstadisticas(); // Recargar estadísticas
      } else {
        _mostrarError('Error en la sincronización');
      }
    } catch (e) {
      _mostrarError('Error en la sincronización: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Funciones de responsividad
  // Funciones de responsividad
  int _getCrossAxisCount(double width) {
    if (width < 600) {
      return 2; // Teléfonos: 2 columnas
    } else if (width < 900) {
      return 3; // Tablets pequeñas: 3 columnas
    } else if (width < 1200) {
      return 4; // Tablets grandes: 4 columnas
    } else {
      return 5; // Escritorio: 5 columnas
    }
  }

  double _getChildAspectRatio(double width) {
    if (width < 600) {
      return 1.0; // Teléfonos: cards más cuadradas
    } else if (width < 900) {
      return 1.1; // Tablets: aspect ratio balanceado
    } else {
      return 1.2; // Escritorio: cards más anchas
    }
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 16.0;
    } else if (width < 900) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return baseSize * 0.9;
    } else if (width < 900) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return baseSpacing * 0.8;
    } else if (width < 900) {
      return baseSpacing;
    } else {
      return baseSpacing * 1.2;
    }
  }

  double _getResponsiveIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 32.0;
    } else if (width < 900) {
      return 40.0;
    } else {
      return 48.0;
    }
  }
}

// Extensiones para manejar propiedades que podrían no existir
extension on Map<String, dynamic>? {
  String? get name => this?['name']?.toString();
}

extension ColorExtension on Color {
  Color? get shade800 {
    // Crear un color más oscuro manualmente
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor();
  }
}
