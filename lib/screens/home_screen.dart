import 'package:flutter/material.dart';
import 'package:fnpv_app/screens/afinamientos_screen.dart';
import 'package:fnpv_app/screens/brigadas_screen.dart';
import 'package:fnpv_app/screens/encuestas_list_view.dart';
import 'package:fnpv_app/screens/envio_muestras_screen.dart';
import 'package:fnpv_app/screens/findrisk_list_screen.dart';
import 'package:fnpv_app/screens/tamizaje_screen.dart'; // 🆕 Importar tamizajes
import 'package:fnpv_app/screens/tamizajes_lista_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/sincronizacion_service.dart'; // 🆕 Para sincronización
import '../database/database_helper.dart'; // 🆕 Para estadísticas
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
  Map<String, int> _estadisticas = {};

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

  Future<void> _cargarEstadisticas() async {
    try {
      final db = DatabaseHelper.instance;
      
      // Obtener estadísticas básicas
      final pacientesCount = await db.countPacientes();
      final visitasCount = await db.countVisitas();
      final medicamentosCount = await db.countMedicamentosPendientes();
      final tamizajesCount = await db.countTamizajes();
      
      setState(() {
        _estadisticas = {
          'pacientes': pacientesCount,
          'visitas': visitasCount,
          'medicamentos': medicamentosCount,
          'tamizajes': tamizajesCount,
        };
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FNPVI - Principal',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                      
                      // Panel de estadísticas rápidas
                      _buildStatsPanel(),
                      
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
            'Fundación Nacional para la Promoción de la Vida Integral',
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

  Widget _buildStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: const Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen Rápido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Pacientes',
                  '${_estadisticas['pacientes'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Visitas',
                  '${_estadisticas['visitas'] ?? 0}',
                  Icons.home_work,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Medicamentos',
                  '${_estadisticas['medicamentos'] ?? 0}',
                  Icons.medical_services,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Tamizajes',
                  '${_estadisticas['tamizajes'] ?? 0}',
                  Icons.monitor_heart,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
              count: _estadisticas['pacientes'],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PacientesScreen(onLogout: widget.onLogout),
                  ),
                );
              },
            ),
            
            // 🆕 Nueva tarjeta de Tamizajes
            _buildMenuCard(
              context,
              icon: Icons.monitor_heart,
              title: 'Tamizajes',
              subtitle: 'Tamizaje de presión arterial',
              color: Colors.red,
              count: _estadisticas['tamizajes'],
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
              count: _estadisticas['visitas'],
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
              count: _estadisticas['medicamentos'],
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
    int? count,
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
              // Icono con badge de contador
              Stack(
                clipBehavior: Clip.none,
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
                  if (count != null && count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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

  // Funciones de responsividad (mantener las existentes)
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
