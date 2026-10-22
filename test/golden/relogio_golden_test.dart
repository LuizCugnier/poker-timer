import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/main.dart';
import 'package:poker_timer/modelos/configuracao.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/modelos/torneio.dart';
import 'package:poker_timer/theme/tema_relogio.dart';

import '../apoio.dart';

// Os 9 estados da tela principal (ESPECIFICACAO 3) nos 2 modos, com os mesmos
// valores de BASE e ESTADOS em docs/design/Relogio.dc.html. Cada estado monta uma
// estrutura de teste: níveis curtos de enchimento levam o número do nível ao do
// design, e o tempo restante sai exatamente igual.
final agora = DateTime(2026, 10, 21, 21);

const enchimento = Nivel(
  smallBlind: 10,
  bigBlind: 20,
  duracao: Duration(minutes: 1),
);
const intervalo = Nivel.intervalo(Duration(minutes: 10));

Nivel nivel(int sb, int bb, {int ante = 0, Duration? duracao}) => Nivel(
  smallBlind: sb,
  bigBlind: bb,
  ante: ante,
  duracao: duracao ?? const Duration(minutes: 20),
);

// O nível atual é o primeiro de `aPartir`, depois de `antes` níveis de enchimento.
Torneio torneio({
  required int antes,
  required List<Nivel> aPartir,
  required Duration restante,
  bool isRodando = true,
}) {
  final estrutura = Estrutura(
    nome: 'Golden',
    niveis: [for (var i = 0; i < antes; i++) enchimento, ...aPartir],
  );
  final decorrido =
      inicioDoNivel(estrutura, antes) + aPartir.first.duracao - restante;
  return Torneio(
    estrutura: estrutura,
    decorridoAcumulado: isRodando ? Duration.zero : decorrido,
    rodandoDesde: isRodando ? agora.subtract(decorrido) : null,
  );
}

Duration mmss(int m, int s, [int h = 0]) =>
    Duration(hours: h, minutes: m, seconds: s);

// Nível 11 · 500 / 1.000 · ANTE 100; o 12 dura 32:35 para "Intervalo em" bater
// com o design (14:37 + 32:35 = 47:12).
final base = [
  nivel(500, 1000, ante: 100),
  nivel(600, 1200, ante: 200, duracao: mmss(32, 35)),
  intervalo,
  nivel(800, 1600, ante: 200),
];

final ultimo = [nivel(5000, 10000, ante: 1000)];

final estados = <String, (Torneio, List<Ficha>)>{
  'rodando': (
    torneio(antes: 10, aPartir: base, restante: mmss(14, 37)),
    fichasPadrao,
  ),
  'pausado': (
    torneio(antes: 10, aPartir: base, restante: mmss(14, 37), isRodando: false),
    fichasPadrao,
  ),
  'ultimo-minuto': (
    torneio(antes: 10, aPartir: base, restante: mmss(0, 42)),
    fichasPadrao,
  ),
  'intervalo': (
    torneio(
      antes: 10,
      aPartir: [intervalo, nivel(600, 1200, ante: 200), intervalo],
      restante: mmss(8, 15),
    ),
    fichasPadrao,
  ),
  'sem-ante': (
    torneio(
      antes: 3,
      aPartir: [nivel(100, 200), nivel(150, 300, ante: 25), intervalo],
      restante: mmss(11, 2),
    ),
    fichasPadrao,
  ),
  'valores-longos': (
    torneio(
      antes: 15,
      aPartir: [
        nivel(4000, 8000, ante: 1000, duracao: const Duration(minutes: 70)),
        nivel(5000, 10000, ante: 1000),
        intervalo,
      ],
      restante: mmss(5, 0, 1),
    ),
    fichasPadrao,
  ),
  'ultimo-nivel': (
    torneio(antes: 17, aPartir: ultimo, restante: mmss(17, 48)),
    fichasPadrao,
  ),
  'fim': (
    torneio(antes: 17, aPartir: ultimo, restante: Duration.zero),
    fichasPadrao,
  ),
  'sem-fichas': (
    torneio(antes: 10, aPartir: base, restante: mmss(14, 37)),
    const <Ficha>[],
  ),
};

const modos = {
  'contraste': ModoRelogio.altoContraste,
  'cassino': ModoRelogio.mesaCassino,
};

void main() {
  setUpAll(carregarFontes);

  for (final MapEntry(key: nomeModo, value: modo) in modos.entries) {
    for (final MapEntry(key: nomeEstado, value: (salvo, fichas))
        in estados.entries) {
      testWidgets('$nomeModo · $nomeEstado', (tester) async {
        await abrirApp(
          tester,
          salvo: salvo,
          fichas: fichas,
          configuracao: Configuracao(modo: modo),
          agora: agora,
          densidade: 1,
        );
        // O pulso do último minuto leva 1500 ms para chegar à cor de alerta.
        await tester.pump(DuracoesRelogio.pulsoUltimoMinuto);
        await expectLater(
          find.byType(AppRelogio),
          matchesGoldenFile('goldens/$nomeModo-$nomeEstado.png'),
        );
      });
    }
  }
}
