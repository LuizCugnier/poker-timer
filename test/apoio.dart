import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/dados/repositorio.dart';
import 'package:poker_timer/logica/avisos.dart';
import 'package:poker_timer/main.dart';
import 'package:poker_timer/modelos/configuracao.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/modelos/premiacao.dart';
import 'package:poker_timer/modelos/torneio.dart';
import 'package:poker_timer/servicos/alarmes.dart';
import 'package:poker_timer/servicos/sons.dart';
import 'package:poker_timer/telas/relogio/estado_relogio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmesFalso implements Alarmes {
  bool permissoes = true;
  int pedidosDePermissao = 0;
  int cancelamentos = 0;
  Torneio? agendado;
  List<Duration>? agendadoCom;
  bool? agendadoComMetade;

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> temPermissoes() async => permissoes;

  @override
  Future<void> pedirPermissoes() async => pedidosDePermissao++;

  @override
  Future<void> agendar(
    Torneio torneio,
    DateTime agora,
    List<Duration> antecedencias, {
    bool isAvisoMetade = false,
  }) async {
    agendado = torneio;
    agendadoCom = antecedencias;
    agendadoComMetade = isAvisoMetade;
  }

  @override
  Future<void> cancelar() async => cancelamentos++;
}

class SonsFalso implements Sons {
  final tocados = <TipoAviso>[];

  @override
  Future<void> tocar(TipoAviso tipo) async => tocados.add(tipo);
}

// "Agora" parado, para a tela mostrar sempre o mesmo instante (goldens).
class AgoraFixo extends AgoraNotifier {
  AgoraFixo(this.fixo);

  final DateTime fixo;

  @override
  DateTime build() => fixo;
}

late AlarmesFalso alarmes;
late SonsFalso sons;

// Rola a lista da tela até o alvo: o ListView só constrói o que está perto da
// tela, e "construído" ainda pode estar fora dela. Cada campo de texto tem o
// próprio Scrollable: a lista é o primeiro.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(
    alvo,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
}

// Abre o app inteiro numa tela de 1280×800 dp, com o que estiver "salvo".
Future<SharedPreferences> abrirApp(
  WidgetTester tester, {
  Torneio? salvo,
  List<Ficha>? fichas,
  Configuracao? configuracao,
  Premiacao? premiacao,
  bool permissoes = true,
  DateTime? agora,
  double densidade = 2,
}) async {
  alarmes = AlarmesFalso()..permissoes = permissoes;
  sons = SonsFalso();
  tester.view.physicalSize = Size(1280 * densidade, 800 * densidade);
  tester.view.devicePixelRatio = densidade;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (salvo != null) 'torneio': jsonEncode(salvo.toJson()),
    if (fichas != null)
      'fichas': jsonEncode([for (final f in fichas) f.toJson()]),
    if (configuracao != null) 'configuracao': jsonEncode(configuracao.toJson()),
    if (premiacao != null) 'premiacao': jsonEncode(premiacao.toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioProvider.overrideWithValue(Repositorio(prefs)),
        alarmesProvider.overrideWithValue(alarmes),
        sonsProvider.overrideWithValue(sons),
        if (agora != null) agoraProvider.overrideWith(() => AgoraFixo(agora)),
      ],
      child: const AppRelogio(),
    ),
  );
  return prefs;
}

// Fonte Inter do app e os ícones Material: sem isso, os goldens saem com a fonte
// de teste (blocos) no lugar das letras e dos ícones.
Future<void> carregarFontes() async {
  Future<ByteData> ler(String caminho) async =>
      ByteData.sublistView(await File(caminho).readAsBytes());

  final inter = FontLoader('Inter');
  for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    inter.addFont(ler('assets/fonts/Inter-$peso.ttf'));
  }
  await inter.load();

  final raizFlutter = Platform.environment['FLUTTER_ROOT'];
  final icones = FontLoader('MaterialIcons')
    ..addFont(
      ler(
        '$raizFlutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await icones.load();
}
