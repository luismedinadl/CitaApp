import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
}

class Service {
  final int id;
  final String name;
  final int duration;
  final double price;
  Service(this.id, this.name, this.duration, this.price);
  factory Service.fromJson(Map<String, dynamic> json) => Service(
      json['id'] as int, json['name'] as String, json['duration'] as int,
      (json['price'] as num).toDouble());
}

class Appointment {
  final int id;
  final String service, date, time, client, status;
  Appointment(this.id, this.service, this.date, this.time, this.client, this.status);
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
      json['id'] as int, json['service'] as String, json['date'] as String,
      json['time'] as String, json['client'] as String, json['status'] as String);
}

class Api {
  // Para Android emulador: 10.0.2.2. Para Chrome o navegador: 127.0.0.1.
  final String baseUrl;
  String? token;
  Api(this.baseUrl);

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamed);
      dynamic data;
      try { data = jsonDecode(utf8.decode(response.bodyBytes)); } catch (_) {
        throw ApiError('La respuesta del servidor no es válida.');
      }
      if (response.statusCode >= 400) {
        final fallback = response.statusCode == 401 ? 'Inicia sesión nuevamente.' :
          response.statusCode == 403 ? 'No tienes permiso para esta acción.' :
          response.statusCode == 404 ? 'No se encontró la información.' :
          response.statusCode >= 500 ? 'El servidor tiene un problema.' : 'Revisa los datos.';
        throw ApiError(data is Map && data['error'] is String ? data['error'] as String : fallback);
      }
      return data;
    } on TimeoutException { throw ApiError('El servidor tardó demasiado.');
    } on http.ClientException { throw ApiError('No hay conexión con el servidor.'); }
  }

  Future<Map<String, dynamic>> login(String email, String password, {bool register = false, String name = ''}) async {
    final result = await _request('POST', register ? '/register' : '/login',
        body: {'email': email, 'password': password, 'name': name});
    token = result['token'] as String;
    return Map<String, dynamic>.from(result['user'] as Map);
  }
  Future<List<Service>> services() async {
    final result = await _request('GET', '/services') as Map;
    return (result['data'] as List).map((e) => Service.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
  Future<List<String>> slots(int serviceId, String date) async {
    final result = await _request('GET', '/slots?service_id=$serviceId&date=$date') as Map;
    return (result['data'] as List).cast<String>();
  }
  Future<void> reserve(int serviceId, String date, String time) =>
      _request('POST', '/appointments', body: {'service_id': serviceId, 'date': date, 'time': time});
  Future<List<Appointment>> appointments({bool admin = false}) async {
    final result = await _request('GET', admin ? '/admin/appointments' : '/appointments') as Map;
    return (result['data'] as List).map((e) => Appointment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
  Future<void> cancel(int id) => _request('POST', '/appointments/$id/cancel');
  Future<void> addService(String name, int duration, double price) =>
      _request('POST', '/admin/services', body: {'name': name, 'duration': duration, 'price': price});
  Future<void> schedule(String start, String end) =>
      _request('POST', '/admin/schedule', body: {'start': start, 'end': end});
}
