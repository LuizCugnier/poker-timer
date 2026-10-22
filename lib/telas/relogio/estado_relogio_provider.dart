import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/relogio_torneio.dart';
import 'torneio_notifier.dart';

// "Agora" atualizado a cada 250 ms: só serve para redesenhar (o estado vem do torneio).
final agoraProvider = NotifierProvider<AgoraNotifier, DateTime>(
  AgoraNotifier.new,
);

class AgoraNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => state = DateTime.now(),
    );
    ref.onDispose(timer.cancel);
    return DateTime.now();
  }
}

// Os widgets leem pedaços deste estado com `select`, para que cada um só
// reconstrua quando o seu pedaço muda (o texto do tempo, uma vez por segundo).
final estadoRelogioProvider = Provider<EstadoRelogio>(
  (ref) => calcularEstado(ref.watch(torneioProvider), ref.watch(agoraProvider)),
);
