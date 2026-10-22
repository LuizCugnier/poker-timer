import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/dados/repositorio.dart';
import 'package:poker_timer/logica/avisos.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/main.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/modelos/torneio.dart';
import 'package:poker_timer/servicos/alarmes.dart';
import 'package:poker_timer/servicos/sons.dart';
import 'package:poker_timer/tema.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmesFalso implements Alarmes {
  bool permissoes = true;
  int pedidosDePermissao = 0;
  int cancelamentos = 0;
  Torneio? agendado;
  List<Duration>? agendadoCom;

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
    List<Duration> antecedencias,
  ) async {
    agendado = torneio;
    agendadoCom = antecedencias;
  }

  @override
  Future<void> cancelar() async => cancelamentos++;
}

class SonsFalso implements Sons {
  final tocados = <TipoAviso>[];

  @override
  Future<void> tocar(TipoAviso tipo) async => tocados.add(tipo);
}

late AlarmesFalso alarmes;
late SonsFalso sons;

Future<SharedPreferences> abrirApp(
  WidgetTester tester, {
  Torneio? salvo,
  List<Ficha>? fichas,
  bool permissoes = true,
}) async {
  alarmes = AlarmesFalso()..permissoes = permissoes;
  sons = SonsFalso();
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (salvo != null) 'torneio': jsonEncode(salvo.toJson()),
    if (fichas != null)
      'fichas': jsonEncode([for (final f in fichas) f.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioProvider.overrideWithValue(Repositorio(prefs)),
        alarmesProvider.overrideWithValue(alarmes),
        sonsProvider.overrideWithValue(sons),
      ],
      child: const AppRelogio(),
    ),
  );
  return prefs;
}

Torneio? salvoEm(SharedPreferences prefs) =>
    Repositorio(prefs).carregarTorneio();

Torneio pausadoEm(Duration decorrido) =>
    Torneio(estrutura: Estrutura.padrao, decorridoAcumulado: decorrido);

