import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logica/avisos.dart';

final sonsProvider = Provider<Sons>((ref) => Sons());

class Sons {
  // late: o player só toca o canal nativo no primeiro som (os testes nunca chegam aqui).
  late final _player = AudioPlayer()
    ..setAudioContext(
      // Abaixa a música que estiver tocando na mesa em vez de pausá-la.
      AudioContextConfig(focus: AudioContextConfigFocus.duckOthers).build(),
    );

  Future<void> tocar(TipoAviso tipo) {
    final arquivo = tipo == TipoAviso.troca ? 'troca.wav' : 'aviso.wav';
    return _player.play(AssetSource('sons/$arquivo'));
  }
}
