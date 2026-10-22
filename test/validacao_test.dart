import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/validacao.dart';
import 'package:poker_timer/modelos/nivel.dart';

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
}
