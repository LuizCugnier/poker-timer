import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/avisos.dart';
import 'package:poker_timer/logica/relogio_torneio.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/modelos/torneio.dart';

// 0 [25/50] 10 [INTERVALO] 15 [50/100 ante 10] 25
const estrutura = Estrutura(
  nome: 'Teste',
  niveis: [
    Nivel(smallBlind: 25, bigBlind: 50, duracao: Duration(minutes: 10)),
    Nivel.intervalo(Duration(minutes: 5)),
    Nivel(
      smallBlind: 50,
      bigBlind: 100,
      ante: 10,
      duracao: Duration(minutes: 10),
    ),
  ],
);

final t0 = DateTime(2026, 10, 21, 20);

Duration minutos(int m, [int s = 0]) => Duration(minutes: m, seconds: s);

const umMinuto = [Duration(minutes: 1)];

Torneio rodandoDesdeT0(Duration acumulado) => Torneio(
  estrutura: estrutura,
  decorridoAcumulado: acumulado,
  rodandoDesde: t0,
);

EstadoRelogio estadoEm(Duration decorrido) => calcularEstado(
  Torneio(estrutura: estrutura, decorridoAcumulado: decorrido),
  t0,
);

void main() {
  group('avisos futuros', () {
    test('pausado não agenda nada', () {
      const torneio = Torneio(estrutura: estrutura);
      expect(avisosFuturos(torneio, t0, umMinuto), isEmpty);
    });

    test('aviso de 1 minuto e troca para cada nível seguinte e o fim', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0, umMinuto);

      expect(avisos.map((a) => a.tipo), [
        TipoAviso.aviso,
        TipoAviso.troca,
        TipoAviso.aviso,
        TipoAviso.troca,
        TipoAviso.aviso,
        TipoAviso.troca,
      ]);
      expect(avisos.map((a) => a.quando), [
        t0.add(minutos(9)),
        t0.add(minutos(10)),
        t0.add(minutos(14)),
        t0.add(minutos(15)),
        t0.add(minutos(24)),
        t0.add(minutos(25)),
      ]);
    });

    test('textos dizem o que vem, sem contar intervalos como nível', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0, umMinuto);

      expect(avisos[0].titulo, '1 minuto para o intervalo');
      expect(avisos[1].titulo, 'INTERVALO');
      expect(avisos[1].texto, '5 minutos de pausa');
      expect(avisos[2].titulo, '1 minuto para o nível 2');
      expect(avisos[3].titulo, 'NÍVEL 2');
      expect(avisos[3].texto, '50 / 100 · ante 10');
      expect(avisos[4].titulo, '1 minuto para o fim da estrutura');
      expect(avisos[5].titulo, 'FIM DA ESTRUTURA');
    });

    test('várias antecedências, em ordem de horário', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0, const [
        Duration(minutes: 1),
        Duration(minutes: 5),
      ]);

      expect(avisos.take(3).map((a) => a.quando), [
        t0.add(minutos(5)),
        t0.add(minutos(9)),
        t0.add(minutos(10)),
      ]);
      expect(avisos[0].titulo, '5 minutos para o intervalo');
      expect(avisos[1].titulo, '1 minuto para o intervalo');
    });

    test('aviso maior ou igual ao nível que termina não é agendado', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0, const [
        Duration(minutes: 5),
      ]);

      // O intervalo dura 5 minutos: não há "5 minutos para o nível 2".
      expect(avisos.map((a) => a.titulo), [
        '5 minutos para o intervalo',
        'INTERVALO',
        'NÍVEL 2',
        '5 minutos para o fim da estrutura',
        'FIM DA ESTRUTURA',
      ]);
    });

    test('sem antecedências, só as trocas', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0, const []);
      expect(avisos.map((a) => a.tipo), everyElement(TipoAviso.troca));
      expect(avisos, hasLength(3));
    });

    test('o que já passou não é agendado', () {
      final agora = t0.add(minutos(9, 30));
      final avisos = avisosFuturos(
        rodandoDesdeT0(Duration.zero),
        agora,
        umMinuto,
      );

      expect(avisos.first.tipo, TipoAviso.troca);
      expect(avisos.first.quando, t0.add(minutos(10)));
      expect(avisos, hasLength(5));
    });

    test('conta o tempo acumulado antes de retomar', () {
      final avisos = avisosFuturos(rodandoDesdeT0(minutos(12)), t0, umMinuto);

      expect(avisos.map((a) => a.quando), [
        t0.add(minutos(2)),
        t0.add(minutos(3)),
        t0.add(minutos(12)),
        t0.add(minutos(13)),
      ]);
    });

    test('no último nível, só os avisos do fim da estrutura', () {
      final avisos = avisosFuturos(rodandoDesdeT0(minutos(20)), t0, umMinuto);

      expect(avisos.map((a) => a.quando), [
        t0.add(minutos(4)),
        t0.add(minutos(5)),
      ]);
      expect(avisos.last.titulo, 'FIM DA ESTRUTURA');
    });

    test('depois do fim da estrutura não há mais avisos', () {
      expect(avisosFuturos(rodandoDesdeT0(minutos(25)), t0, umMinuto), isEmpty);
    });
  });

  group('som da transição', () {
    TipoAviso? som(Duration antes, Duration depois, [List<Duration>? avisos]) =>
        somDaTransicao(estadoEm(antes), estadoEm(depois), avisos ?? umMinuto);

    test('nada muda, nenhum som', () {
      expect(som(minutos(3), minutos(3, 1)), isNull);
    });

    test('cruzar a antecedência toca o aviso', () {
      expect(som(minutos(8, 59), minutos(9)), TipoAviso.aviso);
    });

    test('depois de cruzar, só toca uma vez', () {
      expect(som(minutos(9), minutos(9, 1)), isNull);
    });

    test('cada antecedência configurada toca', () {
      const avisos = [Duration(minutes: 1), Duration(minutes: 5)];
      expect(som(minutos(4, 59), minutos(5), avisos), TipoAviso.aviso);
      expect(som(minutos(6), minutos(6, 1), avisos), isNull);
      expect(som(minutos(8, 59), minutos(9), avisos), TipoAviso.aviso);
    });

    test('antecedência maior ou igual ao nível não toca', () {
      // Intervalo de 5 minutos (10 a 15): o aviso de 5 minutos cairia no começo dele.
      expect(
        som(minutos(10), minutos(10, 1), const [Duration(minutes: 5)]),
        isNull,
      );
    });

    test('sem antecedências, não há aviso', () {
      expect(som(minutos(8, 59), minutos(9), const []), isNull);
    });

    test('mudar de nível toca a troca', () {
      expect(som(minutos(9, 59), minutos(10)), TipoAviso.troca);
    });

    test('chegar ao fim da estrutura toca a troca', () {
      expect(som(minutos(24, 59), minutos(25)), TipoAviso.troca);
    });

    test('depois do fim, silêncio', () {
      expect(som(minutos(25), minutos(26)), isNull);
    });
  });
}
