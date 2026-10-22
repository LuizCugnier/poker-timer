import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/torneio.dart';

// Sobrescrito no main (e nos testes) com o SharedPreferences já aberto.
final repositorioProvider = Provider<Repositorio>(
  (ref) => throw UnimplementedError('repositorioProvider precisa de override'),
);

// Recebe o SharedPreferences já carregado (getInstance no main), para a leitura ser síncrona.
class Repositorio {
  Repositorio(this._prefs);

  final SharedPreferences _prefs;

  static const _chaveTorneio = 'torneio';

  // null se não há torneio salvo ou se o JSON salvo não é mais válido.
  Torneio? carregarTorneio() {
    final texto = _prefs.getString(_chaveTorneio);
    if (texto == null) return null;
    try {
      return Torneio.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on Object {
      // ponytail: JSON inválido (formato antigo ou corrompido) vira "sem torneio" em vez de travar o app.
      return null;
    }
  }

  Future<void> salvarTorneio(Torneio torneio) async {
    await _prefs.setString(_chaveTorneio, jsonEncode(torneio.toJson()));
  }

  Future<void> apagarTorneio() async {
    await _prefs.remove(_chaveTorneio);
  }
}
