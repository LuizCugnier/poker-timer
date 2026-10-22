class Nivel {
  const Nivel({
    required this.smallBlind,
    required this.bigBlind,
    this.ante = 0,
    required this.duracao,
    this.isIntervalo = false,
  });

  const Nivel.intervalo(this.duracao)
    : smallBlind = 0,
      bigBlind = 0,
      ante = 0,
      isIntervalo = true;

  final int smallBlind;
  final int bigBlind;
  final int ante;
  final Duration duracao;
  final bool isIntervalo;

  Nivel copyWith({
    int? smallBlind,
    int? bigBlind,
    int? ante,
    Duration? duracao,
    bool? isIntervalo,
  }) {
    return Nivel(
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      ante: ante ?? this.ante,
      duracao: duracao ?? this.duracao,
      isIntervalo: isIntervalo ?? this.isIntervalo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'smallBlind': smallBlind,
      'bigBlind': bigBlind,
      'ante': ante,
      'duracao': duracao.inSeconds,
      'isIntervalo': isIntervalo,
    };
  }

  factory Nivel.fromJson(Map<String, dynamic> json) {
    return Nivel(
      smallBlind: json['smallBlind'] as int,
      bigBlind: json['bigBlind'] as int,
      ante: json['ante'] as int,
      duracao: Duration(seconds: json['duracao'] as int),
      isIntervalo: json['isIntervalo'] as bool,
    );
  }
}
