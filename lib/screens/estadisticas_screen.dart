// screens/estadisticas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/auth_provider.dart';
import '../services/estadisticas_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  bool _isLoading = false;
  bool _mostrarFiltros = false;
  bool _mostrarDebug = false;
  Map<String, dynamic>? _estadisticas;
  String? _error;
  String _origenDatos = 'local'; // 'api' o 'local'
  Map<String, dynamic>? _debugInfo;
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  // 📊 CARGAR ESTADÍSTICAS
  Future<void> _cargarEstadisticas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      // Usar método híbrido: intenta API primero, luego local
      final data = await EstadisticasService.getEstadisticasHibridas(
        token: token,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      // Obtener info del usuario para debug
      final usuarioId = authProvider.usuario?['id'];
      final usuarioNombre = authProvider.usuario?['nombre'];

      setState(() {
        _estadisticas = data;
        _origenDatos = data['origen'] ?? 'local';
        _debugInfo = {
          'usuario_id': usuarioId,
          'usuario_nombre': usuarioNombre,
          'origen': data['origen'],
          'tiene_token': token != null,
          'sincronizado': data['sincronizado'] ?? false,
          'fecha_consulta': data['fecha_consulta'],
          'raw_data': data,
        };
        _isLoading = false;
      });

      // Mostrar mensaje si está usando datos locales
      if (_origenDatos == 'local' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.info_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('📱 Mostrando datos locales (sin conexión a API)', style: GoogleFonts.roboto())),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      // Mostrar alerta si hay datos sospechosos
      if (_origenDatos == 'api' && data['datos_sospechosos'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.warning_2, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Datos sospechosos: El backend puede no estar filtrando correctamente',
                    style: GoogleFonts.roboto(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'INFO',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _mostrarDebug = true;
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // 📅 SELECCIONAR FECHA
  Future<void> _seleccionarFecha(bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esInicio 
          ? (_fechaInicio ?? DateTime.now())
          : (_fechaFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          // Validar que fecha inicio no sea mayor a fecha fin
          if (_fechaFin != null && picked.isAfter(_fechaFin!)) {
            _fechaFin = picked;
          }
        } else {
          _fechaFin = picked;
          // Validar que fecha fin no sea menor a fecha inicio
          if (_fechaInicio != null && picked.isBefore(_fechaInicio!)) {
            _fechaInicio = picked;
          }
        }
      });
    }
  }

  // 🔄 APLICAR FILTROS
  void _aplicarFiltros() {
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona ambas fechas', style: GoogleFonts.roboto()),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    _cargarEstadisticas();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtro aplicado: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}',
          style: GoogleFonts.roboto()
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🗑️ LIMPIAR FILTROS
  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
    _cargarEstadisticas();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.usuario;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Estadísticas',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _mostrarDebug ? Icons.bug_report : Icons.bug_report_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _mostrarDebug = !_mostrarDebug;
              });
            },
            tooltip: 'Información de debug',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _cargarEstadisticas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        color: const Color(0xFF1B5E20),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 👤 HEADER CON INFO DEL USUARIO
              _buildHeader(usuario),

              // 🔍 BOTÓN DE FILTROS
              _buildBotonFiltros(),

              // 📅 PANEL DE FILTROS (DESPLEGABLE)
              if (_mostrarFiltros) _buildPanelFiltros(),

              // 🐛 PANEL DE DEBUG (DESPLEGABLE)
              if (_mostrarDebug && _debugInfo != null) _buildPanelDebug(),

              // 📊 ESTADÍSTICAS
              if (_isLoading)
                _buildLoading()
              else if (_error != null)
                _buildError()
              else if (_estadisticas != null)
                _buildEstadisticas()
              else
                _buildSinDatos(),
                
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 👤 HEADER CON INFORMACIÓN DEL USUARIO
  Widget _buildHeader(Map<String, dynamic>? usuario) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade100,
              child: Text(
                usuario?['nombre']?.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario?['nombre'] ?? 'Usuario',
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    usuario?['email'] ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 BOTÓN PARA MOSTRAR/OCULTAR FILTROS
  Widget _buildBotonFiltros() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _mostrarFiltros = !_mostrarFiltros;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _mostrarFiltros ? const Color(0xFF1B5E20) : Colors.grey.shade200,
              width: _mostrarFiltros ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_mostrarFiltros ? 15 : 5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.filter,
                    color: _mostrarFiltros ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _mostrarFiltros ? 'Ocultar Filtros' : 'Filtrar por Fecha',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _mostrarFiltros ? const Color(0xFF1B5E20) : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Icon(
                _mostrarFiltros ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                color: _mostrarFiltros ? const Color(0xFF1B5E20) : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📅 PANEL DE FILTROS DESPLEGABLE
  Widget _buildPanelFiltros() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.calendar_tick, color: Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                'Selecciona el rango de fechas',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // FECHA INICIO
          _buildCampoFecha(
            label: 'Fecha Inicio',
            fecha: _fechaInicio,
            onTap: () => _seleccionarFecha(true),
            icono: Iconsax.calendar_1,
          ),

          const SizedBox(height: 12),

          // FECHA FIN
          _buildCampoFecha(
            label: 'Fecha Fin',
            fecha: _fechaFin,
            onTap: () => _seleccionarFecha(false),
            icono: Iconsax.calendar_2,
          ),

          const SizedBox(height: 24),

          // BOTONES DE ACCIÓN
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_fechaInicio != null || _fechaFin != null)
                      ? _limpiarFiltros
                      : null,
                  icon: const Icon(Iconsax.eraser_1, size: 20,),
                  label: Text('Limpiar', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _aplicarFiltros,
                  icon: const Icon(Iconsax.tick_circle, size: 20,),
                  label: Text('Aplicar', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📅 CAMPO DE FECHA
  Widget _buildCampoFecha({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
    required IconData icono,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fecha != null
                        ? DateFormat('dd/MM/yyyy').format(fecha)
                        : 'Seleccionar fecha',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: fecha != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  // 📊 ESTADÍSTICAS
  Widget _buildEstadisticas() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO CON INDICADOR DE ORIGEN
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _origenDatos == 'api' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _origenDatos == 'api' ? Colors.green.shade200 : Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _origenDatos == 'api' ? Iconsax.cloud_plus : Iconsax.mobile,
                        size: 16,
                        color: _origenDatos == 'api' ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _origenDatos == 'api' ? 'API' : 'Local',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _origenDatos == 'api' ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ⚠️ ALERTA DE DATOS SOSPECHOSOS
          if (_estadisticas?['datos_sospechosos'] == true)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.danger, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⚠️ Advertencia: Datos Sospechosos',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Los números parecen muy altos para un usuario auxiliar. '
                    'El backend podría no estar filtrando correctamente por tu usuario.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.red.shade800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Revisa el archivo: CORRECCIONES_BACKEND_ESTADISTICAS.md\n'
                    '• Activa el modo debug (icono bicho) para más información',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // GRID DE ESTADÍSTICAS
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth > 600) crossAxisCount = 3;
              if (constraints.maxWidth > 900) crossAxisCount = 4;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildStatCard(
                    titulo: 'Pacientes',
                    valor: _estadisticas?['pacientes'] ?? 0,
                    icono: Iconsax.people,
                    color: Colors.blue.shade700,
                    subtitulo: 'Sistema completo',
                    esFiltrado: false,
                  ),
                  _buildStatCard(
                    titulo: 'Brigadas',
                    valor: _estadisticas?['brigadas'] ?? 0,
                    icono: Iconsax.buildings,
                    color: Colors.purple.shade600,
                    subtitulo: 'Sistema completo',
                    esFiltrado: false,
                  ),
                  _buildStatCard(
                    titulo: 'Mis Visitas',
                    valor: _estadisticas?['visitas'] ?? 0,
                    icono: Iconsax.home_hashtag,
                    color: const Color(0xFF1B5E20),
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),
                  _buildStatCard(
                    titulo: 'Mis Tamizajes',
                    valor: _estadisticas?['tamizajes'] ?? 0,
                    icono: Iconsax.health,
                    color: Colors.orange.shade700,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),
                  _buildStatCard(
                    titulo: 'Mis Muestras',
                    valor: _estadisticas?['laboratorios'] ?? 0,
                    icono: Iconsax.hospital,
                    color: Colors.teal.shade700,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),
                  _buildStatCard(
                    titulo: 'Mis Encuestas',
                    valor: _estadisticas?['encuestas'] ?? 0,
                    icono: Iconsax.document_text,
                    color: Colors.pink.shade600,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),
                ],
              );
            },
          ),

          // NOTA INFORMATIVA
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withAlpha(150),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.info_circle, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Información de Filtrado',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('✅ Filtrado (Usuario)', 'Visitas, Tamizajes, Muestras, Encuestas'),
                const SizedBox(height: 4),
                _buildInfoRow('❌ Sin filtrar (Global)', 'Pacientes, Brigadas'),
                const Divider(height: 24),
                Text(
                  _origenDatos == 'api' 
                    ? '🌐 Los datos filtrados vienen de la API usando tu token de autenticación.'
                    : '📱 Los datos filtrados vienen de tu base de datos local SQLite.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 TARJETA DE ESTADÍSTICA
  Widget _buildStatCard({
    required String titulo,
    required int valor,
    required IconData icono,
    required Color color,
    required String subtitulo,
    required bool esFiltrado,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: color, size: 28),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: esFiltrado ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    esFiltrado ? Icons.check : Icons.public,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            valor.toString(),
            style: GoogleFonts.roboto(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ⏳ LOADING
  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF1B5E20),
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando estadísticas...',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ❌ ERROR
  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            Icon(
              Iconsax.warning_2,
              color: Colors.red.shade400,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estadísticas',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.red.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarEstadisticas,
              icon: const Icon(Iconsax.refresh, size: 20),
              label: Text('Reintentar', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📭 SIN DATOS
  Widget _buildSinDatos() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Iconsax.chart_fail,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No hay estadísticas disponibles',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🐛 PANEL DE DEBUG
  Widget _buildPanelDebug() {
    final usuario = _debugInfo?['usuario_nombre'] ?? 'N/A';
    final usuarioId = _debugInfo?['usuario_id'] ?? 'N/A';
    final origen = _debugInfo?['origen'] ?? 'N/A';
    final tieneToken = _debugInfo?['tiene_token'] ?? false;
    final sincronizado = _debugInfo?['sincronizado'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark theme inside stats
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.radar, color: Colors.green.shade400, size: 24),
              const SizedBox(width: 12),
              Text(
                'Información de Debug',
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),

          _buildDebugSection('👤 Usuario', [
            'Nombre: $usuario',
            'ID: $usuarioId',
          ]),
          const SizedBox(height: 16),

          _buildDebugSection('🌐 Conexión', [
            'Origen de datos: ${origen.toUpperCase()}',
            'Token presente: ${tieneToken ? "✅ Sí" : "❌ No"}',
            'Sincronizado: ${sincronizado ? "✅ Sí" : "❌ No"}',
          ]),
          const SizedBox(height: 16),

          _buildDebugSection('📅 Filtros', [
            'Fecha inicio: ${_fechaInicio != null ? DateFormat('dd/MM/yyyy').format(_fechaInicio!) : "Sin filtro"}',
            'Fecha fin: ${_fechaFin != null ? DateFormat('dd/MM/yyyy').format(_fechaFin!) : "Sin filtro"}',
          ]),
          const SizedBox(height: 16),

          _buildDebugSection('📊 Datos Recibidos', [
            'Pacientes: ${_estadisticas?['pacientes'] ?? 0}',
            'Brigadas: ${_estadisticas?['brigadas'] ?? 0}',
            'Visitas: ${_estadisticas?['visitas'] ?? 0}',
            'Tamizajes: ${_estadisticas?['tamizajes'] ?? 0}',
            'Laboratorios: ${_estadisticas?['laboratorios'] ?? 0}',
            'Encuestas: ${_estadisticas?['encuestas'] ?? 0}',
          ]),
          const SizedBox(height: 16),

          if (_estadisticas?['filtros_aplicados'] != null) ...[
            _buildDebugSection('🔍 Filtros Backend', [
              'Usuario ID: ${_estadisticas?['filtros_aplicados']['usuario_id']}',
              'Sede: ${_estadisticas?['filtros_aplicados']['sede_nombre']}',
              'Fecha inicio: ${_estadisticas?['filtros_aplicados']['fecha_inicio'] ?? "N/A"}',
              'Fecha fin: ${_estadisticas?['filtros_aplicados']['fecha_fin'] ?? "N/A"}',
            ]),
            const SizedBox(height: 16),
          ],

          if (_estadisticas?['usuario_backend'] != null) ...[
            _buildDebugSection('👤 Usuario Backend', [
              'ID: ${_estadisticas?['usuario_backend']['id']}',
              'Nombre: ${_estadisticas?['usuario_backend']['nombre']}',
              'Rol: ${_estadisticas?['usuario_backend']['rol']}',
            ]),
            const SizedBox(height: 20),
          ],

          if (_estadisticas?['datos_sospechosos'] == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.warning_2, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'WARNING: DATOS SOSPECHOSOS',
                        style: GoogleFonts.robotoMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para auxiliar, se espera:\n'
                    '• Pacientes: < 100 (recibido: ${_estadisticas?['pacientes']})\n'
                    '• Visitas: < 200 (recibido: ${_estadisticas?['visitas']})\n\n'
                    '❌ Error en filtro Backend.',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.red.shade100,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade700, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 INFO FILTRADO:',
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade200,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  origen == 'api'
                      ? '• API usa Token Bearer\n'
                        '• Backend filtra auto por ID\n'
                        '• Globales no filtran'
                      : '• SQLite filtra con: usuario_id=$usuarioId\n'
                        '• Solo muestra creados\n'
                        '• Globales=0 localmente',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: Colors.blue.shade100,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 SECCIÓN DE DEBUG TÉCNICO
  Widget _buildDebugSection(String titulo, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent.shade400,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Text(
                '→ $item',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Colors.grey.shade300,
                ),
              ),
            )),
      ],
    );
  }

  // ℹ️ FILA DE INFORMACIÓN
  Widget _buildInfoRow(String titulo, String contenido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$titulo: ',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          Expanded(
            child: Text(
              contenido,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
