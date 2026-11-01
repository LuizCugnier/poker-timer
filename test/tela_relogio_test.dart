import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/dados/repositorio.dart';
import 'package:poker_timer/logica/avisos.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/modelos/configuracao.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/modelos/premiacao.dart';
import 'package:poker_timer/modelos/torneio.dart';
import 'package:poker_timer/theme/tema_relogio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio.dart';

Torneio? salvoEm(SharedPreferences prefs) =>
    Repositorio(prefs).carregarTorneio();

Torneio pausadoEm(Duration decorrido) =>
    Torneio(estrutura: Estrutura.padrao, decorridoAcumulado: decorrido);

Color? corDoTempo(WidgetTester tester) => tester
    .widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.byKey(const Key('tempo')),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    )
    .style
    .color;

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
    expect(find.text('INICIAR'), findsOneWidget);
  });

  testWidgets('iniciar e pausar salvam o torneio', (tester) async {
    final prefs = await abrirApp(tester);

    await tester.tap(find.text('INICIAR'));
    await tester.pump();
    expect(find.text('PAUSAR'), findsOneWidget);
    expect(salvoEm(prefs)!.isRodando, isTrue);

    await tester.tap(find.text('PAUSAR'));
    await tester.pump();
    expect(find.text('INICIAR'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Mais 1 minuto'));
    await tester.pump();
    expect(find.text('16:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Menos 1 minuto'));
    await tester.tap(find.byTooltip('Menos 1 minuto'));
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

    expect(corDoTempo(tester), CoresRelogio.altoContraste.ultimoMinuto);
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
    await tester.tap(find.text('INICIAR'));
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

    await tester.tap(find.text('INICIAR'));
    await tester.pumpAndSettle();
    expect(find.textContaining('alarmes exatos'), findsOneWidget);
    expect(find.text('PAUSAR'), findsNothing);
    expect(sons.tocados, isEmpty);

    await tester.tap(find.text('Permitir'));
    await tester.pumpAndSettle();
    expect(alarmes.pedidosDePermissao, 1);
    expect(find.text('PAUSAR'), findsOneWidget);
    expect(sons.tocados, [TipoAviso.troca]);
  });

  testWidgets('"Agora não" segue sem pedir permissão', (tester) async {
    await abrirApp(tester, permissoes: false);

    await tester.tap(find.text('INICIAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(alarmes.pedidosDePermissao, 0);
    expect(find.text('PAUSAR'), findsOneWidget);
    expect(sons.tocados, [TipoAviso.troca]);
  });

  testWidgets('retomar um torneio em andamento não pergunta de novo', (
    tester,
  ) async {
    await abrirApp(
      tester,
      salvo: pausadoEm(const Duration(minutes: 5)),
      permissoes: false,
    );

    await tester.tap(find.text('INICIAR'));
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
    await tester.tap(find.text('INICIAR'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(alarmes.agendadoCom, [const Duration(minutes: 5)]);
  });

  testWidgets('o time bank salva ao digitar, só valores válidos', (
    tester,
  ) async {
    final prefs = await abrirApp(tester);
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('SEGUNDOS'));
    Duration? salvo() => Repositorio(prefs).carregarConfiguracao()?.timeBank;

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pump();
    expect(salvo(), isNull);

    await tester.enterText(find.byType(TextFormField), '45');
    await tester.pump();
    expect(salvo(), const Duration(seconds: 45));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('45'));
    expect(find.text('45'), findsOneWidget);
  });

  group('premiação', () {
    testWidgets('sem premiação salva, o painel não aparece', (tester) async {
      await abrirApp(tester);
      expect(find.text('PRÊMIOS'), findsNothing);
    });

    testWidgets('premiação salva aparece com os valores calculados', (
      tester,
    ) async {
      await abrirApp(
        tester,
        premiacao: const Premiacao(
          total: 1250,
          tipo: TipoDivisao.porcentagem,
          valores: [33, 33, 34],
        ),
      );
      expect(find.text('PRÊMIOS'), findsOneWidget);
      expect(find.text('1º  413'), findsOneWidget);
      expect(find.text('2º  412'), findsOneWidget);
      expect(find.text('3º  425'), findsOneWidget);
    });

    Future<void> abrirEditor(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      await rolarAte(tester, find.text('Premiação'));
      await tester.tap(find.text('Premiação'));
      await tester.pumpAndSettle();
    }

    Finder campo(String rotulo) => find.descendant(
      of: find
          .ancestor(
            of: find.text(rotulo.toUpperCase()),
            matching: find.byType(Column),
          )
          .first,
      matching: find.byType(TextFormField),
    );

    testWidgets('o editor salva só quando a soma fecha', (tester) async {
      final prefs = await abrirApp(tester);
      await abrirEditor(tester);
      Premiacao? salva() => Repositorio(prefs).carregarPremiacao();

      await tester.enterText(campo('Total da premiação'), '1000');
      await tester.enterText(campo('2º lugar (%)'), '40');
      await tester.pump();
      expect(find.text('Soma 110% de 100%.'), findsOneWidget);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(salva(), isNull);

      await tester.enterText(campo('2º lugar (%)'), '30');
      await tester.pump();
      expect(find.text('= 300'), findsOneWidget);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(salva()!.valores, [50, 30, 20]);
      expect(salva()!.total, 1000);
      expect(find.text('3 premiados · 1.000'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('1º  500'), findsOneWidget);
    });

    testWidgets('trocar o tipo converte os valores e mudar premiados '
        'redimensiona a lista', (tester) async {
      await abrirApp(
        tester,
        premiacao: const Premiacao(
          total: 1000,
          tipo: TipoDivisao.porcentagem,
          valores: [50, 30, 20],
        ),
      );
      await abrirEditor(tester);

      await tester.tap(find.text('Valor fixo'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '500'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '300'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '200'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '2'));
      await tester.pump();
      expect(find.text('3º LUGAR'), findsNothing);
      expect(find.text('Soma 800 de 1.000.'), findsOneWidget);
    });

    testWidgets('remover a premiação tira o painel da tela', (tester) async {
      final prefs = await abrirApp(
        tester,
        premiacao: const Premiacao(
          total: 1000,
          tipo: TipoDivisao.fixo,
          valores: [1000],
        ),
      );
      await abrirEditor(tester);
      await tester.tap(find.byTooltip('Remover premiação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(Repositorio(prefs).carregarPremiacao(), isNull);
      expect(find.text('Sem premiação'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('PRÊMIOS'), findsNothing);
    });
  });

  testWidgets('o chip 1/2 liga o aviso na metade e vale para os alarmes', (
    tester,
  ) async {
    final prefs = await abrirApp(tester);
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('1/2'));
    await tester.tap(find.text('1/2'));
    await tester.pumpAndSettle();
    expect(Repositorio(prefs).carregarConfiguracao()!.isAvisoMetade, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('INICIAR'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(alarmes.agendadoComMetade, isTrue);
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

    testWidgets('iniciar um torneio novo toca o som de troca', (tester) async {
      await abrirApp(tester);
      await tester.tap(find.text('INICIAR'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(sons.tocados, [TipoAviso.troca]);
    });

    testWidgets('retomar depois de pausar não toca som', (tester) async {
      await abrirApp(
        tester,
        salvo: Torneio(
          estrutura: Estrutura.padrao,
          decorridoAcumulado: const Duration(minutes: 5),
        ),
      );
      await tester.tap(find.text('INICIAR'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(sons.tocados, isEmpty);
    });

    testWidgets('time bank conta e tocar de novo cancela, sem som', (
      tester,
    ) async {
      await abrirApp(tester);
      await tester.tap(find.byTooltip('Time bank'));
      await tester.pump();
      expect(find.text('00:30'), findsOneWidget);

      await tester.tap(find.byTooltip('Time bank'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TIME BANK'), findsOneWidget);
      expect(sons.tocados, isEmpty);
    });

    testWidgets('time bank acabando toca o aviso e volta a parado', (
      tester,
    ) async {
      await abrirApp(
        tester,
        configuracao: const Configuracao(timeBank: Duration(seconds: 1)),
      );
      await tester.tap(find.byTooltip('Time bank'));
      await tester.pump(const Duration(milliseconds: 300));

      await esperarATroca(tester);
      expect(sons.tocados, [TipoAviso.aviso]);
      expect(find.text('TIME BANK'), findsOneWidget);
    });

    testWidgets('pular nível pelos controles não toca som', (tester) async {
      await abrirApp(tester);
      await tester.tap(find.text('INICIAR'));
      await tester.pump(const Duration(milliseconds: 300));
      sons.tocados.clear();

      await tester.tap(find.byTooltip('Próximo nível'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('NÍVEL 2'), findsOneWidget);
      expect(sons.tocados, isEmpty);
    });
  });

  group('estados da tela', () {
    testWidgets('pausado mostra o selo e o tempo apagado', (tester) async {
      await abrirApp(tester, salvo: pausadoEm(const Duration(minutes: 5)));
      expect(find.text('PAUSADO'), findsOneWidget);
      expect(corDoTempo(tester), CoresRelogio.altoContraste.pausado);

      await tester.tap(find.text('INICIAR'));
      await tester.pumpAndSettle();
      expect(find.text('PAUSADO'), findsNothing);
      expect(corDoTempo(tester), CoresRelogio.altoContraste.texto);
    });

    testWidgets('último nível e fim da estrutura', (tester) async {
      final total = inicioDoNivel(
        Estrutura.padrao,
        Estrutura.padrao.niveis.length,
      );
      await abrirApp(
        tester,
        salvo: pausadoEm(total - const Duration(minutes: 5)),
      );
      expect(find.text('Último nível'), findsOneWidget);
      expect(find.textContaining('Intervalo em'), findsNothing);

      await abrirApp(tester, salvo: pausadoEm(total));
      await tester.pumpAndSettle();
      expect(find.text('FIM DA ESTRUTURA'), findsOneWidget);
      expect(find.text('Fim da estrutura'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);

      // Play desabilitado: tocar não inicia nada.
      await tester.tap(find.text('INICIAR'));
      await tester.pump();
      expect(find.text('PAUSAR'), findsNothing);
    });

    testWidgets('sem ante, a caixa do ante continua com a mesma altura', (
      tester,
    ) async {
      await abrirApp(tester);
      final semAnte = tester.getRect(find.text('Próximo: 50 / 100'));

      await abrirApp(
        tester,
        salvo: pausadoEm(inicioDoNivel(Estrutura.padrao, 10)),
      );
      await tester.pumpAndSettle();
      final comAnte = tester.getRect(
        find.text('Próximo: 600 / 1.200 · ante 200'),
      );
      expect(comAnte.top, semAnte.top);
    });

    testWidgets('a confirmação de pular mostra o nível que vem', (
      tester,
    ) async {
      await abrirApp(tester);
      await tester.tap(find.byTooltip('Próximo nível'));
      await tester.pumpAndSettle();
      expect(find.text('Pular para o próximo nível?'), findsOneWidget);
      expect(
        find.text(
          'O nível 1 termina agora e o relógio começa o nível 2: 50 / 100.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('trocar o modo de exibição muda as cores na hora', (
      tester,
    ) async {
      final prefs = await abrirApp(tester);
      Color fundoAtual() =>
          tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor!;
      expect(fundoAtual(), CoresRelogio.altoContraste.fundo);

      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mesa de cassino'));
      await tester.pumpAndSettle();
      expect(
        Repositorio(prefs).carregarConfiguracao()!.modo,
        ModoRelogio.mesaCassino,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(fundoAtual(), CoresRelogio.mesaCassino.fundo);
    });

    testWidgets('abre no modo salvo', (tester) async {
      await abrirApp(
        tester,
        configuracao: const Configuracao(modo: ModoRelogio.mesaCassino),
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        CoresRelogio.mesaCassino.fundo,
      );
    });
  });

  testWidgets(
    'a tela principal escala para ocupar telas maiores que o design',
    (tester) async {
      await abrirApp(tester);
      final noDesign = tester.getRect(find.byKey(const Key('tempo')));

      // Tablet com "Tamanho da tela" reduzido: mais dp, mesma proporção 16:10.
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      await tester.pump();
      final ampliado = tester.getRect(find.byKey(const Key('tempo')));

      expect(ampliado.height / noDesign.height, closeTo(1.25, 0.01));
      expect(
        tester.getRect(find.byType(FittedBox).first),
        Offset.zero & const Size(1600, 1000),
      );
    },
  );

  group('piscada vermelha', () {
    final agora = DateTime(2026, 10, 22, 21);

    // Rodando no primeiro nível da estrutura padrão (20 min) com `restante` no relógio.
    Torneio faltando(Duration restante) => Torneio(
      estrutura: Estrutura.padrao,
      rodandoDesde: agora.subtract(const Duration(minutes: 20) - restante),
    );

    Color? fundo(WidgetTester tester) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(const Key('fundoPrincipal')),
                    )
                    .decoration
                as BoxDecoration?)
            ?.color;

    testWidgets(
      'no último minuto o tempo fica vermelho, mas o fundo não pisca',
      (tester) async {
        await abrirApp(
          tester,
          salvo: faltando(const Duration(seconds: 30)),
          agora: agora,
        );
        await tester.pump(DuracoesRelogio.troca);
        expect(corDoTempo(tester), CoresRelogio.altoContraste.ultimoMinuto);
        expect(fundo(tester), CoresRelogio.altoContraste.fundo);
      },
    );

    testWidgets(
      'nos últimos 10 segundos o fundo fica vermelho no começo do segundo',
      (tester) async {
        await abrirApp(
          tester,
          salvo: faltando(const Duration(seconds: 7, milliseconds: 600)),
          agora: agora,
        );
        await tester.pump(DuracoesRelogio.piscada);
        expect(fundo(tester), CoresRelogio.altoContraste.fundoUltimoMinuto);
      },
    );

    testWidgets('e volta ao normal na outra metade do segundo', (tester) async {
      await abrirApp(
        tester,
        salvo: faltando(const Duration(seconds: 7, milliseconds: 300)),
        agora: agora,
      );
      await tester.pump(DuracoesRelogio.piscada);
      expect(fundo(tester), CoresRelogio.altoContraste.fundo);
    });

    testWidgets('pausado nos últimos 10 segundos não pisca', (tester) async {
      await abrirApp(
        tester,
        salvo: Torneio(
          estrutura: Estrutura.padrao,
          decorridoAcumulado: const Duration(
            minutes: 19,
            seconds: 52,
            milliseconds: 400,
          ),
        ),
        agora: agora,
      );
      await tester.pump(DuracoesRelogio.piscada);
      expect(fundo(tester), CoresRelogio.altoContraste.fundo);
    });
  });
}
