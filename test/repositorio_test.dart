import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/dados/repositorio.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/modelos/estrutura.dart';
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
}
