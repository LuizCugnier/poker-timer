import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/modelos/torneio.dart';

// Linha do tempo (minutos de jogo):
// 0  [25/50]  10  [50/100]  20  [INTERVALO]  25  [100/200]  40  [INTERVALO]  45  [200/400]  55
const estrutura = Estrutura(
  nome: 'Teste',
  niveis: [
    Nivel(smallBlind: 25, bigBlind: 50, duracao: Duration(minutes: 10)),
    Nivel(smallBlind: 50, bigBlind: 100, duracao: Duration(minutes: 10)),
    Nivel.intervalo(Duration(minutes: 5)),
    Nivel(
      smallBlind: 100,
      bigBlind: 200,
      ante: 25,
      duracao: Duration(minutes: 15),
    ),
    Nivel.intervalo(Duration(minutes: 5)),
    Nivel(
      smallBlind: 200,
      bigBlind: 400,
      ante: 50,
      duracao: Duration(minutes: 10),
    ),
  ],
);

final t0 = DateTime(2026, 10, 21, 20);

Duration minutos(int m, [int s = 0]) => Duration(minutes: m, seconds: s);

Torneio pausadoEm(Duration decorrido) =>
    Torneio(estrutura: estrutura, decorridoAcumulado: decorrido);

Torneio rodandoDesdeT0(Duration acumulado) => Torneio(
  estrutura: estrutura,
  decorridoAcumulado: acumulado,
  rodandoDesde: t0,
);

EstadoRelogio estadoEm(Duration decorrido) =>
    calcularEstado(pausadoEm(decorrido), t0);

