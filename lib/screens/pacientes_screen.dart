import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../models/paciente_model.dart';
import '../api/api_service.dart';



class PacientesScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const PacientesScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  _PacientesScreenState createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  @override
  void initState() {
    super.initState();
    _loadPacientes();
  }

  Future<void> _loadPacientes() async {
    await Provider.of<PacienteProvider>(context, listen: false).loadPacientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadPacientes,
          ),
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLogout();
                      },
                      child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PacienteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.pacientes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pacientes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.people, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay pacientes registrados'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddPacienteDialog(context),
                    child: const Text('Agregar Paciente'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPacientes,
            child: ListView.builder(
              itemCount: provider.pacientes.length,
              itemBuilder: (context, index) {
                final paciente = provider.pacientes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(paciente.nombre[0] + paciente.apellido[0]),
                    ),
                    title: Text(paciente.nombreCompleto),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paciente.infoBasica),
                        if (paciente.nombreSede != null) 
                          Text('Sede: ${paciente.nombreSede}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Iconsax.edit, size: 20),
                          onPressed: () => _showEditPacienteDialog(context, paciente),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                          onPressed: () => _deletePaciente(context, paciente.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Iconsax.add),
        onPressed: () => _showAddPacienteDialog(context),
      ),
    );
  }

  void _showAddPacienteDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final identificacionController = TextEditingController();
  DateTime? fechaNacimiento;
  String genero = 'Masculino';
  String? sedeSeleccionada;
  bool isSaving = false;

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  List<dynamic> sedes = [];

  try {
    sedes = await ApiService.getSedes(authProvider.token!);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cargar sedes: $e')),
    );
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Agregar Paciente'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: apellidoController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: identificacionController,
                      decoration: const InputDecoration(labelText: 'Identificación'),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: genero,
                      items: ['Masculino', 'Femenino', 'Otro']
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => genero = value!),
                      decoration: const InputDecoration(labelText: 'Género'),
                    ),
                    DropdownButtonFormField<String>(
                      value: sedeSeleccionada,
                      items: sedes.map<DropdownMenuItem<String>>((sede) {
                        return DropdownMenuItem<String>(
                          value: sede['id'],
                          child: Text(sede['nombresede'] ?? 'Sede sin nombre'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => sedeSeleccionada = value),
                      decoration: const InputDecoration(labelText: 'Sede'),
                      validator: (value) => value == null ? 'Seleccione una sede' : null,
                    ),
                    ListTile(
                      title: const Text('Fecha de Nacimiento'),
                      subtitle: Text(
                        fechaNacimiento == null
                            ? 'Seleccionar fecha'
                            : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                      ),
                      trailing: const Icon(Iconsax.calendar),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() => fechaNacimiento = selectedDate);
                        }
                      },
                    ),
                    if (isSaving) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate() && 
                            fechaNacimiento != null && 
                            sedeSeleccionada != null) {
                          setState(() => isSaving = true);

                          final nuevoPaciente = Paciente(
                            id: '', // El backend generará el ID
                            identificacion: identificacionController.text,
                            fecnacimiento: fechaNacimiento!,
                            nombre: nombreController.text,
                            apellido: apellidoController.text,
                            genero: genero,
                            idsede: sedeSeleccionada!,
                          );

                          try {
                            await Provider.of<PacienteProvider>(context, listen: false)
                                .addPaciente(nuevoPaciente);
                            Navigator.pop(context);
                            _loadPacientes(); // Recargar la lista
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al guardar: $e')),
                            );
                          } finally {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showEditPacienteDialog(BuildContext context, Paciente paciente) {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController(text: paciente.nombre);
  final apellidoController = TextEditingController(text: paciente.apellido);
  final identificacionController = TextEditingController(text: paciente.identificacion);
  DateTime fechaNacimiento = paciente.fecnacimiento;
  String genero = paciente.genero;
  String? sedeSeleccionada = paciente.idsede;
  bool isSaving = false;

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  List<dynamic> sedes = [];

  // Cargar sedes
  ApiService.getSedes(authProvider.token!).then((value) => sedes = value);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Paciente'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: apellidoController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: identificacionController,
                      decoration: const InputDecoration(labelText: 'Identificación'),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: genero,
                      items: ['Masculino', 'Femenino', 'Otro']
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => genero = value!),
                      decoration: const InputDecoration(labelText: 'Género'),
                    ),
                    DropdownButtonFormField<String>(
                      value: sedeSeleccionada,
                      items: sedes.map<DropdownMenuItem<String>>((sede) {
                        return DropdownMenuItem<String>(
                          value: sede['id'],
                          child: Text(sede['nombresede'] ?? 'Sede sin nombre'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => sedeSeleccionada = value),
                      decoration: const InputDecoration(labelText: 'Sede'),
                    ),
                    ListTile(
                      title: const Text('Fecha de Nacimiento'),
                      subtitle: Text(
                        '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}',
                      ),
                      trailing: const Icon(Iconsax.calendar),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: fechaNacimiento,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() => fechaNacimiento = selectedDate);
                        }
                      },
                    ),
                    if (isSaving) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate() && sedeSeleccionada != null) {
                          setState(() => isSaving = true);

                          final pacienteActualizado = Paciente(
                            id: paciente.id,
                            identificacion: identificacionController.text,
                            fecnacimiento: fechaNacimiento,
                            nombre: nombreController.text,
                            apellido: apellidoController.text,
                            genero: genero,
                            longitud: paciente.longitud,
                            latitud: paciente.latitud,
                            idsede: sedeSeleccionada!,
                          );

                          try {
                            await Provider.of<PacienteProvider>(context, listen: false)
                                .updatePaciente(pacienteActualizado);
                            Navigator.pop(context);
                            _loadPacientes(); // Recargar la lista
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al actualizar: $e')),
                            );
                          } finally {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                child: const Text('Actualizar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _deletePaciente(BuildContext context, String id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar'),
      content: const Text('¿Estás seguro de que deseas eliminar este paciente?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await Provider.of<PacienteProvider>(context, listen: false)
          .deletePaciente(id);
      _loadPacientes(); // Recargar la lista después de eliminar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }
}}