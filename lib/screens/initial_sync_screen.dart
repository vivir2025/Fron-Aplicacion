import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../services/sincronizacion_service.dart';
import 'dart:ui';

class InitialSyncScreen extends StatefulWidget {
  const InitialSyncScreen({Key? key}) : super(key: key);

  @override
  State<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends State<InitialSyncScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusMessage = 'Iniciando sincronización...';
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSync() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pacienteProvider = Provider.of<PacienteProvider>(context, listen: false);

    try {
      // ✅ PASO 1: Cargar sedes
      setState(() {
        _statusMessage = 'Cargando sedes...';
        _progress = 0.20;
      });
      await pacienteProvider.loadSedes();

      // ✅ PASO 2: Sincronizar pacientes desde servidor
      setState(() {
        _statusMessage = 'Sincronizando pacientes desde servidor...';
        _progress = 0.40;
      });
      
      if (authProvider.isAuthenticated && authProvider.token != null) {
        // 🆕 USAR EL MÉTODO DE SINCRONIZACIÓN COMPLETA DE PACIENTES
        await pacienteProvider.syncPacientesFromServer();
        
        setState(() {
          _statusMessage = 'Pacientes sincronizados correctamente';
          _progress = 0.60;
        });
      } else {
        // Si no hay token, solo cargar desde DB local
        debugPrint('⚠️ Sin token, cargando pacientes desde DB local');
        await pacienteProvider.loadPacientesFromDB();
        
        setState(() {
          _statusMessage = 'Pacientes cargados desde almacenamiento local';
          _progress = 0.60;
        });
      }

      // ✅ PASO 3: Cargar medicamentos
      setState(() {
        _statusMessage = 'Cargando medicamentos...';
        _progress = 0.80;
      });
      await authProvider.loadInitialMedicamentos();

      // ✅ PASO 4: Finalización
      setState(() {
        _statusMessage = '¡Sincronización completa!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }

    } catch (e) {
      debugPrint("❌ Error durante la sincronización inicial: $e");
      
      // ✅ EN CASO DE ERROR, INTENTAR CARGAR SOLO DESDE DB LOCAL
      try {
        setState(() {
          _statusMessage = 'Error de conexión, cargando datos locales...';
          _progress = 0.70;
        });
        
        await pacienteProvider.loadPacientesFromDB();
        
        setState(() {
          _statusMessage = 'Datos locales cargados correctamente';
          _progress = 1.0;
        });
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Modo offline: usando datos locales'),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
        
      } catch (localError) {
        debugPrint("❌ Error crítico cargando datos locales: $localError");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error crítico: $localError'),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 5),
            ),
          );
          await authProvider.logout();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fondo con patrones
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),
            // Contenido principal
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo o ícono
                        Image.asset(
                          'assets/icon/borniveicoo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.business,
                              size: 60,
                              color: Color(0xFF1E8449),
                            );
                          },
                        ),
                        const SizedBox(height: 25),
                        // Título
                        const Text(
                          'Bornive',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E8449),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Indicadores de progreso
                        _buildStatusIndicator(),
                        const SizedBox(height: 30),
                        // Mensaje de estado actual
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2E86C1),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Mensaje de espera
                        Text(
                          'Esto solo tomará un momento',
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Logo de la fundación en la parte inferior
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 80,
                    padding: EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/icon/fundacionico.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.business,
                            size: 30,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator('Cargando sedes', Icons.business_outlined, 0.20),
        const SizedBox(height: 12),
        _buildStepIndicator('Sincronizando pacientes', Icons.people_outline, 0.40),
        const SizedBox(height: 12),
        _buildStepIndicator('Sincronizando medicamentos', Icons.medication_outlined, 0.80),
        const SizedBox(height: 12),
        _buildStepIndicator('Sincronización completa', Icons.check_circle_outline, 1.0),
        const SizedBox(height: 25),
        // Barra de progreso personalizada
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 10,
                width: MediaQuery.of(context).size.width * 0.85 * 0.8 * _progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E86C1),
                      Color(0xFF1E8449),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String message, IconData icon, double progress) {
    final isCompleted = _progress >= progress;
    final isInProgress = _progress < progress && _progress > progress - 0.20;
    
    return Row(
      children: [
        // Solo mostrar el ícono si NO está completado
        if (!isCompleted)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isInProgress 
                  ? const Color(0xFF2E86C1).withOpacity(0.1)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Icon(
                  icon,
                  color: isInProgress 
                      ? const Color(0xFF2E86C1)
                      : Colors.grey[400],
                  size: isInProgress ? 20 + _controller.value * 2 : 20,
                );
              },
            ),
          ),
        if (!isCompleted) const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCompleted || isInProgress ? FontWeight.w600 : FontWeight.normal,
              color: isCompleted 
                  ? const Color(0xFF1E8449)
                  : isInProgress 
                      ? const Color(0xFF2E86C1)
                      : Colors.grey[600],
            ),
          ),
        ),
        // Mostrar check solo si está completado
        if (isCompleted)
          Icon(
            Icons.check_circle,
            color: const Color(0xFF1E8449),
            size: 20,
          ),
      ],
    );
  }
}

// Pintor personalizado para el fondo con patrones (sin cambios)
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E86C1).withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 50.0;
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.15),
        radius,
        paint,
      );
      
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.85),
        radius,
        paint,
      );
    }
    
    final linePaint = Paint()
      ..color = const Color(0xFF1E8449).withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i < 10; i++) {
      final offset = i * 30.0;
      canvas.drawLine(
        Offset(0, offset),
        Offset(offset * 2, 0),
        linePaint,
      );
      
      canvas.drawLine(
        Offset(size.width, size.height - offset),
        Offset(size.width - offset * 2, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