void main() {
  testWidgets('abre no primeiro nível da estrutura padrão, pausado', (
    tester,
  ) async {
    await abrirApp(tester);

    expect(find.text('NÍVEL 1'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('25 / 50'), findsOneWidget);
    expect(find.text('Próximo: 50 / 100'), findsOneWidget);
    expect(find.text('Intervalo em 1:20:00'), findsOneWidget);
    expect(find.text('1.000'), findsOneWidget);
    expect(find.byTooltip('Iniciar'), findsOneWidget);
  });

  testWidgets('iniciar e pausar salvam o torneio', (tester) async {
    final prefs = await abrirApp(tester);

    await tester.tap(find.byTooltip('Iniciar'));
    await tester.pump();
    expect(find.byTooltip('Pausar'), findsOneWidget);
    expect(salvoEm(prefs)!.isRodando, isTrue);

    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(find.byTooltip('Iniciar'), findsOneWidget);
    expect(salvoEm(prefs)!.isRodando, isFalse);
  });

  testWidgets('avançar nível pede confirmação', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byTooltip('Próximo nível'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('25 / 50'), findsOneWidget);

    await tester.tap(find.byTooltip('Próximo nível'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('NÍVEL 2'), findsOneWidget);
    expect(find.text('50 / 100'), findsOneWidget);
  });

  testWidgets('±1 minuto não pede confirmação', (tester) async {
    await abrirApp(tester, salvo: pausadoEm(const Duration(minutes: 5)));
    expect(find.text('15:00'), findsOneWidget);

    await tester.tap(find.text('+1 min'));
    await tester.pump();
    expect(find.text('16:00'), findsOneWidget);

    await tester.tap(find.text('−1 min'));
    await tester.tap(find.text('−1 min'));
    await tester.pump();
    expect(find.text('14:00'), findsOneWidget);
  });

  testWidgets('reiniciar volta ao começo depois de confirmar', (tester) async {
    final prefs = await abrirApp(
      tester,
      salvo: pausadoEm(const Duration(minutes: 50)),
    );
    expect(find.text('NÍVEL 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Reiniciar torneio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('NÍVEL 1'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(salvoEm(prefs)!.decorridoAcumulado, Duration.zero);
  });

  testWidgets('restaura o torneio salvo e mostra o intervalo', (tester) async {
    final inicioIntervalo = inicioDoNivel(Estrutura.padrao, 4);
    await abrirApp(
      tester,
      salvo: pausadoEm(inicioIntervalo + const Duration(minutes: 2)),
    );

    expect(find.text('INTERVALO'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.textContaining('NÍVEL'), findsNothing);
    expect(find.text('Próximo: 150 / 300'), findsOneWidget);
  });

  testWidgets('últimos 60 segundos em destaque', (tester) async {
    final agora = DateTime.now();
    await abrirApp(
      tester,
      salvo: Torneio(
        estrutura: Estrutura.padrao,
        decorridoAcumulado: const Duration(minutes: 19, seconds: 30),
        rodandoDesde: agora,
      ),
    );

    final tempo = tester.widget<Text>(find.textContaining(RegExp(r'^00:')));
    expect(tempo.style!.color, Tema.ultimoMinuto);
  });

  testWidgets('ante aparece quando o nível tem ante', (tester) async {
    await abrirApp(
      tester,
      salvo: pausadoEm(inicioDoNivel(Estrutura.padrao, 10)),
    );

    expect(find.text('500 / 1.000'), findsOneWidget);
    expect(find.text('ANTE 100'), findsOneWidget);
    expect(find.text('Próximo: 600 / 1.200 · ante 200'), findsOneWidget);
  });

  testWidgets('ao abrir, cancela alarmes pendentes da última sessão', (
    tester,
  ) async {
    await abrirApp(tester);
    expect(alarmes.cancelamentos, 1);
  });

  testWidgets('em segundo plano agenda os alarmes; ao voltar, cancela', (
    tester,
  ) async {
    await abrirApp(tester);
    await tester.tap(find.byTooltip('Iniciar'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(alarmes.agendado?.isRodando, isTrue);

    final antes = alarmes.cancelamentos;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(alarmes.cancelamentos, antes + 1);
  });

  testWidgets('primeiro início sem permissão explica e pede', (tester) async {
    await abrirApp(tester, permissoes: false);

    await tester.tap(find.byTooltip('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pausar'), findsOneWidget);
    expect(find.textContaining('alarmes exatos'), findsOneWidget);

    await tester.tap(find.text('Permitir'));
    await tester.pumpAndSettle();
    expect(alarmes.pedidosDePermissao, 1);
  });

  testWidgets('"Agora não" segue sem pedir permissão', (tester) async {
    await abrirApp(tester, permissoes: false);

    await tester.tap(find.byTooltip('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(alarmes.pedidosDePermissao, 0);
    expect(find.byTooltip('Pausar'), findsOneWidget);
  });

  testWidgets('retomar um torneio em andamento não pergunta de novo', (
    tester,
  ) async {
    await abrirApp(
      tester,
      salvo: pausadoEm(const Duration(minutes: 5)),
      permissoes: false,
    );

    await tester.tap(find.byTooltip('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('alarmes exatos'), findsNothing);
  });

  testWidgets('mostra as fichas salvas na lateral', (tester) async {
    await abrirApp(
      tester,
      fichas: const [Ficha(valor: 5000, cor: 0xFF1976D2, rotulo: 'Azul')],
    );
    expect(find.text('5.000'), findsOneWidget);
    expect(find.text('1.000'), findsNothing);
  });

  testWidgets('o menu de configurações abre os editores', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Avisar antes da troca de nível'), findsOneWidget);
    expect(find.text('Fichas'), findsOneWidget);

    await tester.tap(find.text('Estrutura de blinds'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Estrutura de blinds'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fichas'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Fichas'), findsOneWidget);
  });

  testWidgets('avisos escolhidos nas configurações valem para os alarmes', (
    tester,
  ) async {
    final prefs = await abrirApp(tester);
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min'));
    await tester.tap(find.text('1 min'));
    await tester.pumpAndSettle();
    expect(Repositorio(prefs).carregarConfiguracao()!.avisosMinutos, [5]);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Iniciar'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(alarmes.agendadoCom, [const Duration(minutes: 5)]);
  });

  group('sons', () {
    // O relógio usa DateTime.now(): o teste deixa passar tempo real e depois
    // avança o Timer de redesenho (que roda no tempo falso do teste).
    Torneio faltandoUmSegundo() => Torneio(
      estrutura: Estrutura.padrao,
      decorridoAcumulado: const Duration(minutes: 19, seconds: 59),
      rodandoDesde: DateTime.now(),
    );

    Future<void> esperarATroca(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1300)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('na tela, a troca de nível toca o som', (tester) async {
      await abrirApp(tester, salvo: faltandoUmSegundo());
      await tester.pump(const Duration(milliseconds: 300));

      await esperarATroca(tester);
      expect(find.text('NÍVEL 2'), findsOneWidget);
      expect(sons.tocados, [TipoAviso.troca]);
    });

    testWidgets('fora da tela não toca, nem atrasado ao voltar', (
      tester,
    ) async {
      await abrirApp(tester, salvo: faltandoUmSegundo());
      await tester.pump(const Duration(milliseconds: 300));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);

      await esperarATroca(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('NÍVEL 2'), findsOneWidget);
      expect(sons.tocados, isEmpty);
    });

    testWidgets('pular nível pelos controles não toca som', (tester) async {
      await abrirApp(tester);
      await tester.tap(find.byTooltip('Iniciar'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Próximo nível'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('NÍVEL 2'), findsOneWidget);
      expect(sons.tocados, isEmpty);
    });
  });
}
