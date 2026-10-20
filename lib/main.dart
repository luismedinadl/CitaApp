import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api.dart';

void main() {
  const value = String.fromEnvironment('API_URL');
  final url = value.isNotEmpty ? value :
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8080/api' : 'http://127.0.0.1:8080/api');
  runApp(CitaApp(api: Api(url)));
}

class CitaApp extends StatefulWidget {
  final Api api;
  const CitaApp({super.key, required this.api});
  @override State<CitaApp> createState() => _CitaAppState();
}

class _CitaAppState extends State<CitaApp> {
  Map<String, dynamic>? user;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CitaApp', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
    home: user == null ? LoginPage(api: widget.api, onLogin: (u) => setState(() => user = u))
        : HomePage(api: widget.api, user: user!, onLogout: () => setState(() => user = null)),
  );
}

String errorText(Object error) => error is ApiError ? error.message : 'Ocurrió un error. Intenta nuevamente.';
void snack(BuildContext c, String text) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class LoginPage extends StatefulWidget {
  final Api api;
  final ValueChanged<Map<String, dynamic>> onLogin;
  const LoginPage({super.key, required this.api, required this.onLogin});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false, loading = false;
  String? error;
  @override void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    setState(() { loading = true; error = null; });
    try {
      final user = await widget.api.login(email.text.trim(), password.text,
          register: register, name: name.text.trim());
      if (mounted) widget.onLogin(user);
    } catch (e) { if (mounted) setState(() => error = errorText(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CitaApp')),
    body: Center(child: SizedBox(width: 380, child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
      Text(register ? 'Crear cuenta' : 'Iniciar sesión', style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 20),
      if (register) field(name, 'Nombre'),
      field(email, 'Correo electrónico'), field(password, 'Contraseña', password: true),
      if (register) const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('La contraseña debe tener al menos 10 caracteres.')),
      if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      FilledButton(onPressed: loading ? null : submit, child: Text(loading ? 'Conectando...' : register ? 'Registrarme' : 'Entrar')),
      TextButton(onPressed: loading ? null : () => setState(() { register = !register; error = null; }),
          child: Text(register ? 'Ya tengo cuenta' : 'Crear una cuenta')),
    ]))),
  );
}

