import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorio.dart';
import '../../modelos/configuracao.dart';
import '../../theme/tema_relogio.dart';

final configuracaoProvider =
    NotifierProvider<ConfiguracaoNotifier, Configuracao>(
      ConfiguracaoNotifier.new,
    );

class ConfiguracaoNotifier extends Notifier<Configuracao> {
  @override
  Configuracao build() {
    return ref.watch(repositorioProvider).carregarConfiguracao() ??
        const Configuracao();
  }

  void salvar(Configuracao configuracao) {
    state = configuracao;
    ref.read(repositorioProvider).salvarConfiguracao(configuracao);
  }

  void mudarModo(ModoRelogio modo) => salvar(state.copyWith(modo: modo));

  void alternarAvisoMetade() =>
      salvar(state.copyWith(isAvisoMetade: !state.isAvisoMetade));

  void alternarAviso(int minutos) {
    final avisos = {...state.avisosMinutos};
    if (!avisos.remove(minutos)) avisos.add(minutos);
    salvar(state.copyWith(avisosMinutos: avisos.toList()..sort()));
  }
}

// Cores do modo escolhido; a troca de modo reflete na hora em todas as telas.
final coresProvider = Provider<CoresRelogio>(
  (ref) =>
      CoresRelogio.de(ref.watch(configuracaoProvider.select((c) => c.modo))),
);
