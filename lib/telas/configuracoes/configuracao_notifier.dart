import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorio.dart';
import '../../modelos/configuracao.dart';

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

  void alternarAviso(int minutos) {
    final avisos = {...state.avisosMinutos};
    if (!avisos.remove(minutos)) avisos.add(minutos);
    salvar(state.copyWith(avisosMinutos: avisos.toList()..sort()));
  }
}
