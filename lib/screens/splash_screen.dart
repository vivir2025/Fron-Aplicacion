import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart'; // Importa tu pantalla de login

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _logoController;
  late AnimationController _linesController;
  late AnimationController _waveController;
  late AnimationController _organicController; // NUEVO: Para movimiento orgánico tipo lombriz
  
  late Animation<double> _logoAnimation;
  late Animation<double> _linesAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _organicAnimation; // NUEVO: Animación orgánica

  // Colores más vibrantes y modernos
  final List<Color> lineColors = [
    Color(0xFF00A651), // Verde Bancolombia
    Color(0xFF0066CC), // Azul Bancolombia
    Color(0xFF4A90E2), // Azul claro
    Color(0xFF00A651), // Verde
    Color(0xFF0066CC), // Azul
    Color(0xFF7B68EE), // Púrpura moderno
    Color(0xFF00A651), // Verde
    Color.fromARGB(255, 46, 168, 97), // Verde moderno
  ];

  @override
  void initState() {
    super.initState();
    
    // Controlador para el logo
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Controlador para las líneas (más rápido)
    _linesController = AnimationController(
      duration: Duration(milliseconds: 2500), // Más lento para efecto orgánico
      vsync: this,
    );

    // Controlador para el efecto ondulante
    _waveController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    // NUEVO: Controlador para movimiento orgánico tipo lombriz
    _organicController = AnimationController(
      duration: Duration(milliseconds: 4000), // Movimiento lento y orgánico
      vsync: this,
    );

    // Animación del logo (aparece con fade y escala)
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Animación de las líneas
    _linesAnimation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _linesController,
      curve: Curves.easeInOutSine, // Curva más suave para movimiento orgánico
    ));

    // Animación de onda
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 4 * pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    // NUEVO: Animación orgánica tipo lombriz
    _organicAnimation = Tween<double>(
      begin: 0.0,
      end: 6 * pi, // Más ciclos para efecto serpenteante
    ).animate(CurvedAnimation(
      parent: _organicController,
      curve: Curves.easeInOutSine,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Primero aparece el logo
    await Future.delayed(Duration(milliseconds: 300));
    _logoController.forward();
    
    // Luego empiezan las líneas y las animaciones orgánicas
    await Future.delayed(Duration(milliseconds: 400));
    _linesController.repeat();
    _waveController.repeat();
    _organicController.repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _linesController.dispose();
    _waveController.dispose();
    _organicController.dispose(); // NUEVO: Dispose del controlador orgánico
    super.dispose();
  }

  // MÉTODO ACTUALIZADO: Líneas con movimiento orgánico tipo lombriz
  Widget _buildOrganicLine(Color color, double delay, double baseHeight, int lineIndex) {
    return AnimatedBuilder(
      animation: Listenable.merge([_linesAnimation, _waveAnimation, _organicAnimation]),
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Posición horizontal base
        double horizontalPosition = (screenWidth + 400) * _linesAnimation.value - 200;
        
        // NUEVO: Movimiento vertical orgánico tipo serpiente/lombriz
        double organicWave1 = sin(_organicAnimation.value + delay * 3) * 25;
        double organicWave2 = sin(_organicAnimation.value * 0.7 + delay * 2) * 15;
        double organicWave3 = cos(_organicAnimation.value * 1.3 + delay * 4) * 10;
        
        // Combinar ondas para movimiento más complejo y orgánico
        double verticalOffset = organicWave1 + organicWave2 + organicWave3;
        
        // Movimiento horizontal adicional para simular serpenteado
        double horizontalWave = cos(_organicAnimation.value * 0.5 + delay * 2.5) * 30;
        horizontalPosition += horizontalWave;
        
        // Altura dinámica que cambia como respiración
        double dynamicHeight = baseHeight + sin(_waveAnimation.value * 0.8 + delay * 1.5) * 4;
        
        // Rotación sutil para seguir el movimiento
        double rotation = sin(_organicAnimation.value * 0.3 + delay) * 0.1;
        
        return Transform.translate(
          offset: Offset(horizontalPosition, verticalOffset),
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 250, // Líneas más largas para efecto serpenteante
              height: dynamicHeight,
              decoration: BoxDecoration(
                // Gradiente más suave para efecto orgánico
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.8),
                    color.withOpacity(0.4),
                    color.withOpacity(0.1),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(dynamicHeight),
                // Sombra que sigue el movimiento
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(sin(_organicAnimation.value + delay) * 3, 
                                 cos(_organicAnimation.value + delay) * 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradiente de fondo más suave
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FA),
              Color(0xFFF0F2F5),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Líneas animadas con movimiento orgánico
            Positioned.fill(
              child: Stack(
                children: [
                  // Líneas superiores con movimiento orgánico
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    left: -200,
                    child: _buildOrganicLine(lineColors[0], 0.0, 6, 0),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.20,
                    left: -200,
                    child: _buildOrganicLine(lineColors[1], 0.8, 10, 1),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.25,
                    left: -200,
                    child: _buildOrganicLine(lineColors[2], 1.5, 4, 2),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.30,
                    left: -200,
                    child: _buildOrganicLine(lineColors[3], 2.2, 8, 3),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: -200,
                    child: _buildOrganicLine(lineColors[4], 0.5, 12, 4),
                  ),
                  
                  // Líneas inferiores con movimiento orgánico
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.65,
                    left: -200,
                    child: _buildOrganicLine(lineColors[5], 1.8, 7, 5),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.70,
                    left: -200,
                    child: _buildOrganicLine(lineColors[6], 2.5, 9, 6),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.75,
                    left: -200,
                    child: _buildOrganicLine(lineColors[7], 0.3, 5, 7),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.80,
                    left: -200,
                    child: _buildOrganicLine(lineColors[0], 1.2, 11, 8),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.85,
                    left: -200,
                    child: _buildOrganicLine(lineColors[1], 2.8, 6, 9),
                  ),
                ],
              ),
            ),
            
            // Logo en el centro con efecto mejorado
            Center(
              child: AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _logoAnimation,
                    child: ScaleTransition(
                      scale: _logoAnimation,
                      child: Container(
                        width: 220, // Logo más grande
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 10,
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                            // Sombra interna sutil
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              spreadRadius: -8,
                              blurRadius: 20,
                              offset: Offset(0, -8),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(30),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            'https://nacerparavivir.org/wp-content/uploads/2023/12/Logo_Section1home-8.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback en caso de error de carga
                              return Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF00A651),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.favorite_border,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00A651),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}