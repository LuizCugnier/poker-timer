import '../modelos/nivel.dart';
import '../modelos/premiacao.dart';
import 'formatacao.dart';
import 'premiacao.dart';

// Validadores no formato do TextFormField: null = válido; senão, a mensagem de erro.
String? validarInteiro(String? texto, {int minimo = 0}) {
  final valor = int.tryParse(texto?.trim() ?? '');
  if (valor == null) return 'Informe um número';
  if (valor < minimo) return 'Mínimo $minimo';
  return null;
}

String? validarBigBlind(String? bigBlind, String? smallBlind) {
  final erro = validarInteiro(bigBlind, minimo: 1);
  if (erro != null) return erro;
  final sb = int.tryParse(smallBlind?.trim() ?? '');
  if (sb != null && int.parse(bigBlind!.trim()) < sb) {
    return 'Menor que o small blind';
  }
  return null;
}

String? validarNiveis(List<Nivel> niveis) {
  if (niveis.every((n) => n.isIntervalo)) {
    return 'A estrutura precisa de pelo menos um nível de jogo.';
  }
  return null;
}

String? validarPremiacao(Premiacao premiacao) {
  final Premiacao(:total, :tipo, :valores) = premiacao;
  if (total <= 0) return 'O total precisa ser maior que zero.';
  if (valores.isEmpty) return 'Informe pelo menos um premiado.';
  if (valores.length > Premiacao.maximoPremiados) {
    return 'No máximo ${Premiacao.maximoPremiados} premiados.';
  }
  if (valores.any((v) => v <= 0)) {
    return 'Prêmios precisam ser maiores que zero.';
  }
  final soma = somar(valores);
  return switch (tipo) {
    TipoDivisao.porcentagem when soma != 100 => 'Soma $soma% de 100%.',
    TipoDivisao.fixo when soma != total =>
      'Soma ${formatarValor(soma)} de ${formatarValor(total)}.',
    _ => null,
  };
}
