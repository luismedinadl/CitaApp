import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Usa el mismo Client ID web que valida el servidor.
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

class GoogleAuth {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  final _webTokens = StreamController<String>.broadcast();

  bool get configured => googleClientId.isNotEmpty;
  Stream<String> get webTokens => _webTokens.stream;

  Future<void> initialize() async {
    if (!configured) return;
    await GoogleSignIn.instance.initialize(
      // Chrome necesita su Client ID. Android utiliza serverClientId.
      clientId: kIsWeb ? googleClientId : null,
      serverClientId: kIsWeb ? null : googleClientId,
    );
    if (kIsWeb) {
      _events = GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final token = event.user.authentication.idToken;
          if (token != null) _webTokens.add(token);
        }
      }, onError: _webTokens.addError);
    }
  }

  Future<String> signInOnAndroid() async {
    if (!configured) {
      throw StateError('Falta configurar GOOGLE_CLIENT_ID.');
    }
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('En Chrome usa el botón oficial de Google.');
    }
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google no devolvió un token de acceso.');
    }
    return token;
  }

  void dispose() {
    _events?.cancel();
    _webTokens.close();
  }
}
