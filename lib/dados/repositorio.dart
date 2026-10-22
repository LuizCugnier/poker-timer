import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/configuracao.dart';
import '../modelos/estrutura.dart';
import '../modelos/ficha.dart';
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
  static const _chaveEstrutura = 'estrutura';
  static const _chaveFichas = 'fichas';
  static const _chaveConfiguracao = 'configuracao';

  // Os carregar* devolvem null se não há nada salvo ou se o JSON salvo não é mais válido.
  Torneio? carregarTorneio() {
    final torneio = _ler(
      _chaveTorneio,
      (json) => Torneio.fromJson(json as Map<String, dynamic>),
    );
    return torneio == null || torneio.estrutura.niveis.isEmpty ? null : torneio;
  }

  Future<void> salvarTorneio(Torneio torneio) async {
    await _prefs.setString(_chaveTorneio, jsonEncode(torneio.toJson()));
  }

  Future<void> apagarTorneio() async {
    await _prefs.remove(_chaveTorneio);
  }

  Estrutura? carregarEstrutura() {
    final estrutura = _ler(
      _chaveEstrutura,
      (json) => Estrutura.fromJson(json as Map<String, dynamic>),
    );
    return estrutura == null || estrutura.niveis.isEmpty ? null : estrutura;
  }

  Future<void> salvarEstrutura(Estrutura estrutura) async {
    await _prefs.setString(_chaveEstrutura, jsonEncode(estrutura.toJson()));
  }

  List<Ficha>? carregarFichas() {
    return _ler(
      _chaveFichas,
      (json) => [
        for (final ficha in json as List)
          Ficha.fromJson(ficha as Map<String, dynamic>),
      ],
    );
  }

  Future<void> salvarFichas(List<Ficha> fichas) async {
    await _prefs.setString(
      _chaveFichas,
      jsonEncode([for (final ficha in fichas) ficha.toJson()]),
    );
  }

  Configuracao? carregarConfiguracao() {
    return _ler(
      _chaveConfiguracao,
      (json) => Configuracao.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> salvarConfiguracao(Configuracao configuracao) async {
    await _prefs.setString(
      _chaveConfiguracao,
      jsonEncode(configuracao.toJson()),
    );
  }

  T? _ler<T>(String chave, T Function(Object? json) converter) {
    final texto = _prefs.getString(chave);
    if (texto == null) return null;
    try {
      return converter(jsonDecode(texto));
    } on Object {
      // ponytail: JSON inválido (formato antigo ou corrompido) vira "nada salvo" em vez de travar o app.
      return null;
    }
  }
}
