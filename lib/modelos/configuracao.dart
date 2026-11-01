import '../theme/tema_relogio.dart' show ModoRelogio;

class Configuracao {
  const Configuracao({
    this.avisosMinutos = const [1],
    this.modo = ModoRelogio.altoContraste,
    this.isAvisoMetade = false,
    this.timeBank = const Duration(seconds: 30),
  });

  // Quantos minutos antes de cada troca de nível toca o aviso (vazio = só na troca).
  final List<int> avisosMinutos;
  final ModoRelogio modo;

  // Aviso também na metade de cada nível de jogo (o chip "1/2" nas configurações).
  final bool isAvisoMetade;

  // Tempo do time bank; no JSON vai em segundos.
  final Duration timeBank;

  static const segundosMinimoTimeBank = 10;

  static const opcoesAvisoMinutos = [1, 2, 3, 5, 10];

  List<Duration> get antecedencias => [
    for (final minutos in avisosMinutos) Duration(minutes: minutos),
  ];

  Configuracao copyWith({
    List<int>? avisosMinutos,
    ModoRelogio? modo,
    bool? isAvisoMetade,
    Duration? timeBank,
  }) {
    return Configuracao(
      avisosMinutos: avisosMinutos ?? this.avisosMinutos,
      modo: modo ?? this.modo,
      isAvisoMetade: isAvisoMetade ?? this.isAvisoMetade,
      timeBank: timeBank ?? this.timeBank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avisosMinutos': avisosMinutos,
      'modo': modo.name,
      'isAvisoMetade': isAvisoMetade,
      'timeBank': timeBank.inSeconds,
    };
  }

  // Campos ausentes (configuração salva por uma versão anterior) ficam no padrão.
  factory Configuracao.fromJson(Map<String, dynamic> json) {
    return Configuracao(
      avisosMinutos: [
        for (final minutos in json['avisosMinutos'] as List) minutos as int,
      ],
      modo:
          ModoRelogio.values.asNameMap()[json['modo']] ??
          ModoRelogio.altoContraste,
      isAvisoMetade: json['isAvisoMetade'] as bool? ?? false,
      timeBank: Duration(seconds: json['timeBank'] as int? ?? 30),
    );
  }
}
