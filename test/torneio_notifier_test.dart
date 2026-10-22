import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/dados/repositorio.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/telas/configuracoes/configuracao_notifier.dart';
import 'package:poker_timer/telas/estrutura/estrutura_notifier.dart';
import 'package:poker_timer/telas/relogio/torneio_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

const turbo = Estrutura(
  nome: 'Turbo',
  niveis: [
    Nivel(smallBlind: 50, bigBlind: 100, duracao: Duration(minutes: 10)),
  ],
);

Future<ProviderContainer> container([
  Map<String, Object> valores = const {},
]) async {
  SharedPreferences.setMockInitialValues(valores);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [repositorioProvider.overrideWithValue(Repositorio(prefs))],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('sem nada salvo, o torneio usa a estrutura padrão', () async {
    final c = await container();
    expect(c.read(torneioProvider).estrutura.nome, Estrutura.padrao.nome);
  });

  test('torneio novo usa a estrutura salva', () async {
    final c = await container();
    c.read(estruturaProvider.notifier).salvar(turbo);

    final outro = ProviderContainer(
      overrides: [
        repositorioProvider.overrideWithValue(
          Repositorio(await SharedPreferences.getInstance()),
        ),
      ],
    );
    addTearDown(outro.dispose);
    expect(outro.read(torneioProvider).estrutura.nome, 'Turbo');
  });

  test('estrutura nova vale na hora se o torneio não começou', () async {
    final c = await container();
    final trocou = c
        .read(torneioProvider.notifier)
        .usarEstruturaSeNaoComecou(turbo);

    expect(trocou, isTrue);
    expect(c.read(torneioProvider).estrutura.nome, 'Turbo');
  });

  test('torneio em andamento mantém a estrutura até reiniciar', () async {
    final c = await container();
    final torneio = c.read(torneioProvider.notifier)..iniciarOuPausar();
    c.read(estruturaProvider.notifier).salvar(turbo);

    expect(torneio.usarEstruturaSeNaoComecou(turbo), isFalse);
    expect(c.read(torneioProvider).estrutura.nome, Estrutura.padrao.nome);

    torneio.reiniciar();
    expect(c.read(torneioProvider).estrutura.nome, 'Turbo');
    expect(c.read(torneioProvider).isRodando, isFalse);
  });

  test('alternar aviso liga e desliga, em ordem, e salva', () async {
    final c = await container();
    final notifier = c.read(configuracaoProvider.notifier);

    notifier.alternarAviso(10);
    notifier.alternarAviso(5);
    expect(c.read(configuracaoProvider).avisosMinutos, [1, 5, 10]);

    notifier.alternarAviso(1);
    expect(c.read(configuracaoProvider).avisosMinutos, [5, 10]);

    final salva = Repositorio(
      await SharedPreferences.getInstance(),
    ).carregarConfiguracao();
    expect(salva!.avisosMinutos, [5, 10]);
  });
}
