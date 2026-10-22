import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/formatacao.dart';

void main() {
  test('valores com separador de milhar', () {
    expect(formatarValor(0), '0');
    expect(formatarValor(25), '25');
    expect(formatarValor(500), '500');
    expect(formatarValor(1000), '1.000');
    expect(formatarValor(10000), '10.000');
    expect(formatarValor(1500000), '1.500.000');
  });

  test('blinds', () {
    expect(formatarBlinds(500, 1000), '500 / 1.000');
  });

  test('tempo em mm:ss, com hora quando passa de 60 minutos', () {
    expect(formatarTempo(const Duration(minutes: 20)), '20:00');
    expect(formatarTempo(const Duration(minutes: 5, seconds: 7)), '05:07');
    expect(formatarTempo(Duration.zero), '00:00');
    expect(
      formatarTempo(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  test('fração de segundo arredonda para cima', () {
    expect(
      formatarTempo(const Duration(minutes: 19, seconds: 59, milliseconds: 1)),
      '20:00',
    );
    expect(formatarTempo(const Duration(milliseconds: 400)), '00:01');
  });
}
