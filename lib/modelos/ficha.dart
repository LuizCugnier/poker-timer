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
  Ficha(valor: 25, cor: 0xFFF2F0EA, rotulo: 'Branca'),
  Ficha(valor: 100, cor: 0xFFD23B3B, rotulo: 'Vermelha'),
  Ficha(valor: 500, cor: 0xFF2E9B5B, rotulo: 'Verde'),
  Ficha(valor: 1000, cor: 0xFF111113, rotulo: 'Preta'),
];

// Cores oferecidas no editor de fichas, na ordem da grade 6×2 do design.
const coresFicha = [
  0xFFF2F0EA, // branca
  0xFFD23B3B, // vermelha
  0xFF2E9B5B, // verde
  0xFF111113, // preta
  0xFF2F6FD6, // azul
  0xFFE8C33A, // amarela
  0xFFE8782C, // laranja
  0xFF7B4BC4, // roxa
  0xFFE0619A, // rosa
  0xFF8A5A3B, // marrom
  0xFF8E9196, // cinza
  0xFF5BC0EB, // azul-claro
];
