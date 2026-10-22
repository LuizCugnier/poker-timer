import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorio.dart';
import '../../modelos/estrutura.dart';

// A estrutura usada pelo próximo torneio. O torneio em andamento tem a sua própria cópia.
final estruturaProvider = NotifierProvider<EstruturaNotifier, Estrutura>(
  EstruturaNotifier.new,
);

class EstruturaNotifier extends Notifier<Estrutura> {
  @override
  Estrutura build() {
    return ref.watch(repositorioProvider).carregarEstrutura() ??
        Estrutura.padrao;
  }

  void salvar(Estrutura estrutura) {
    state = estrutura;
    ref.read(repositorioProvider).salvarEstrutura(estrutura);
  }
}
