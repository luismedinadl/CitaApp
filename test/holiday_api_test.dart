import 'package:citaapp/holiday_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('convierte la respuesta de Nager.Date en días festivos', () {
    const response = '''[
      {
        "date": "2026-09-16",
        "localName": "Día de la Independencia",
        "name": "Independence Day"
      }
    ]''';

    final holidays = NagerDateApi.parseHolidays(response);

    expect(holidays, hasLength(1));
    expect(holidays.single.date, '2026-09-16');
    expect(holidays.single.visibleName, 'Día de la Independencia');
  });

  test('rechaza una respuesta que no sea una lista JSON', () {
    expect(
      () => NagerDateApi.parseHolidays('{"error":"invalid"}'),
      throwsFormatException,
    );
  });
}
