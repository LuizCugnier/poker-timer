import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/time_bank.dart';
import '../configuracoes/configuracao_notifier.dart';
import 'estado_relogio_provider.dart';

// Quando o time bank começou a contar; null = parado. Não é salvo: uma decisão
// de alguns segundos não precisa sobreviver ao app fechado.
final timeBankProvider = NotifierProvider<TimeBankNotifier, DateTime?>(
  TimeBankNotifier.new,
);

class TimeBankNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void iniciar() => state = DateTime.now();

  void parar() => state = null;
}

// Quanto falta, recalculado a cada redesenho; null = parado.
final restanteTimeBankProvider = Provider<Duration?>(
  (ref) => restanteTimeBank(
    ref.watch(timeBankProvider),
    ref.watch(configuracaoProvider.select((c) => c.timeBank)),
    ref.watch(agoraProvider),
  ),
);
