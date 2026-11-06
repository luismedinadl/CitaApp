import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Día festivo obtenido desde la API pública Nager.Date.
class Holiday {
  final String date;
  final String name;
  final String localName;

  const Holiday({
    required this.date,
    required this.name,
    required this.localName,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['date'] as String? ?? '',
      name: json['name'] as String? ?? 'Día festivo',
      localName: json['localName'] as String? ?? '',
    );
  }

  String get visibleName => localName.isEmpty ? name : localName;
}

class HolidayApiException implements Exception {
  final String message;
  const HolidayApiException(this.message);
}

/// Consulta los días festivos nacionales de México una vez por año y conserva
/// el resultado durante la sesión para evitar solicitudes repetidas.
class NagerDateApi {
  static const _baseUrl = 'https://date.nager.at/api/v3/PublicHolidays';

  final http.Client _client;
  final Duration _timeout;
  final Map<int, List<Holiday>> _cache = {};

  NagerDateApi({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 8);

  Future<Holiday?> holidayOn(String isoDate) async {
    final date = DateTime.tryParse(isoDate);
    if (date == null) {
      throw const HolidayApiException('La fecha seleccionada no es válida.');
    }
    final holidays = await _holidaysForYear(date.year);
    for (final holiday in holidays) {
      if (holiday.date == isoDate) return holiday;
    }
    return null;
  }

  Future<List<Holiday>> _holidaysForYear(int year) async {
    final cached = _cache[year];
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/$year/MX');
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw const HolidayApiException(
          'No se pudieron consultar los feriados. Intenta nuevamente.',
        );
      }
      final holidays = parseHolidays(response.body);
      _cache[year] = holidays;
      return holidays;
    } on TimeoutException {
      throw const HolidayApiException(
        'La consulta de feriados tardó demasiado. Intenta nuevamente.',
      );
    } on http.ClientException {
      throw const HolidayApiException(
        'No se pudo conectar con el servicio de feriados.',
      );
    } on FormatException {
      throw const HolidayApiException(
        'El servicio de feriados respondió con información no válida.',
      );
    }
  }

  static List<Holiday> parseHolidays(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('La respuesta no contiene una lista.');
    }
    return decoded
        .whereType<Map>()
        .map((item) => Holiday.fromJson(Map<String, dynamic>.from(item)))
        .where((holiday) => holiday.date.isNotEmpty)
        .toList();
  }
}
