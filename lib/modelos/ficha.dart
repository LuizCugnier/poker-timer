class Ficha {
  const Ficha({required this.valor, required this.cor, required this.rotulo});

  final int valor;

  // ARGB (0xFFRRGGBB). Na tela vira Color(cor); assim o modelo não depende do Flutter.
  final int cor;
  final String rotulo;

  Ficha copyWith({int? valor, int? cor, String? rotulo}) {
    return Ficha(
      valor: valor ?? this.valor,
      cor: cor ?? this.cor,
      rotulo: rotulo ?? this.rotulo,
    );
  }

  Map<String, dynamic> toJson() {
    return {'valor': valor, 'cor': cor, 'rotulo': rotulo};
  }

  factory Ficha.fromJson(Map<String, dynamic> json) {
    return Ficha(
      valor: json['valor'] as int,
      cor: json['cor'] as int,
      rotulo: json['rotulo'] as String,
    );
  }
}

const fichasPadrao = [
  Ficha(valor: 25, cor: 0xFFFFFFFF, rotulo: 'Branca'),
  Ficha(valor: 100, cor: 0xFFD32F2F, rotulo: 'Vermelha'),
  Ficha(valor: 500, cor: 0xFF388E3C, rotulo: 'Verde'),
  Ficha(valor: 1000, cor: 0xFF212121, rotulo: 'Preta'),
];

// Cores oferecidas no editor de fichas.
const coresFicha = [
  0xFFFFFFFF, // branca
  0xFFD32F2F, // vermelha
  0xFF388E3C, // verde
  0xFF212121, // preta
  0xFF1976D2, // azul
  0xFFFBC02D, // amarela
  0xFF7B1FA2, // roxa
  0xFFF57C00, // laranja
  0xFFEC407A, // rosa
  0xFF757575, // cinza
  0xFF6D4C41, // marrom
  0xFF4FC3F7, // azul-claro
];
