import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorio.dart';
import '../../logica/relogio_torneio.dart' as relogio;
import '../../modelos/estrutura.dart';
import '../../modelos/torneio.dart';
import '../estrutura/estrutura_notifier.dart';

final torneioProvider = NotifierProvider<TorneioNotifier, Torneio>(
  TorneioNotifier.new,
);

class TorneioNotifier extends Notifier<Torneio> {
  @override
  Torneio build() {
    return ref.watch(repositorioProvider).carregarTorneio() ??
        Torneio(estrutura: ref.read(estruturaProvider));
  }

  void iniciarOuPausar() {
    final agora = DateTime.now();
    _salvar(
      state.isRodando
          ? relogio.pausar(state, agora)
          : relogio.iniciar(state, agora),
    );
  }

  void avancarNivel() => _salvar(relogio.avancarNivel(state, DateTime.now()));

  void voltarNivel() => _salvar(relogio.voltarNivel(state, DateTime.now()));

  void ajustarTempoRestante(Duration delta) =>
      _salvar(relogio.ajustarTempoRestante(state, delta, DateTime.now()));

  void reiniciar() => _salvar(Torneio(estrutura: ref.read(estruturaProvider)));

  // Um torneio que ainda não começou passa a usar a estrutura nova; um em andamento,
  // só depois de Reiniciar. Devolve se trocou.
  bool usarEstruturaSeNaoComecou(Estrutura estrutura) {
    if (state.isRodando || state.decorridoAcumulado > Duration.zero) {
      return false;
    }
    _salvar(Torneio(estrutura: estrutura));
    return true;
  }

  void _salvar(Torneio torneio) {
    state = torneio;
    ref.read(repositorioProvider).salvarTorneio(torneio);
  }
}
