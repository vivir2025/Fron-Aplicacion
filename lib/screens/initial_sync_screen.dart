import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../services/sincronizacion_service.dart';

class InitialSyncScreen extends StatefulWidget {
  const InitialSyncScreen({super.key});

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
              content: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('⚠️ Modo offline: usando datos locales', style: GoogleFonts.roboto())),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
        
      } catch (localError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.danger, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('❌ Error crítico: $localError', style: GoogleFonts.roboto())),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo decorativo moderno y limpio
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B5E20).withAlpha(10), // Verde muy claro
                    Colors.grey.shade50,
                    const Color(0xFF4CAF50).withAlpha(10), // Verde brillante muy claro
                  ],
                ),
              ),
            ),
          ),
          // Formas abstractas en el fondo
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B5E20).withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withAlpha(15),
              ),
            ),
          ),
          
          // Contenido principal (Glassmorphism de alta calidad)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.88,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 30,
                        spreadRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo de la Aplicación
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/Bornive.png', // Ajustado al logo Bornive
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Iconsax.hospital,
                              size: 60,
                              color: Color(0xFF1B5E20),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Título
                      Text(
                        'Preparando todo',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sincronizando tus datos...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Estructura de pasos e indicador de progreso
                      _buildStatusIndicator(),
                      
                      const SizedBox(height: 35),
                      
                      // Mensaje de estado dinámico tipo banner
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1B5E20).withAlpha(30)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_progress < 1.0)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFF1B5E20),
                                ),
                              )
                            else
                              const Icon(Iconsax.tick_circle, color: Color(0xFF1B5E20), size: 16),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _statusMessage,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: const Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Pie de página: Logo de fundación
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'from',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Image.asset(
                  'assets/icon/fundacionico.png',
                  width: 90,
                  height: 45,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        'FUNDACIÓN',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator('Sedes e Instalaciones', Iconsax.building_3, 0.20),
        const SizedBox(height: 16),
        _buildStepIndicator('Registros de Pacientes', Iconsax.profile_2user, 0.60),
        const SizedBox(height: 16),
        _buildStepIndicator('Inventario Médico', Iconsax.health, 0.80),
        const SizedBox(height: 16),
        _buildStepIndicator('Verificación Final', Iconsax.shield_tick, 1.0),
        
        const SizedBox(height: 35),
        
        // Barra de progreso elegante
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.fastOutSlowIn,
                height: 8,
                width: MediaQuery.of(context).size.width * 0.88 * _progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4CAF50), // Verde más claro a la izquierda
                      Color(0xFF1B5E20), // Primary Green a la derecha
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String message, IconData icon, double targetProgress) {
    // Definir rangos reales según los pasos del inicio:
    // Sedes -> 0.20
    // Pacientes -> 0.40 a 0.60
    // Medicamentos -> 0.80
    // Completo -> 1.0

    final isCompleted = _progress >= targetProgress;
    // Está en progreso si el progreso actual está activo pero no ha llegado a completar ese paso
    final isInProgress = _progress < targetProgress && _progress >= (targetProgress - 0.21);
    
    Color iconBgColor = Colors.grey.shade100;
    Color iconColor = Colors.grey.shade400;
    Color textColor = Colors.grey.shade500;
    FontWeight textWeight = FontWeight.normal;

    if (isCompleted) {
      iconBgColor = const Color(0xFF1B5E20).withAlpha(20);
      iconColor = const Color(0xFF1B5E20);
      textColor = Colors.black87;
      textWeight = FontWeight.w600;
    } else if (isInProgress) {
      iconBgColor = const Color(0xFF4CAF50).withAlpha(25);
      iconColor = const Color(0xFF4CAF50);
      textColor = Colors.black87;
      textWeight = FontWeight.bold;
    }

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
            border: isInProgress ? Border.all(color: iconColor.withAlpha(100), width: 1.5) : null,
          ),
          child: isCompleted 
            ? const Icon(Iconsax.tick_circle, color: Color(0xFF1B5E20), size: 20)
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Icon(
                    icon,
                    color: iconColor,
                    size: isInProgress ? 20 + (_controller.value * 2) : 20,
                  );
                },
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: textWeight,
              color: textColor,
            ),
            child: Text(message),
          ),
        ),
      ],
    );
  }
}