void main() {
  group('1. tempo decorrido', () {
    test('torneio novo começa em zero', () {
      expect(
        tempoDecorrido(const Torneio(estrutura: estrutura), t0),
        Duration.zero,
      );
    });

    test('pausado devolve o acumulado, seja qual for o agora', () {
      final torneio = pausadoEm(minutos(7));
      expect(tempoDecorrido(torneio, t0), minutos(7));
      expect(
        tempoDecorrido(torneio, t0.add(const Duration(hours: 3))),
        minutos(7),
      );
    });

    test('rodando soma o trecho desde rodandoDesde', () {
      final torneio = rodandoDesdeT0(minutos(5));
      expect(tempoDecorrido(torneio, t0.add(minutos(2, 30))), minutos(7, 30));
    });

    test('reabrir o app horas depois recalcula sem escorregar', () {
      final torneio = rodandoDesdeT0(Duration.zero);
      expect(
        tempoDecorrido(torneio, t0.add(const Duration(hours: 2))),
        const Duration(hours: 2),
      );
    });
  });

  group('2. nível atual e tempo restante', () {
    test('início dos níveis', () {
      expect(inicioDoNivel(estrutura, 0), Duration.zero);
      expect(inicioDoNivel(estrutura, 1), minutos(10));
      expect(inicioDoNivel(estrutura, 3), minutos(25));
      expect(inicioDoNivel(estrutura, 6), minutos(55));
    });

    test('no início, primeiro nível com tempo cheio', () {
      final estado = estadoEm(Duration.zero);
      expect(estado.indiceNivel, 0);
      expect(estado.nivelAtual.bigBlind, 50);
      expect(estado.tempoRestante, minutos(10));
    });

    test('no meio do primeiro nível', () {
      final estado = estadoEm(minutos(3, 30));
      expect(estado.indiceNivel, 0);
      expect(estado.tempoRestante, minutos(6, 30));
    });

    test('na fronteira exata, já está no nível seguinte', () {
      final estado = estadoEm(minutos(10));
      expect(estado.indiceNivel, 1);
      expect(estado.nivelAtual.bigBlind, 100);
      expect(estado.tempoRestante, minutos(10));
    });

    test('dentro do intervalo', () {
      final estado = estadoEm(minutos(22));
      expect(estado.indiceNivel, 2);
      expect(estado.nivelAtual.isIntervalo, isTrue);
      expect(estado.tempoRestante, minutos(3));
    });

    test('depois do intervalo', () {
      final estado = estadoEm(minutos(30));
      expect(estado.indiceNivel, 3);
      expect(estado.nivelAtual.ante, 25);
      expect(estado.tempoRestante, minutos(10));
    });

    test('com o relógio rodando', () {
      final estado = calcularEstado(
        rodandoDesdeT0(minutos(5)),
        t0.add(minutos(7)),
      );
      expect(estado.indiceNivel, 1);
      expect(estado.tempoRestante, minutos(8));
    });
  });

  group('3. próximo nível e próximo intervalo', () {
    test('próximo nível é o seguinte da lista', () {
      expect(estadoEm(minutos(3)).proximoNivel?.bigBlind, 100);
      expect(estadoEm(minutos(12)).proximoNivel?.isIntervalo, isTrue);
    });

    test('no último nível não há próximo', () {
      expect(estadoEm(minutos(50)).proximoNivel, isNull);
    });

    test('tempo até o próximo intervalo', () {
      expect(estadoEm(minutos(3)).tempoAteProximoIntervalo, minutos(17));
      expect(estadoEm(minutos(30)).tempoAteProximoIntervalo, minutos(10));
    });

    test('durante um intervalo, conta até o intervalo seguinte', () {
      expect(estadoEm(minutos(22)).tempoAteProximoIntervalo, minutos(18));
    });

    test('sem intervalo à frente, é null', () {
      expect(estadoEm(minutos(42)).tempoAteProximoIntervalo, isNull);
      expect(estadoEm(minutos(50)).tempoAteProximoIntervalo, isNull);
    });
  });

  group('4. pausar e retomar', () {
    test('iniciar começa a contar a partir de agora', () {
      final torneio = iniciar(const Torneio(estrutura: estrutura), t0);
      expect(torneio.rodandoDesde, t0);
      expect(torneio.decorridoAcumulado, Duration.zero);
    });

    test('iniciar quando já está rodando não muda nada', () {
      final torneio = iniciar(rodandoDesdeT0(minutos(5)), t0.add(minutos(3)));
      expect(torneio.rodandoDesde, t0);
      expect(torneio.decorridoAcumulado, minutos(5));
    });

    test('pausar guarda o trecho corrido e para', () {
      final torneio = pausar(rodandoDesdeT0(minutos(5)), t0.add(minutos(3)));
      expect(torneio.rodandoDesde, isNull);
      expect(torneio.decorridoAcumulado, minutos(8));
    });

    test('pausar quando já está pausado não muda nada', () {
      final torneio = pausar(pausadoEm(minutos(5)), t0.add(minutos(3)));
      expect(torneio.rodandoDesde, isNull);
      expect(torneio.decorridoAcumulado, minutos(5));
    });

    test('ciclo completo: o tempo pausado não conta', () {
      var torneio = iniciar(const Torneio(estrutura: estrutura), t0);
      torneio = pausar(torneio, t0.add(minutos(5)));
      torneio = iniciar(torneio, t0.add(minutos(8)));
      expect(tempoDecorrido(torneio, t0.add(minutos(10))), minutos(7));
    });

    test('a estrutura é mantida', () {
      final torneio = pausar(
        iniciar(const Torneio(estrutura: estrutura), t0),
        t0,
      );
      expect(torneio.estrutura.nome, 'Teste');
    });
  });

  group('5. pular e voltar nível', () {
    test('ir para um nível coloca o relógio no começo dele', () {
      final torneio = irParaNivel(pausadoEm(minutos(3)), 3, t0);
      expect(torneio.decorridoAcumulado, minutos(25));
      expect(torneio.isRodando, isFalse);
    });

    test('avançar pausado vai ao começo do próximo e continua pausado', () {
      final torneio = avancarNivel(pausadoEm(minutos(3)), t0);
      expect(tempoDecorrido(torneio, t0), minutos(10));
      expect(torneio.isRodando, isFalse);
    });

    test('avançar rodando continua rodando a partir do começo do próximo', () {
      final agora = t0.add(minutos(3));
      final torneio = avancarNivel(rodandoDesdeT0(Duration.zero), agora);
      expect(torneio.isRodando, isTrue);

      final estado = calcularEstado(torneio, agora);
      expect(estado.indiceNivel, 1);
      expect(estado.tempoRestante, minutos(10));

      final umMinutoDepois = calcularEstado(torneio, agora.add(minutos(1)));
      expect(umMinutoDepois.tempoRestante, minutos(9));
    });

    test('avançar no último nível não muda nada', () {
      final torneio = avancarNivel(pausadoEm(minutos(50)), t0);
      expect(torneio.decorridoAcumulado, minutos(50));
    });

    test('voltar vai ao começo do nível anterior', () {
      final torneio = voltarNivel(pausadoEm(minutos(13)), t0);
      expect(torneio.decorridoAcumulado, Duration.zero);
    });

    test('voltar a partir do intervalo vai ao começo do nível antes dele', () {
      final torneio = voltarNivel(pausadoEm(minutos(22)), t0);
      expect(torneio.decorridoAcumulado, minutos(10));
    });

    test('voltar no primeiro nível vai ao começo dele', () {
      final torneio = voltarNivel(pausadoEm(minutos(4)), t0);
      expect(torneio.decorridoAcumulado, Duration.zero);
    });

    test('voltar rodando continua rodando', () {
      final agora = t0.add(minutos(13));
      final torneio = voltarNivel(rodandoDesdeT0(Duration.zero), agora);
      expect(torneio.isRodando, isTrue);
      expect(tempoDecorrido(torneio, agora), Duration.zero);
    });
  });

  group('6. ajustar ±1 minuto', () {
    test('+1 minuto dá mais tempo ao nível', () {
      final torneio = ajustarTempoRestante(
        pausadoEm(minutos(3)),
        minutos(1),
        t0,
      );
      expect(calcularEstado(torneio, t0).tempoRestante, minutos(8));
    });

    test('-1 minuto tira tempo do nível', () {
      final torneio = ajustarTempoRestante(
        pausadoEm(minutos(3)),
        minutos(-1),
        t0,
      );
      expect(calcularEstado(torneio, t0).tempoRestante, minutos(6));
    });

    test('o decorrido nunca fica negativo', () {
      final torneio = ajustarTempoRestante(
        pausadoEm(minutos(0, 30)),
        minutos(1),
        t0,
      );
      expect(torneio.decorridoAcumulado, Duration.zero);
    });

    test('rodando, o ajuste vale e o relógio continua', () {
      final agora = t0.add(minutos(3));
      final torneio = ajustarTempoRestante(
        rodandoDesdeT0(Duration.zero),
        minutos(1),
        agora,
      );
      expect(torneio.isRodando, isTrue);
      expect(calcularEstado(torneio, agora).tempoRestante, minutos(8));
      expect(
        calcularEstado(torneio, agora.add(minutos(2))).tempoRestante,
        minutos(6),
      );
    });
  });

  group('7. fim da estrutura', () {
    test('antes do fim, não terminou', () {
      expect(estadoEm(minutos(54, 59)).isTerminado, isFalse);
    });

    test('no fim exato, para no último nível com 00:00', () {
      final estado = estadoEm(minutos(55));
      expect(estado.isTerminado, isTrue);
      expect(estado.indiceNivel, 5);
      expect(estado.tempoRestante, Duration.zero);
      expect(estado.proximoNivel, isNull);
      expect(estado.tempoAteProximoIntervalo, isNull);
    });

    test('muito depois do fim, continua parado no último nível', () {
      final estado = estadoEm(const Duration(hours: 5));
      expect(estado.isTerminado, isTrue);
      expect(estado.indiceNivel, 5);
      expect(estado.tempoRestante, Duration.zero);
    });

    test('avançar depois do fim não muda nada', () {
      final torneio = avancarNivel(pausadoEm(const Duration(hours: 5)), t0);
      expect(torneio.decorridoAcumulado, const Duration(hours: 5));
    });
  });
}
