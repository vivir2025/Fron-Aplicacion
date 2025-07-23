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
  late AnimationController _waveController; // NUEVO: Para el efecto ondulante
  
  late Animation<double> _logoAnimation;
  late Animation<double> _linesAnimation;
  late Animation<double> _waveAnimation; // NUEVO: Animación de onda

  // Colores más vibrantes y modernos
  final List<Color> lineColors = [
    Color(0xFF00A651), // Verde Bancolombia
    Color(0xFF0066CC), // Azul Bancolombia
    Color(0xFF4A90E2), // Azul claro
    Color(0xFF00A651), // Verde
    Color(0xFF0066CC), // Azul
    Color(0xFF7B68EE), // Púrpura moderno
    Color(0xFF00A651), // Verde
    Color.fromARGB(255, 46, 168, 97), // Coral moderno
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
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );

    // NUEVO: Controlador para el efecto ondulante
    _waveController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    // Animación del logo (aparece con fade y escala)
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut, // Cambio: efecto más dinámico
    ));

    // Animación de las líneas
    _linesAnimation = Tween<double>(
      begin: -1.2,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _linesController,
      curve: Curves.easeInOutCubic, // Cambio: curva más suave
    ));

    // NUEVO: Animación de onda
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 4 * pi, // Dos ciclos completos
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Primero aparece el logo
    await Future.delayed(Duration(milliseconds: 300));
    _logoController.forward();
    
    // Luego empiezan las líneas y las ondas
    await Future.delayed(Duration(milliseconds: 400));
    _linesController.repeat();
    _waveController.repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _linesController.dispose();
    _waveController.dispose(); // NUEVO: Dispose del controlador de onda
    super.dispose();
  }

  // MÉTODO ACTUALIZADO: Líneas más gruesas con efecto ondulante
  Widget _buildAnimatedLine(Color color, double delay, double baseHeight, double verticalOffset) {
    return AnimatedBuilder(
      animation: Listenable.merge([_linesAnimation, _waveAnimation]),
      builder: (context, child) {
        // Calcular la posición horizontal
        double horizontalPosition = (MediaQuery.of(context).size.width + 300) * 
            _linesAnimation.value - 150;
        
        // NUEVO: Calcular el desplazamiento vertical ondulante
        double waveOffset = sin(_waveAnimation.value + delay * 2) * 15; // Amplitud de 15px
        
        // NUEVO: Calcular la altura dinámica (efecto de respiración)
        double dynamicHeight = baseHeight + sin(_waveAnimation.value * 0.7 + delay) * 3;
        
        return Transform.translate(
          offset: Offset(
            horizontalPosition,
            waveOffset, // Aplicar el desplazamiento ondulante
          ),
          child: Container(
            width: 200, // CAMBIO: Líneas más largas
            height: dynamicHeight, // CAMBIO: Altura dinámica
            decoration: BoxDecoration(
              // NUEVO: Gradiente para efecto más moderno
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.9),
                  color.withOpacity(0.3),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(dynamicHeight / 2),
              // NUEVO: Sombra sutil
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NUEVO: Gradiente de fondo más moderno
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FA),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Líneas animadas con efecto ondulante
            Positioned.fill(
              child: Stack(
                children: [
                  // Líneas superiores (más gruesas)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.25,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[0], 0.0, 8, 0), // Más gruesa
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.28,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[1], 0.5, 12, 0), // Más gruesa
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.32,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[2], 1.0, 6, 0), // Más gruesa
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.36,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[3], 1.5, 10, 0), // Más gruesa
                  ),
                  
                  // Líneas inferiores (más gruesas)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.64,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[4], 0.3, 9, 0), // Más gruesa
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.68,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[5], 0.8, 7, 0), // Más gruesa
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.72,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[6], 1.3, 11, 0), // Más gruesa
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.76,
                    left: -150,
                    child: _buildAnimatedLine(lineColors[7], 1.8, 8, 0), // Más gruesa
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
                        width: 200, // CAMBIO: Logo más grande
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25), // Más redondeado
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15), // Sombra más pronunciada
                              spreadRadius: 8,
                              blurRadius: 25,
                              offset: Offset(0, 8),
                            ),
                            // NUEVO: Sombra interna sutil
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              spreadRadius: -5,
                              blurRadius: 15,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(25), // Más padding
                        child: Image.asset(
                          'assets/splash/icon.png',
                          fit: BoxFit.contain,
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