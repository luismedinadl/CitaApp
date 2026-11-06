import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'holiday_api.dart';

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
}

class Service {
  final String id;
  final String name;
  final int duration;
  final double price;
  final int order;

  Service(this.id, this.name, this.duration, this.price, this.order);

  factory Service.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Service(
      doc.id,
      data['name'] as String? ?? 'Servicio',
      (data['duration'] as num?)?.toInt() ?? 30,
      (data['price'] as num?)?.toDouble() ?? 0,
      (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class Appointment {
  final String id;
  final String service;
  final String date;
  final String time;
  final String client;
  final String status;

  Appointment(
    this.id,
    this.service,
    this.date,
    this.time,
    this.client,
    this.status,
  );

  factory Appointment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Appointment(
      doc.id,
      data['service'] as String? ?? 'Servicio',
      data['date'] as String? ?? '',
      data['time'] as String? ?? '',
      data['client'] as String? ?? '',
      data['status'] as String? ?? 'confirmada',
    );
  }
}

class SlotsResult {
  final List<String> slots;
  final Holiday? holiday;

  const SlotsResult(this.slots, {this.holiday});
}

/// Conserva el nombre Api para que la interfaz siga siendo sencilla. Ahora
/// guarda los datos directamente en Firebase, sin depender de un servidor local.
class Api {
  static const adminEmail = 'admin@citaapp.com';
  static const _googleWebClientId =
      '372221592179-kk7ol73nf6b92jpnnhg1f0f9nldskeph.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NagerDateApi _holidays = NagerDateApi();
  bool _googleReady = false;

  Stream<User?> get authChanges => _auth.authStateChanges();

  Map<String, dynamic> userData(User user) {
    final email = user.email ?? '';
    final visibleName = user.displayName?.trim();
    return {
      'name': (visibleName == null || visibleName.isEmpty)
          ? (email.isEmpty ? 'Usuario' : email.split('@').first)
          : visibleName,
      'email': email,
      'role': email.toLowerCase() == adminEmail ? 'admin' : 'client',
    };
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool register = false,
    String name = '',
  }) async {
    try {
      final credential = register
          ? await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
          : await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
      final user = credential.user;
      if (user == null) throw ApiError('No se pudo iniciar sesión.');
      if (register && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
        await user.reload();
      }
      return userData(_auth.currentUser ?? user);
    } on FirebaseAuthException catch (e) {
      throw ApiError(_authMessage(e));
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        if (!_googleReady) {
          await GoogleSignIn.instance.initialize(
            serverClientId: _googleWebClientId,
          );
          _googleReady = true;
        }
        final account = await GoogleSignIn.instance.authenticate();
        final googleCredential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken,
        );
        credential = await _auth.signInWithCredential(googleCredential);
      }
      final user = credential.user;
      if (user == null) throw ApiError('Google no devolvió una cuenta.');
      return userData(user);
    } on FirebaseAuthException catch (e) {
      throw ApiError(_authMessage(e));
    } catch (_) {
      throw ApiError(
        'No se pudo iniciar sesión con Google. Intenta nuevamente.',
      );
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<List<Service>> services() async {
    final result = await _db.collection('services').get();
    final list = result.docs.map(Service.fromDocument).toList();
    list.sort(
      (a, b) => a.order == b.order
          ? a.name.compareTo(b.name)
          : a.order.compareTo(b.order),
    );
    return list;
  }

  Future<SlotsResult> slots(Service service, String date) async {
    try {
      final holiday = await _holidays.holidayOn(date);
      if (holiday != null) return SlotsResult(const [], holiday: holiday);
    } on HolidayApiException catch (error) {
      throw ApiError(error.message);
    }
    final business = await _db.collection('settings').doc('business').get();
    final data = business.data() ?? {};
    final start = data['start'] as String? ?? '09:00';
    final end = data['end'] as String? ?? '18:00';
    final availability = await _db
        .collection('availability')
        .where('date', isEqualTo: date)
        .get();
    final occupied = availability.docs
        .map(
          (doc) => _Range(
            _minutes(doc.data()['time'] as String? ?? '00:00'),
            (doc.data()['duration'] as num?)?.toInt() ?? 30,
          ),
        )
        .toList();
    final available = <String>[];
    final opening = _minutes(start);
    final closing = _minutes(end);
    for (
      var minute = opening;
      minute + service.duration <= closing;
      minute += 30
    ) {
      final overlaps = occupied.any(
        (item) =>
            minute < item.start + item.duration &&
            minute + service.duration > item.start,
      );
      if (!overlaps) available.add(_clock(minute));
    }
    return SlotsResult(available);
  }

  Future<void> reserve(Service service, String date, String time) async {
    final user = _auth.currentUser;
    if (user == null) throw ApiError('Inicia sesión nuevamente.');
    final currentSlots = await slots(service, date);
    if (currentSlots.holiday != null) {
      throw ApiError(
        'No se pueden reservar citas en ${currentSlots.holiday!.visibleName}.',
      );
    }
    if (!currentSlots.slots.contains(time))
      throw ApiError('Ese horario ya no está disponible.');
    final profile = userData(user);
    final appointment = _db.collection('appointments').doc();
    final availability = _db.collection('availability').doc();
    final batch = _db.batch();
    batch.set(appointment, {
      'userId': user.uid,
      'serviceId': service.id,
      'service': service.name,
      'duration': service.duration,
      'date': date,
      'time': time,
      'client': profile['name'],
      'clientEmail': profile['email'],
      'status': 'confirmada',
      'availabilityId': availability.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(availability, {
      'userId': user.uid,
      'date': date,
      'time': time,
      'duration': service.duration,
    });
    await batch.commit();
  }

  Future<List<Appointment>> appointments({bool admin = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw ApiError('Inicia sesión nuevamente.');
    Query<Map<String, dynamic>> query = _db.collection('appointments');
    if (!admin) query = query.where('userId', isEqualTo: user.uid);
    final result = await query.get();
    final list = result.docs.map(Appointment.fromDocument).toList();
    list.sort((a, b) => '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'));
    return list;
  }

  Future<void> cancel(String id) async {
    final appointment = _db.collection('appointments').doc(id);
    final data = (await appointment.get()).data();
    final availabilityId = data?['availabilityId'] as String?;
    final batch = _db.batch();
    batch.update(appointment, {'status': 'cancelada'});
    if (availabilityId != null)
      batch.delete(_db.collection('availability').doc(availabilityId));
    await batch.commit();
  }

  Future<void> addService(String name, int duration, double price) async {
    if (name.trim().isEmpty ||
        ![30, 60, 90, 120].contains(duration) ||
        price < 0) {
      throw ApiError('Revisa el nombre, la duración y el precio.');
    }
    final currentServices = await services();
    final nextOrder = currentServices.isEmpty
        ? 1
        : currentServices
                  .map((service) => service.order)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    await _db.collection('services').add({
      'name': name.trim(),
      'duration': duration,
      'price': price,
      'order': nextOrder,
    });
  }

  Future<void> deleteService(String id) =>
      _db.collection('services').doc(id).delete();

  Future<void> moveService(String id, int direction) async {
    final currentServices = await services();
    final index = currentServices.indexWhere((service) => service.id == id);
    final newIndex = index + direction;
    if (index < 0 || newIndex < 0 || newIndex >= currentServices.length) return;

    final moving = currentServices.removeAt(index);
    currentServices.insert(newIndex, moving);
    final batch = _db.batch();
    for (var position = 0; position < currentServices.length; position++) {
      batch.update(
        _db.collection('services').doc(currentServices[position].id),
        {'order': position + 1},
      );
    }
    await batch.commit();
  }

  Future<void> schedule(String start, String end) async {
    if (!_validClock(start) ||
        !_validClock(end) ||
        _minutes(start) >= _minutes(end)) {
      throw ApiError('Escribe horarios válidos, por ejemplo 09:00 y 18:00.');
    }
    await _db.collection('settings').doc('business').set({
      'start': start,
      'end': end,
    });
  }

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya tiene una cuenta.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Revisa tu conexión a Internet.';
      default:
        return 'No se pudo completar el acceso. Intenta nuevamente.';
    }
  }
}

class _Range {
  final int start;
  final int duration;
  _Range(this.start, this.duration);
}

int _minutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String _clock(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

bool _validClock(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return false;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  return hour != null &&
      minute != null &&
      hour >= 0 &&
      hour < 24 &&
      minute >= 0 &&
      minute < 60;
}
