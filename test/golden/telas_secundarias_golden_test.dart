import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/main.dart';
import 'package:poker_timer/modelos/configuracao.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/theme/tema_relogio.dart';

import '../apoio.dart';
import 'relogio_golden_test.dart' show agora, base, modos, torneio, mmss;

// Configurações, editores e a confirmação (ESPECIFICACAO 5) nos 2 modos.
void main() {
  setUpAll(carregarFontes);

  Future<void> abrir(WidgetTester tester, ModoRelogio modo) => abrirApp(
    tester,
    salvo: torneio(antes: 10, aPartir: base, restante: mmss(14, 37)),
    fichas: fichasPadrao,
    configuracao: Configuracao(modo: modo),
    agora: agora,
    densidade: 1,
  );

  Future<void> conferir(WidgetTester tester, String nome) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AppRelogio),
      matchesGoldenFile('goldens/$nome.png'),
    );
  }

  for (final MapEntry(key: nomeModo, value: modo) in modos.entries) {
    testWidgets('$nomeModo · configurações', (tester) async {
      await abrir(tester, modo);
      await tester.tap(find.byTooltip('Configurações'));
      await conferir(tester, '$nomeModo-configuracoes');
    });

    testWidgets('$nomeModo · editor de estrutura', (tester) async {
      await abrir(tester, modo);
      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estrutura de blinds'));
      await conferir(tester, '$nomeModo-editor-estrutura');
    });

    testWidgets('$nomeModo · editor de fichas com o diálogo', (tester) async {
      await abrir(tester, modo);
      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fichas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();
      // Sem o foco no campo, o cursor não pisca e a imagem fica estável.
      FocusManager.instance.primaryFocus?.unfocus();
      await conferir(tester, '$nomeModo-editor-fichas');
    });

    testWidgets('$nomeModo · confirmação', (tester) async {
      await abrir(tester, modo);
      await tester.tap(find.byTooltip('Próximo nível'));
      await conferir(tester, '$nomeModo-confirmacao');
    });
  }
}
