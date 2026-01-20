// screens/findrisk/findrisk_list_screen.dart
import 'package:flutter/material.dart';
import 'package:Bornive/database/database_helper.dart';
import 'package:Bornive/services/sincronizacion_service.dart';
import '../../models/findrisk_test_model.dart';
import '../../services/findrisk_service.dart';
import 'findrisk_form_screen.dart';
import 'findrisk_detail_screen.dart';

class FindriskListScreen extends StatefulWidget {
  const FindriskListScreen({Key? key}) : super(key: key);

  @override
  State<FindriskListScreen> createState() => _FindriskListScreenState();
}

class _FindriskListScreenState extends State<FindriskListScreen> {
  List<FindriskTest> _tests = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _searchQuery = '';
  
  // 🆕 MAPA PARA CACHEAR NOMBRES DE PACIENTES
  Map<String, String> _pacientesCache = {};

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    try {
      final tests = await FindriskService.getAllTests();
      
      // 🆕 CARGAR INFORMACIÓN DE PACIENTES
      await _loadPacientesInfo(tests);
      
      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tests: $e')),
        );
      }
    }
  }

  // 🆕 MÉTODO PARA CARGAR INFORMACIÓN DE PACIENTES (SOLO NOMBRES)
  Future<void> _loadPacientesInfo(List<FindriskTest> tests) async {
    final dbHelper = DatabaseHelper.instance;
    
    for (final test in tests) {
      if (!_pacientesCache.containsKey(test.idpaciente)) {
        try {
          final paciente = await dbHelper.getPacienteById(test.idpaciente);
          if (paciente != null) {
            _pacientesCache[test.idpaciente] = '${paciente.nombre} ${paciente.apellido}';
          } else {
            _pacientesCache[test.idpaciente] = 'Paciente no encontrado';
          }
        } catch (e) {
          debugPrint('Error cargando paciente ${test.idpaciente}: $e');
          _pacientesCache[test.idpaciente] = 'Error al cargar';
        }
      }
    }
  }

  // screens/findrisk/findrisk_list_screen.dart - MÉTODO CORREGIDO
  Future<void> _sincronizarTestsPendientes() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      // Mostrar diálogo de progreso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Sincronizando tests FINDRISK pendientes...'),
              ],
            ),
          ),
        );
      }

      // 🔑 OBTENER TOKEN DEL USUARIO LOGUEADO
      final dbHelper = DatabaseHelper.instance;
      final usuario = await dbHelper.getLoggedInUser();
      
      if (usuario == null || usuario['token'] == null) {
        throw Exception('No hay usuario logueado o token no disponible');
      }
      
      final token = usuario['token'] as String;
      debugPrint('🔑 Token obtenido para sincronización FINDRISK: ${token.substring(0, 20)}...');

      // 🔄 USAR EL TOKEN REAL EN LUGAR DE CADENA VACÍA
      final resultado = await SincronizacionService.sincronizarFindriskTestsPendientes(token);

      // Cerrar diálogo de progreso
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 🆕 LIMPIAR CACHE DE PACIENTES PARA RECARGAR
      _pacientesCache.clear();
      
      // Recargar la lista
      await _loadTests();

      // Mostrar resultado
      if (mounted) {
        final exitosas = resultado['exitosas'] ?? 0;
        final fallidas = resultado['fallidas'] ?? 0;
        final total = resultado['total'] ?? 0;
        final errores = resultado['errores'] as List<String>? ?? [];

        String mensaje;
        Color color;
        IconData icono;

        if (total == 0) {
          mensaje = 'No hay tests FINDRISK pendientes de sincronizar';
          color = Colors.blue;
          icono = Icons.info;
        } else if (fallidas == 0) {
          mensaje = '✅ $exitosas tests FINDRISK sincronizados exitosamente';
          color = Colors.green;
          icono = Icons.check_circle;
        } else if (exitosas == 0) {
          mensaje = '❌ Error: $fallidas tests FINDRISK fallaron';
          color = Colors.red;
          icono = Icons.error;
        } else {
          mensaje = '⚠️ $exitosas exitosos, $fallidas fallidos de $total tests FINDRISK';
          color = Colors.orange;
          icono = Icons.warning;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icono, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(mensaje)),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 4),
            action: (fallidas > 0 && errores.isNotEmpty) ? SnackBarAction(
              label: 'Ver errores',
              textColor: Colors.white,
              onPressed: () => _mostrarErroresSincronizacion(errores),
            ) : null,
          ),
        );
      }

    } catch (e) {
      // Cerrar diálogo si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error de sincronización FINDRISK: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _mostrarErroresSincronizacion(List<String> errores) {
    if (errores.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Errores de Sincronización FINDRISK'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se encontraron ${errores.length} errores durante la sincronización:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: errores.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            errores[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // 🔧 MÉTODO ACTUALIZADO PARA FILTRO CON NOMBRE DE PACIENTE
  List<FindriskTest> get _filteredTests {
    if (_searchQuery.isEmpty) return _tests;
    return _tests.where((test) {
      final nombrePaciente = _pacientesCache[test.idpaciente] ?? '';
      
      return test.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             nombrePaciente.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests FINDRISK'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showEstadisticas,
          ),
          // 🔄 BOTÓN DE SINCRONIZACIÓN FINDRISK
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _sincronizarTestsPendientes,
            tooltip: 'Sincronizar tests FINDRISK pendientes',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar tests...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Estadísticas rápidas
          _buildQuickStats(),
          
          // Lista de tests
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTests,
                        child: ListView.builder(
                          itemCount: _filteredTests.length,
                          itemBuilder: (context, index) {
                            final test = _filteredTests[index];
                            return _buildTestCard(test);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickStats() {
    final total = _tests.length;
    final sincronizados = _tests.where((t) => t.syncStatus == 1).length;
    final pendientes = total - sincronizados;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total.toString(), Colors.blue),
          _buildStatItem('Sincronizados', sincronizados.toString(), Colors.green),
          _buildStatItem('Pendientes', pendientes.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 🔧 MÉTODO ACTUALIZADO PARA MOSTRAR SOLO NOMBRE DEL PACIENTE
  Widget _buildTestCard(FindriskTest test) {
    final interpretacion = test.interpretarRiesgo();
    final color = Color(interpretacion['color']);

    // 🔧 OBTENER NOMBRE DEL PACIENTE DESDE EL CACHE
    final nombrePaciente = _pacientesCache[test.idpaciente] ?? 'Cargando...';

    // 🔧 VALIDACIÓN SEGURA DE SUBSTRING PARA EVITAR ERRORES
    String getDisplayId(String id, int maxLength) {
      if (id.length <= maxLength) {
        return id;
      }
      return '${id.substring(0, maxLength)}...';
    }

    final displayTestId = getDisplayId(test.id, 12);
    final displayNombrePaciente = nombrePaciente.length > 30 
        ? '${nombrePaciente.substring(0, 30)}...' 
        : nombrePaciente;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            test.puntajeFinal.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Test $displayTestId',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🆕 MOSTRAR SOLO NOMBRE DEL PACIENTE
            Text(
              'Paciente: $displayNombrePaciente',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              'Riesgo: ${interpretacion['nivel']} (${interpretacion['riesgo']})',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Creado: ${_formatDate(test.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (test.syncStatus == 0)
              Icon(Icons.sync_problem, color: Colors.orange[600], size: 20),
            if (test.syncStatus == 1)
              Icon(Icons.cloud_done, color: Colors.green[600], size: 20),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _navigateToDetail(test),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tests FINDRISK',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para crear el primer test',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // 🔧 ACTUALIZAR NAVEGACIÓN PARA RECARGAR CACHE
  void _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindriskFormScreen(),
      ),
    );
    
    if (result == true) {
      // 🆕 LIMPIAR CACHE PARA RECARGAR
      _pacientesCache.clear();
      _loadTests();
    }
  }

  void _navigateToDetail(FindriskTest test) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FindriskDetailScreen(test: test),
      ),
    );
    
    if (result == true) {
      // 🆕 LIMPIAR CACHE PARA RECARGAR
      _pacientesCache.clear();
      _loadTests();
    }
  }

  void _showEstadisticas() async {
    final estadisticas = await FindriskService.getEstadisticas();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas FINDRISK'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEstadisticaItem('Total de tests', estadisticas['total_tests']?.toString() ?? '0'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildEstadisticaItem('Riesgo bajo', estadisticas['riesgo_bajo']?.toString() ?? '0', Colors.green),
            _buildEstadisticaItem('Riesgo ligeramente elevado', estadisticas['riesgo_ligeramente_elevado']?.toString() ?? '0', Colors.yellow[700]!),
            _buildEstadisticaItem('Riesgo moderado', estadisticas['riesgo_moderado']?.toString() ?? '0', Colors.orange),
            _buildEstadisticaItem('Riesgo alto', estadisticas['riesgo_alto']?.toString() ?? '0', Colors.red),
            _buildEstadisticaItem('Riesgo muy alto', estadisticas['riesgo_muy_alto']?.toString() ?? '0', Colors.purple),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color?.withOpacity(0.1) ?? Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color?.withOpacity(0.3) ?? Colors.grey[300]!,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