Widget field(TextEditingController controller, String label, {bool password = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: TextField(controller: controller, obscureText: password, decoration: InputDecoration(labelText: label)),
);

class HomePage extends StatefulWidget {
  final Api api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  const HomePage({super.key, required this.api, required this.user, required this.onLogout});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loading = true;
  String? error;
  List<Service> services = [];
  List<Appointment> appointments = [];
  bool get admin => widget.user['role'] == 'admin';
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      if (tab == 0) services = await widget.api.services();
      if (tab == 1) appointments = await widget.api.appointments(admin: admin);
    } catch (e) { error = errorText(e); }
    if (mounted) setState(() => loading = false);
  }
  Future<void> reserve(Service service) async {
    final done = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => BookingPage(api: widget.api, service: service)));
    if (done == true && mounted) { setState(() => tab = 1); load(); }
  }
  Future<void> cancel(Appointment appointment) async {
    final answer = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('¿Cancelar cita?'), content: Text('${appointment.service}\n${appointment.date} ${appointment.time}'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, cancelar'))],
    ));
    if (answer == true) {
      try { await widget.api.cancel(appointment.id); if (mounted) { snack(context, 'Cita cancelada.'); load(); } }
      catch (e) { if (mounted) snack(context, errorText(e)); }
    }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(admin ? 'CitaApp - Administrador' : 'CitaApp'), actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
        IconButton(onPressed: () { widget.api.token = null; widget.onLogout(); }, icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión'),
      ]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (value) { setState(() => tab = value); load(); }, destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Servicios'),
        NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), label: admin ? 'Agenda' : 'Mis citas'),
        if (admin) const NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Negocio'),
      ]),
      body: Center(child: SizedBox(width: 650, child: loading ? const Center(child: CircularProgressIndicator()) :
        error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), TextButton(onPressed: load, child: const Text('Reintentar'))])) :
        ListView(padding: const EdgeInsets.all(20), children: tab == 0 ? serviceView() : tab == 1 ? appointmentView() : adminView()))),
    );
  }
  List<Widget> serviceView() => [
    Text('Hola, ${widget.user['name']}', style: const TextStyle(fontSize: 25)),
    const SizedBox(height: 8), const Text('Elige un servicio y reserva tu horario.'), const SizedBox(height: 20),
    if (services.isEmpty) const Text('No hay servicios disponibles.'),
    ...services.map((s) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.name, style: const TextStyle(fontSize: 20)), Text('${s.duration} minutos - \$${s.price.toStringAsFixed(0)} MXN'),
      if (!admin) Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => reserve(s), child: const Text('Reservar'))),
    ])))),
  ];
  List<Widget> appointmentView() => [
    Text(admin ? 'Agenda del negocio' : 'Mis citas', style: const TextStyle(fontSize: 25)), const SizedBox(height: 16),
    if (appointments.isEmpty) const Text('No hay citas registradas.'),
    ...appointments.map((a) => Card(child: ListTile(
      title: Text(a.service), subtitle: Text('${a.date} - ${a.time}${admin ? '\nCliente: ${a.client}' : ''}\nEstado: ${a.status}'),
      isThreeLine: admin, trailing: !admin && a.status == 'confirmada' ? TextButton(onPressed: () => cancel(a), child: const Text('Cancelar')) : null,
    ))),
  ];
  List<Widget> adminView() => [
    const Text('Administración', style: TextStyle(fontSize: 25)), const SizedBox(height: 10),
    const Text('Agrega servicios o cambia el horario. Estas acciones solo están disponibles para el administrador.'),
    const SizedBox(height: 16),
    FilledButton(onPressed: () => showServiceDialog(), child: const Text('Agregar servicio')),
    const SizedBox(height: 10),
    OutlinedButton(onPressed: () => showScheduleDialog(), child: const Text('Cambiar horario')),
  ];
  Future<void> showServiceDialog() async {
    final name = TextEditingController(), duration = TextEditingController(text: '30'), price = TextEditingController();
    final save = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Nuevo servicio'), content: Column(mainAxisSize: MainAxisSize.min, children: [field(name, 'Nombre'), field(duration, 'Duración: 30, 60, 90 o 120'), field(price, 'Precio')]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar'))]));
    if (save == true) { try { await widget.api.addService(name.text, int.tryParse(duration.text) ?? 0, double.tryParse(price.text) ?? -1); if (mounted) snack(context, 'Servicio agregado.'); } catch (e) { if (mounted) snack(context, errorText(e)); } }
    name.dispose(); duration.dispose(); price.dispose();
  }
  Future<void> showScheduleDialog() async {
    final start = TextEditingController(text: '09:00'), end = TextEditingController(text: '18:00');
    final save = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Horario del negocio'), content: Column(mainAxisSize: MainAxisSize.min, children: [field(start, 'Apertura HH:mm'), field(end, 'Cierre HH:mm')]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar'))]));
    if (save == true) { try { await widget.api.schedule(start.text, end.text); if (mounted) snack(context, 'Horario guardado.'); } catch (e) { if (mounted) snack(context, errorText(e)); } }
    start.dispose(); end.dispose();
  }
}

class BookingPage extends StatefulWidget {
  final Api api;
  final Service service;
  const BookingPage({super.key, required this.api, required this.service});
  @override State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime selected = DateTime.now();
  List<String> slots = [];
  String? time, error;
  bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { setState(() { loading = true; time = null; error = null; }); try { slots = await widget.api.slots(widget.service.id, ymd(selected)); } catch (e) { error = errorText(e); } if (mounted) setState(() => loading = false); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.service.name)), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Elige fecha y horario', style: TextStyle(fontSize: 24)),
    OutlinedButton(onPressed: () async { final date = await showDatePicker(context: context, initialDate: selected, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90))); if (date != null) { selected = date; load(); } }, child: Text(ymd(selected))),
    if (loading) const Center(child: CircularProgressIndicator()) else if (error != null) ...[Text(error!), TextButton(onPressed: load, child: const Text('Reintentar'))] else ...[
      if (slots.isEmpty) const Text('No hay horarios disponibles en esta fecha.'),
      Wrap(spacing: 8, children: slots.map((s) => ChoiceChip(label: Text(s), selected: time == s, onSelected: (_) => setState(() => time = s))).toList()),
      const SizedBox(height: 20),
      FilledButton(onPressed: time == null ? null : () async { try { await widget.api.reserve(widget.service.id, ymd(selected), time!); if (mounted) { snack(context, 'Cita reservada.'); Navigator.pop(context, true); } } catch (e) { if (mounted) { snack(context, '${errorText(e)} Revisa Mis citas antes de intentarlo otra vez.'); load(); } } }, child: const Text('Reservar cita')),
    ]
  ]));
}
