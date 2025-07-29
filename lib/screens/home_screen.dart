import 'package:flutter/material.dart';
import 'package:fnpv_app/screens/envio_muestras_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'pacientes_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const HomeScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FNPVI - Principal'),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(_getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensaje de bienvenida
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_getResponsivePadding(context)),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 28),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: _getResponsiveSpacing(context, 8)),
                      Text(
                        auth.user?.name ?? 'Usuario',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 18),
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: _getResponsiveSpacing(context, 24)),
                
                // Título de opciones
                Text(
                  'Opciones del Sistema',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                SizedBox(height: _getResponsiveSpacing(context, 16)),
                
                // Grid responsive de opciones
                LayoutBuilder(
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
                          subtitle: 'Gestionar pacientes',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PacientesScreen(onLogout: onLogout),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.home_work,
                          title: 'Visitas Domiciliarias',
                          subtitle: 'Programar visitas',
                          color: Colors.green,
                          onTap: () {
                            Navigator.of(context).pushNamed('/visitas');
                          },
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.medication,
                          title: 'Medicamentos Pendientes',
                          subtitle: 'Revisar medicamentos',
                          color: Colors.orange,
                          onTap: () {
                            _showComingSoon(context, 'Medicamentos Pendientes');
                          },
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.assessment,
                          title: 'Test Finrisk',
                          subtitle: 'Evaluaciones de riesgo',
                          color: Colors.purple,
                          onTap: () {
                            _showComingSoon(context, 'Test Finrisk');
                          },
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.tune,
                          title: 'Afinamientos',
                          subtitle: 'Ajustes y configuración',
                          color: Colors.teal,
                          onTap: () {
                            _showComingSoon(context, 'Afinamientos');
                          },
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.poll,
                          title: 'Encuestas',
                          subtitle: 'Completar encuestas',
                          color: Colors.indigo,
                          onTap: () {
                            _showComingSoon(context, 'Encuestas');
                          },
                        ),
                       _buildMenuCard(
  context,
  icon: Icons.local_shipping, // Cambié el icono para que sea más representativo
  title: 'Envío de Muestras',
  subtitle: 'Gestionar envío de muestras',
  color: Colors.red,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Función para obtener el número de columnas según el ancho de pantalla
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

  // Función para obtener el aspect ratio según el ancho de pantalla
  double _getChildAspectRatio(double width) {
    if (width < 600) {
      return 1.1; // Teléfonos: cards más altas
    } else if (width < 900) {
      return 1.2; // Tablets: aspect ratio balanceado
    } else {
      return 1.3; // Escritorio: cards más anchas
    }
  }

  // Función para obtener padding responsivo
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 16.0; // Teléfonos: padding pequeño
    } else if (width < 900) {
      return 24.0; // Tablets: padding medio
    } else {
      return 32.0; // Escritorio: padding grande
    }
  }

  // Función para obtener tamaño de fuente responsivo
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return baseSize * 0.9; // Teléfonos: 90% del tamaño base
    } else if (width < 900) {
      return baseSize; // Tablets: tamaño base
    } else {
      return baseSize * 1.1; // Escritorio: 110% del tamaño base
    }
  }

  // Función para obtener espaciado responsivo
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return baseSpacing * 0.8; // Teléfonos: 80% del espaciado base
    } else if (width < 900) {
      return baseSpacing; // Tablets: espaciado base
    } else {
      return baseSpacing * 1.2; // Escritorio: 120% del espaciado base
    }
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
              Icon(
                icon,
                size: _getResponsiveIconSize(context),
                color: color,
              ),
              SizedBox(height: _getResponsiveSpacing(context, 12)),
              Text(
                title,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
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

  // Función para obtener tamaño de icono responsivo
  double _getResponsiveIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 32.0; // Teléfonos: iconos pequeños
    } else if (width < 900) {
      return 40.0; // Tablets: iconos medianos
    } else {
      return 48.0; // Escritorio: iconos grandes
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$feature'),
          content: Text('Esta funcionalidad estará disponible próximamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

extension on Map<String, dynamic>? {
  get name => null;
}

extension on Color {
  get shade800 => null;
}