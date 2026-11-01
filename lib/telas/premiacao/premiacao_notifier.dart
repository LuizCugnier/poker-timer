import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorio.dart';
import '../../modelos/premiacao.dart';

// null = sem premiação (o painel não aparece no relógio).
final premiacaoProvider = NotifierProvider<PremiacaoNotifier, Premiacao?>(
  PremiacaoNotifier.new,
);

class PremiacaoNotifier extends Notifier<Premiacao?> {
  @override
  Premiacao? build() => ref.watch(repositorioProvider).carregarPremiacao();

  void salvar(Premiacao premiacao) {
    state = premiacao;
    ref.read(repositorioProvider).salvarPremiacao(premiacao);
  }

  void remover() {
    state = null;
    ref.read(repositorioProvider).removerPremiacao();
  }
}
