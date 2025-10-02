// screens/estadisticas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/estadisticas_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({Key? key}) : super(key: key);

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  bool _isLoading = false;
  bool _mostrarFiltros = false;
  Map<String, dynamic>? _estadisticas;
  String? _error;
  
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

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // TODO: Si tienes fechas seleccionadas, envíalas al backend
      // Por ahora solo obtenemos estadísticas generales
      final data = await EstadisticasService.getEstadisticasDesdeApi(token);

      setState(() {
        _estadisticas = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        const SnackBar(
          content: Text('Selecciona ambas fechas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implementar llamada al backend con fechas
    _cargarEstadisticas();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtro aplicado: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}',
        ),
        backgroundColor: Colors.green,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _cargarEstadisticas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        color: const Color(0xFF2E7D32),
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

              // 📊 ESTADÍSTICAS
              if (_isLoading)
                _buildLoading()
              else if (_error != null)
                _buildError()
              else if (_estadisticas != null)
                _buildEstadisticas()
              else
                _buildSinDatos(),
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
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  usuario?['nombre']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario?['email'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔍 BOTÓN PARA MOSTRAR/OCULTAR FILTROS
  Widget _buildBotonFiltros() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _mostrarFiltros = !_mostrarFiltros;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _mostrarFiltros 
                    ? const Color(0xFF2E7D32) 
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: _mostrarFiltros 
                          ? const Color(0xFF2E7D32) 
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _mostrarFiltros ? 'Ocultar Filtros' : 'Filtrar por Fecha',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _mostrarFiltros 
                            ? const Color(0xFF2E7D32) 
                            : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                Icon(
                  _mostrarFiltros 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: _mostrarFiltros 
                      ? const Color(0xFF2E7D32) 
                      : Colors.grey[600],
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona el rango de fechas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),

          // FECHA INICIO
          _buildCampoFecha(
            label: 'Fecha Inicio',
            fecha: _fechaInicio,
            onTap: () => _seleccionarFecha(true),
            icono: Icons.calendar_today,
          ),

          const SizedBox(height: 12),

          // FECHA FIN
          _buildCampoFecha(
            label: 'Fecha Fin',
            fecha: _fechaFin,
            onTap: () => _seleccionarFecha(false),
            icono: Icons.event,
          ),

          const SizedBox(height: 20),

          // BOTONES DE ACCIÓN
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_fechaInicio != null || _fechaFin != null)
                      ? _limpiarFiltros
                      : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _aplicarFiltros,
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icono, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fecha != null
                        ? DateFormat('dd/MM/yyyy').format(fecha)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: fecha != null ? Colors.black87 : Colors.grey[400],
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

  // 📊 ESTADÍSTICAS
  Widget _buildEstadisticas() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Resumen de Actividades',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),

          // GRID DE ESTADÍSTICAS
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsivo: 2 columnas en móvil, 3 en tablet, 4 en desktop
              int crossAxisCount = 2;
              if (constraints.maxWidth > 600) crossAxisCount = 3;
              if (constraints.maxWidth > 900) crossAxisCount = 4;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  // ❌ Total Pacientes (NO filtrado)
                  _buildStatCard(
                    titulo: 'Total Pacientes',
                    valor: _estadisticas?['pacientes'] ?? 0,
                    icono: Icons.people,
                    color: Colors.blue,
                    subtitulo: 'Sistema completo',
                    esFiltrado: false,
                  ),

                  // ❌ Total Brigadas (NO filtrado)
                  _buildStatCard(
                    titulo: 'Total Brigadas',
                    valor: _estadisticas?['brigadas'] ?? 0,
                    icono: Icons.groups,
                    color: Colors.purple,
                    subtitulo: 'Sistema completo',
                    esFiltrado: false,
                  ),

                  // ✅ Visitas (filtrado por usuario)
                  _buildStatCard(
                    titulo: 'Mis Visitas',
                    valor: _estadisticas?['visitas'] ?? 0,
                    icono: Icons.home_work,
                    color: Colors.green,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),

                  // ✅ Tamizajes (filtrado por usuario)
                  _buildStatCard(
                    titulo: 'Mis Tamizajes',
                    valor: _estadisticas?['tamizajes'] ?? 0,
                    icono: Icons.medical_services,
                    color: Colors.orange,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),

                  // ✅ Envío Muestras (filtrado por usuario)
                  _buildStatCard(
                    titulo: 'Mis Muestras',
                    valor: _estadisticas?['laboratorios'] ?? 0,
                    icono: Icons.science,
                    color: Colors.teal,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),

                  // ✅ Encuestas (filtrado por usuario) - Si lo tienes en el backend
                  _buildStatCard(
                    titulo: 'Mis Encuestas',
                    valor: _estadisticas?['encuestas'] ?? 0,
                    icono: Icons.assignment,
                    color: Colors.pink,
                    subtitulo: 'Tus registros',
                    esFiltrado: true,
                  ),
                ],
              );
            },
          ),

          // NOTA INFORMATIVA
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Las estadísticas con ✅ muestran solo tus registros. Las marcadas con ❌ muestran totales del sistema.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
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

  // 📊 TARJETA DE ESTADÍSTICA
  Widget _buildStatCard({
    required String titulo,
    required int valor,
    required IconData icono,
    required Color color,
    required String subtitulo,
    required bool esFiltrado,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICONO CON BADGE
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: color, size: 28),
                ),
                // BADGE INDICADOR
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: esFiltrado ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esFiltrado ? Icons.check : Icons.public,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // VALOR
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            // TÍTULO
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // SUBTÍTULO
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ⏳ LOADING
  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando estadísticas...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
      child: Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar estadísticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarEstadisticas,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📭 SIN DATOS
  Widget _buildSinDatos() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay estadísticas disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
