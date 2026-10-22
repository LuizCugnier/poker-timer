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
