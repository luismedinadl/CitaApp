import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(CitaApp(api: Api()));
}

class CitaApp extends StatelessWidget {
  final Api api;
  const CitaApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CitaApp',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: StreamBuilder<User?>(
      stream: api.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        return user == null
            ? LoginPage(api: api)
            : HomePage(api: api, user: api.userData(user));
      },
    ),
  );
}

String errorText(Object error) =>
    error is ApiError ? error.message : 'Ocurrió un error. Intenta nuevamente.';

void snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String ymd(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class LoginPage extends StatefulWidget {
  final Api api;
  const LoginPage({super.key, required this.api});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.login(
        email.text.trim(),
        password.text,
        register: register,
        name: name.text.trim(),
      );
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.loginWithGoogle();
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CitaApp')),
    body: Center(
      child: SizedBox(
        width: 380,
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            Text(
              register ? 'Crear cuenta' : 'Iniciar sesión',
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(height: 20),
            if (register) field(name, 'Nombre'),
            field(email, 'Correo electrónico'),
            field(password, 'Contraseña', password: true),
            if (register)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('La contraseña debe tener al menos 6 caracteres.'),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: loading ? null : submit,
              child: Text(
                loading
                    ? 'Conectando...'
                    : register
                    ? 'Registrarme'
                    : 'Entrar',
              ),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () => setState(() {
                      register = !register;
                      error = null;
                    }),
              child: Text(register ? 'Ya tengo cuenta' : 'Crear una cuenta'),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: loading ? null : loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Continuar con Google'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget field(
  TextEditingController controller,
  String label, {
  bool password = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: TextField(
    controller: controller,
    obscureText: password,
    decoration: InputDecoration(labelText: label),
  ),
);

class HomePage extends StatefulWidget {
  final Api api;
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.api, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loading = true;
  String? error;
  List<Service> services = [];
  List<Appointment> appointments = [];

  bool get admin => widget.user['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (tab == 0) services = await widget.api.services();
      if (tab == 1) appointments = await widget.api.appointments(admin: admin);
    } catch (e) {
      error = errorText(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> reserve(Service service) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(api: widget.api, service: service),
      ),
    );
    if (done == true && mounted) {
      setState(() => tab = 1);
      load();
    }
  }

  Future<void> cancel(Appointment appointment) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar cita?'),
        content: Text(
          '${appointment.service}\n${appointment.date} ${appointment.time}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (answer == true) {
      try {
        await widget.api.cancel(appointment.id);
        if (mounted) {
          snack(context, 'Cita cancelada.');
          load();
        }
      } catch (e) {
        if (mounted) snack(context, errorText(e));
      }
    }
  }

  Future<void> deleteService(Service service) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar servicio?'),
        content: Text(
          'Se eliminará "${service.name}". Las citas ya creadas no se borrarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (answer == true) {
      try {
        await widget.api.deleteService(service.id);
        if (mounted) {
          snack(context, 'Servicio eliminado.');
          load();
        }
      } catch (e) {
        if (mounted) snack(context, errorText(e));
      }
    }
  }

  Future<void> moveService(Service service, int direction) async {
    try {
      await widget.api.moveService(service.id, direction);
      if (mounted) await load();
    } catch (e) {
      if (mounted) snack(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: 'Servicios',
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_month_outlined),
        label: admin ? 'Agenda' : 'Mis citas',
      ),
      if (admin)
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Negocio',
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(admin ? 'CitaApp - Administrador' : 'CitaApp'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: widget.api.logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() => tab = value);
          load();
        },
        destinations: destinations,
      ),
      body: Center(
        child: SizedBox(
          width: 650,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: tab == 0
                      ? serviceView()
                      : tab == 1
                      ? appointmentView()
                      : adminView(),
                ),
        ),
      ),
    );
  }

  List<Widget> serviceView() => [
    Text('Hola, ${widget.user['name']}', style: const TextStyle(fontSize: 25)),
    const SizedBox(height: 8),
    const Text('Elige un servicio y reserva tu horario.'),
    const SizedBox(height: 20),
    if (services.isEmpty)
      const Text(
        'No hay servicios disponibles. El administrador debe agregarlos.',
      ),
    ...services.asMap().entries.map((entry) {
      final index = entry.key;
      final service = entry.value;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service.name, style: const TextStyle(fontSize: 20)),
              Text(
                '${service.duration} minutos - \$${service.price.toStringAsFixed(0)} MXN',
              ),
              if (!admin)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => reserve(service),
                    child: const Text('Reservar'),
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  children: [
                    IconButton(
                      onPressed: index == 0
                          ? null
                          : () => moveService(service, -1),
                      tooltip: 'Subir servicio',
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      onPressed: index == services.length - 1
                          ? null
                          : () => moveService(service, 1),
                      tooltip: 'Bajar servicio',
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => deleteService(service),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }),
  ];

  List<Widget> appointmentView() => [
    Text(
      admin ? 'Agenda del negocio' : 'Mis citas',
      style: const TextStyle(fontSize: 25),
    ),
    const SizedBox(height: 16),
    if (appointments.isEmpty) const Text('No hay citas registradas.'),
    ...appointments.map(
      (appointment) => Card(
        child: ListTile(
          title: Text(appointment.service),
          subtitle: Text(
            '${appointment.date} - ${appointment.time}'
            '${admin ? '\nCliente: ${appointment.client}' : ''}'
            '\nEstado: ${appointment.status}',
          ),
          isThreeLine: admin,
          trailing: !admin && appointment.status == 'confirmada'
              ? TextButton(
                  onPressed: () => cancel(appointment),
                  child: const Text('Cancelar'),
                )
              : null,
        ),
      ),
    ),
  ];

  List<Widget> adminView() => [
    const Text('Administración', style: TextStyle(fontSize: 25)),
    const SizedBox(height: 10),
    const Text('Agrega servicios o cambia el horario del negocio.'),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: showServiceDialog,
      child: const Text('Agregar servicio'),
    ),
    const SizedBox(height: 10),
    OutlinedButton(
      onPressed: showScheduleDialog,
      child: const Text('Cambiar horario'),
    ),
  ];

  Future<void> showServiceDialog() async {
    final name = TextEditingController();
    final duration = TextEditingController(text: '30');
    final price = TextEditingController();
    final details = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo servicio'),
        // Hace que los campos se desplacen sin tapar Guardar con el teclado.
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(name, 'Nombre'),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración: 30, 60, 90 o 120',
                ),
              ),
            ),
            TextField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(dialogContext).unfocus(),
              decoration: const InputDecoration(labelText: 'Precio'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // El toque guarda aun cuando el teclado siga abierto.
              FocusScope.of(dialogContext).unfocus();
              Navigator.pop(dialogContext, {
                'name': name.text,
                'duration': duration.text,
                'price': price.text,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (details != null) {
      try {
        await widget.api.addService(
          details['name'] ?? '',
          int.tryParse(details['duration'] ?? '') ?? 0,
          double.tryParse(details['price'] ?? '') ?? -1,
        );
        if (mounted) snack(context, 'Servicio agregado.');
      } catch (e) {
        if (mounted) snack(context, errorText(e));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      name.dispose();
      duration.dispose();
      price.dispose();
    }
  }

  Future<void> showScheduleDialog() async {
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '18:00');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horario del negocio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(start, 'Apertura HH:mm'),
            field(end, 'Cierre HH:mm'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (save == true) {
      try {
        await widget.api.schedule(start.text, end.text);
        if (mounted) snack(context, 'Horario guardado.');
      } catch (e) {
        if (mounted) snack(context, errorText(e));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      start.dispose();
      end.dispose();
    });
  }
}

class BookingPage extends StatefulWidget {
  final Api api;
  final Service service;
  const BookingPage({super.key, required this.api, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime selected = DateTime.now();
  List<String> slots = [];
  String? time;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      time = null;
      error = null;
    });
    try {
      slots = await widget.api.slots(widget.service, ymd(selected));
    } catch (e) {
      error = errorText(e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.service.name)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Elige fecha y horario', style: TextStyle(fontSize: 24)),
        OutlinedButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selected,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) {
              selected = date;
              load();
            }
          },
          child: Text(ymd(selected)),
        ),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null) ...[
          Text(error!),
          TextButton(onPressed: load, child: const Text('Reintentar')),
        ] else ...[
          if (slots.isEmpty)
            const Text('No hay horarios disponibles en esta fecha.'),
          Wrap(
            spacing: 8,
            children: slots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(slot),
                    selected: time == slot,
                    onSelected: (_) => setState(() => time = slot),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: time == null
                ? null
                : () async {
                    try {
                      await widget.api.reserve(
                        widget.service,
                        ymd(selected),
                        time!,
                      );
                      if (mounted) {
                        snack(context, 'Cita reservada.');
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (mounted) {
                        snack(context, errorText(e));
                        load();
                      }
                    }
                  },
            child: const Text('Reservar cita'),
          ),
        ],
      ],
    ),
  );
}
