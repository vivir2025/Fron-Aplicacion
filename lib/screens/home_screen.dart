import 'package:flutter/material.dart';
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensaje de bienvenida
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        auth.user?.name ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Título de opciones
                Text(
                  'Opciones del Sistema',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Grid de opciones
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
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
                      icon: Icons.science,
                      title: 'Laboratorios',
                      subtitle: 'Resultados de laboratorio',
                      color: Colors.red,
                      onTap: () {
                        _showComingSoon(context, 'Laboratorios');
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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