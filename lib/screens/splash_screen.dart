import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _sweepController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para la entrada del logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para el efecto de barrido continuo (estilo Bancolombia / premium)
    _sweepController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animación de escala (crece un poco al entrar y se asienta)
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Animación de opacidad (fade in)
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Animación de barrido (de -1 a 2 para cruzar toda la pantalla de forma diagonal)
    _sweepAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _sweepController,
        curve: Curves.easeInOutSine,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _logoController.forward();
    
    // Iniciar el barrido repetitivo
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _sweepController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo animado de barrido (Sweeping gradient)
          AnimatedBuilder(
            animation: _sweepAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: _SweepPainter(
                    progress: _sweepAnimation.value,
                    primaryColor: const Color(0xFF1B5E20), // Verde principal
                    secondaryColor: const Color(0xFF4CAF50), // Verde brillante
                  ),
                ),
              );
            },
          ),
          
          // Centro: Logo de la app animado
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icon/Bornive.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business,
                            size: 100,
                            color: Color(0xFF1B5E20),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Inferior: Textos de pie de página "from [Fundación]"
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacityAnimation.value,
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
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/icon/fundacionico.png',
                        width: 100,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para dibujar un efecto de "barrido" oblicuo cruzando la pantalla
/// similar a los efectos de apps bancarias (limpio y corporativo).
class _SweepPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _SweepPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Solo dibujamos si el progreso está en rango visible
    if (progress <= -0.5 || progress >= 1.5) return;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Calculamos el centro actual del barrido en el eje diagonal
    // progress va de -1 a 2. La diagonal efectiva es más o menos el ancho + alto
    final travelX = size.width * progress;
    final travelY = size.height * progress;

    // Crear un gradiente lineal que da el efecto de iluminación / cinta gruesa
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withAlpha(0),
        primaryColor.withAlpha(5),
        secondaryColor.withAlpha(20),
        primaryColor.withAlpha(40),
        primaryColor.withAlpha(5),
        Colors.white.withAlpha(0),
      ],
      stops: const [0.0, 0.2, 0.4, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Dibujamos un polígono cruzando transversalmente la pantalla
    final path = Path();
    
    // Configurar grosor de la banda de barrido
    final bandWidth = size.width * 1.5;

    // Puntos del paralelogramo (banda diagonal cruzando de arriba-izquierda a abajo-derecha)
    path.moveTo(travelX - bandWidth, travelY - size.height * 0.5);
    path.lineTo(travelX + size.width * 0.5, travelY - bandWidth);
    path.lineTo(travelX + bandWidth * 1.5, travelY + size.height * 0.5);
    path.lineTo(travelX - size.width * 0.5, travelY + bandWidth * 1.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}