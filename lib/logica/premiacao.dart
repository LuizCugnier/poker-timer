import '../modelos/premiacao.dart';

// Prêmio de cada posição. Em porcentagem, arredonda para baixo e, se as
// porcentagens fecham 100, a sobra vai para o 1º lugar (a soma bate com o total).
List<int> calcularPremios(Premiacao premiacao) {
  final Premiacao(:total, :tipo, :valores) = premiacao;
  if (tipo == TipoDivisao.fixo) return [...valores];

  final premios = [for (final valor in valores) total * valor ~/ 100];
  if (premios.isNotEmpty && somar(valores) == 100) {
    premios[0] += total - somar(premios);
  }
  return premios;
}

// Valores fixos convertidos em porcentagem do total (ao trocar o tipo no editor).
// Se os valores fecham o total, a sobra do arredondamento vai para o 1º lugar.
List<int> converterParaPorcentagem(int total, List<int> valores) {
  final porcentagens = [for (final valor in valores) valor * 100 ~/ total];
  if (porcentagens.isNotEmpty && somar(valores) == total) {
    porcentagens[0] += 100 - somar(porcentagens);
  }
  return porcentagens;
}

int somar(List<int> valores) => valores.fold(0, (soma, v) => soma + v);
