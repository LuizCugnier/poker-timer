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
      expect(avisosFuturos(torneio, t0), isEmpty);
    });

    test('do início: aviso de 1 minuto e troca para cada nível seguinte', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0);

      expect(avisos.map((a) => a.tipo), [
        TipoAviso.umMinuto,
        TipoAviso.troca,
        TipoAviso.umMinuto,
        TipoAviso.troca,
      ]);
      expect(avisos.map((a) => a.quando), [
        t0.add(minutos(9)),
        t0.add(minutos(10)),
        t0.add(minutos(14)),
        t0.add(minutos(15)),
      ]);
    });

    test('textos dizem o que vem, sem contar intervalos como nível', () {
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), t0);

      expect(avisos[0].titulo, '1 minuto para o intervalo');
      expect(avisos[1].titulo, 'INTERVALO');
      expect(avisos[1].texto, '5 minutos de pausa');
      expect(avisos[2].titulo, '1 minuto para o nível 2');
      expect(avisos[3].titulo, 'NÍVEL 2');
      expect(avisos[3].texto, '50 / 100 · ante 10');
    });

    test('o que já passou não é agendado', () {
      final agora = t0.add(minutos(9, 30));
      final avisos = avisosFuturos(rodandoDesdeT0(Duration.zero), agora);

      expect(avisos.first.tipo, TipoAviso.troca);
      expect(avisos.first.quando, t0.add(minutos(10)));
      expect(avisos, hasLength(3));
    });

    test('conta o tempo acumulado antes de retomar', () {
      final avisos = avisosFuturos(rodandoDesdeT0(minutos(12)), t0);

      expect(avisos.map((a) => a.quando), [
        t0.add(minutos(2)),
        t0.add(minutos(3)),
      ]);
    });

    test('no último nível não há mais avisos', () {
      expect(avisosFuturos(rodandoDesdeT0(minutos(20)), t0), isEmpty);
    });
  });

  group('som da transição', () {
    test('nada muda, nenhum som', () {
      expect(
        somDaTransicao(estadoEm(minutos(3)), estadoEm(minutos(3, 1))),
        isNull,
      );
    });

    test('entrar no último minuto toca o aviso', () {
      expect(
        somDaTransicao(estadoEm(minutos(8, 59)), estadoEm(minutos(9))),
        TipoAviso.umMinuto,
      );
    });

    test('dentro do último minuto, só toca uma vez', () {
      expect(
        somDaTransicao(estadoEm(minutos(9)), estadoEm(minutos(9, 1))),
        isNull,
      );
    });

    test('mudar de nível toca a troca', () {
      expect(
        somDaTransicao(estadoEm(minutos(9, 59)), estadoEm(minutos(10))),
        TipoAviso.troca,
      );
    });

    test('chegar ao fim da estrutura toca a troca', () {
      expect(
        somDaTransicao(estadoEm(minutos(24, 59)), estadoEm(minutos(25))),
        TipoAviso.troca,
      );
    });

    test('depois do fim, silêncio', () {
      expect(
        somDaTransicao(estadoEm(minutos(25)), estadoEm(minutos(26))),
        isNull,
      );
    });
  });
}
