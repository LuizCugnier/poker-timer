class Configuracao {
  const Configuracao({this.avisosMinutos = const [1]});

  // Quantos minutos antes de cada troca de nível toca o aviso (vazio = só na troca).
  final List<int> avisosMinutos;

  static const opcoesAvisoMinutos = [1, 2, 3, 5, 10];

  List<Duration> get antecedencias => [
    for (final minutos in avisosMinutos) Duration(minutes: minutos),
  ];

  Configuracao copyWith({List<int>? avisosMinutos}) {
    return Configuracao(avisosMinutos: avisosMinutos ?? this.avisosMinutos);
  }

  Map<String, dynamic> toJson() {
    return {'avisosMinutos': avisosMinutos};
  }

  factory Configuracao.fromJson(Map<String, dynamic> json) {
    return Configuracao(
      avisosMinutos: [
        for (final minutos in json['avisosMinutos'] as List) minutos as int,
      ],
    );
  }
}
