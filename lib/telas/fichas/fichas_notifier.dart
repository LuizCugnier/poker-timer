import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorio.dart';
import '../../modelos/ficha.dart';

final fichasProvider = NotifierProvider<FichasNotifier, List<Ficha>>(
  FichasNotifier.new,
);

class FichasNotifier extends Notifier<List<Ficha>> {
  @override
  List<Ficha> build() {
    return ref.watch(repositorioProvider).carregarFichas() ?? fichasPadrao;
  }

  // Sempre em ordem crescente de valor, como aparecem na lateral do relógio.
  void salvar(List<Ficha> fichas) {
    state = [...fichas]..sort((a, b) => a.valor.compareTo(b.valor));
    ref.read(repositorioProvider).salvarFichas(state);
  }
}
