import '../modelos/nivel.dart';

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
