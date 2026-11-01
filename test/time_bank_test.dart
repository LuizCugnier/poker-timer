import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/logica/time_bank.dart';

void main() {
  final inicio = DateTime(2026, 10, 31, 20);
  const trinta = Duration(seconds: 30);

  Duration? restanteApos(Duration passado) =>
      restanteTimeBank(inicio, trinta, inicio.add(passado));

  test('parado não tem restante', () {
    expect(restanteTimeBank(null, trinta, inicio), isNull);
  });

  test('contando desconta o tempo passado', () {
    expect(restanteApos(Duration.zero), trinta);
    expect(
      restanteApos(const Duration(seconds: 7)),
      const Duration(seconds: 23),
    );
  });

  test('ao chegar em zero volta a parado', () {
    expect(restanteApos(trinta), isNull);
    expect(restanteApos(const Duration(minutes: 5)), isNull);
  });

  test('agora antes do início não passa da duração', () {
    expect(restanteApos(const Duration(seconds: -10)), trinta);
  });
}
