import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/dados/repositorio.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/modelos/premiacao.dart';
import 'package:poker_timer/modelos/torneio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Repositorio> repositorio([
  Map<String, Object> valores = const {},
]) async {
  SharedPreferences.setMockInitialValues(valores);
  return Repositorio(await SharedPreferences.getInstance());
}

void main() {
  final t0 = DateTime(2026, 10, 21, 20);

  test('sem nada salvo, não há torneio', () async {
    expect((await repositorio()).carregarTorneio(), isNull);
  });

  test('torneio rodando sobrevive a fechar e reabrir o app', () async {
    final repo = await repositorio();
    final torneio = iniciar(const Torneio(estrutura: Estrutura.padrao), t0);
    await repo.salvarTorneio(torneio);

    final reaberto = Repositorio(await SharedPreferences.getInstance());
    final carregado = reaberto.carregarTorneio()!;

    expect(carregado.rodandoDesde, t0);
    expect(carregado.estrutura.niveis.length, Estrutura.padrao.niveis.length);
    final duasHorasDepois = t0.add(const Duration(hours: 2));
    expect(
      calcularEstado(carregado, duasHorasDepois).indiceNivel,
      calcularEstado(torneio, duasHorasDepois).indiceNivel,
    );
  });

  test('torneio pausado guarda o tempo acumulado', () async {
    final repo = await repositorio();
    await repo.salvarTorneio(
      const Torneio(
        estrutura: Estrutura.padrao,
        decorridoAcumulado: Duration(minutes: 7, milliseconds: 250),
      ),
    );

    final carregado = repo.carregarTorneio()!;
    expect(carregado.isRodando, isFalse);
    expect(
      carregado.decorridoAcumulado,
      const Duration(minutes: 7, milliseconds: 250),
    );
  });

  test('apagar remove o torneio', () async {
    final repo = await repositorio();
    await repo.salvarTorneio(const Torneio(estrutura: Estrutura.padrao));
    await repo.apagarTorneio();
    expect(repo.carregarTorneio(), isNull);
  });

  test('JSON inválido não trava o app', () async {
    final repo = await repositorio({'torneio': '{"formato": "antigo"}'});
    expect(repo.carregarTorneio(), isNull);

    final lixo = await repositorio({'torneio': 'não é json'});
    expect(lixo.carregarTorneio(), isNull);
  });

  test('estrutura salva sobrevive a reabrir o app', () async {
    final repo = await repositorio();
    expect(repo.carregarEstrutura(), isNull);

    await repo.salvarEstrutura(
      const Estrutura(
        nome: 'Turbo',
        niveis: [
          Nivel(smallBlind: 50, bigBlind: 100, duracao: Duration(minutes: 10)),
          Nivel.intervalo(Duration(minutes: 5)),
        ],
      ),
    );

    final carregada = Repositorio(
      await SharedPreferences.getInstance(),
    ).carregarEstrutura()!;
    expect(carregada.nome, 'Turbo');
    expect(carregada.niveis, hasLength(2));
    expect(carregada.niveis[1].isIntervalo, isTrue);
  });

  test('estrutura vazia salva é ignorada', () async {
    final repo = await repositorio({
      'estrutura': '{"nome": "x", "niveis": []}',
    });
    expect(repo.carregarEstrutura(), isNull);
  });

  test('fichas salvas sobrevivem a reabrir o app', () async {
    final repo = await repositorio();
    expect(repo.carregarFichas(), isNull);

    await repo.salvarFichas(const [
      Ficha(valor: 5, cor: 0xFF1976D2, rotulo: 'Azul'),
      Ficha(valor: 25, cor: 0xFFFFFFFF, rotulo: ''),
    ]);

    final carregadas = Repositorio(
      await SharedPreferences.getInstance(),
    ).carregarFichas()!;
    expect(carregadas.map((f) => f.valor), [5, 25]);
    expect(carregadas.first.rotulo, 'Azul');
  });

  test('lista de fichas vazia é válida', () async {
    final repo = await repositorio();
    await repo.salvarFichas(const []);
    expect(repo.carregarFichas(), isEmpty);
  });

  test(
    'premiação salva sobrevive a reabrir o app e pode ser removida',
    () async {
      final repo = await repositorio();
      expect(repo.carregarPremiacao(), isNull);

      await repo.salvarPremiacao(
        const Premiacao(
          total: 1000,
          tipo: TipoDivisao.porcentagem,
          valores: [60, 40],
        ),
      );
      final carregada = Repositorio(
        await SharedPreferences.getInstance(),
      ).carregarPremiacao()!;
      expect(carregada.valores, [60, 40]);

      await repo.removerPremiacao();
      expect(repo.carregarPremiacao(), isNull);
    },
  );
}
