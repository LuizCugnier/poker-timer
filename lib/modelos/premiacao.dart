enum TipoDivisao { porcentagem, fixo }

class Premiacao {
  const Premiacao({
    required this.total,
    required this.tipo,
    required this.valores,
    this.jackpot = 0,
  });

  final int total;
  final TipoDivisao tipo;
  // Um valor por posição (% ou valor fixo, conforme o tipo); número de premiados = tamanho da lista.
  final List<int> valores;
  final int jackpot;

  static const maximoPremiados = 9;

  Premiacao copyWith({
    int? total,
    TipoDivisao? tipo,
    List<int>? valores,
    int? jackpot,
  }) {
    return Premiacao(
      total: total ?? this.total,
      tipo: tipo ?? this.tipo,
      valores: valores ?? this.valores,
      jackpot: jackpot ?? this.jackpot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'tipo': tipo.name,
      'valores': valores,
      'jackpot': jackpot,
    };
  }

  factory Premiacao.fromJson(Map<String, dynamic> json) {
    return Premiacao(
      total: json['total'] as int,
      tipo:
          TipoDivisao.values.asNameMap()[json['tipo']] ??
          TipoDivisao.porcentagem,
      valores: [for (final valor in json['valores'] as List) valor as int],
      jackpot: json['jackpot'] as int? ?? 0,
    );
  }
}
