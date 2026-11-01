import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/validacao.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/modelos/premiacao.dart';

void main() {
  test('inteiro', () {
    expect(validarInteiro('25'), isNull);
    expect(validarInteiro(' 25 '), isNull);
    expect(validarInteiro('0'), isNull);
    expect(validarInteiro(''), 'Informe um número');
    expect(validarInteiro('abc'), 'Informe um número');
    expect(validarInteiro(null), 'Informe um número');
    expect(validarInteiro('0', minimo: 1), 'Mínimo 1');
  });

  test('big blind não pode ser menor que o small blind', () {
    expect(validarBigBlind('100', '50'), isNull);
    expect(validarBigBlind('50', '50'), isNull);
    expect(validarBigBlind('40', '50'), 'Menor que o small blind');
    expect(validarBigBlind('0', '0'), 'Mínimo 1');
    expect(validarBigBlind('100', 'abc'), isNull);
  });

  test('estrutura precisa de um nível de jogo', () {
    const jogo = Nivel(
      smallBlind: 25,
      bigBlind: 50,
      duracao: Duration(minutes: 20),
    );
    const intervalo = Nivel.intervalo(Duration(minutes: 10));

    expect(validarNiveis([jogo, intervalo]), isNull);
    expect(validarNiveis([]), isNotNull);
    expect(validarNiveis([intervalo]), isNotNull);
  });

  test('premiação', () {
    Premiacao premiacao(
      TipoDivisao tipo,
      List<int> valores, [
      int total = 1000,
    ]) => Premiacao(total: total, tipo: tipo, valores: valores);
    const pct = TipoDivisao.porcentagem;
    const fixo = TipoDivisao.fixo;

    expect(validarPremiacao(premiacao(pct, [50, 30, 20])), isNull);
    expect(validarPremiacao(premiacao(fixo, [600, 400])), isNull);
    expect(validarPremiacao(premiacao(pct, [100], 0)), isNotNull);
    expect(validarPremiacao(premiacao(pct, [])), isNotNull);
    expect(validarPremiacao(premiacao(pct, List.filled(10, 10))), isNotNull);
    expect(validarPremiacao(premiacao(pct, [100, 0])), isNotNull);
    expect(validarPremiacao(premiacao(pct, [50, 40])), 'Soma 90% de 100%.');
    expect(validarPremiacao(premiacao(fixo, [600, 300])), 'Soma 900 de 1.000.');
  });
}
