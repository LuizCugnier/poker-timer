import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/premiacao.dart';
import 'package:poker_timer/modelos/premiacao.dart';

void main() {
  Premiacao porcentagem(int total, List<int> valores) =>
      Premiacao(total: total, tipo: TipoDivisao.porcentagem, valores: valores);

  test('porcentagem divide o total', () {
    expect(calcularPremios(porcentagem(1000, [50, 30, 20])), [500, 300, 200]);
  });

  test('sobra do arredondamento vai para o 1º lugar', () {
    expect(calcularPremios(porcentagem(1250, [33, 33, 34])), [413, 412, 425]);
  });

  test('porcentagens que não fecham 100 não recebem sobra', () {
    expect(calcularPremios(porcentagem(1000, [50, 40])), [500, 400]);
  });

  test('um premiado leva tudo', () {
    expect(calcularPremios(porcentagem(700, [100])), [700]);
  });

  test('valor fixo é o próprio valor', () {
    const fixo = Premiacao(
      total: 1000,
      tipo: TipoDivisao.fixo,
      valores: [600, 400],
    );
    expect(calcularPremios(fixo), [600, 400]);
  });

  test('sem premiados, sem prêmios', () {
    expect(calcularPremios(porcentagem(1000, [])), isEmpty);
  });

  test('valores fixos viram porcentagem; a sobra vai para o 1º', () {
    expect(converterParaPorcentagem(1000, [600, 400]), [60, 40]);
    expect(converterParaPorcentagem(900, [300, 300, 300]), [34, 33, 33]);
    expect(converterParaPorcentagem(1000, [500, 300]), [50, 30]);
  });
}
