import '../theme/tema_relogio.dart' show ModoRelogio;

class Configuracao {
  const Configuracao({
    this.avisosMinutos = const [1],
    this.modo = ModoRelogio.altoContraste,
  });

  // Quantos minutos antes de cada troca de nível toca o aviso (vazio = só na troca).
  final List<int> avisosMinutos;
  final ModoRelogio modo;

  static const opcoesAvisoMinutos = [1, 2, 3, 5, 10];

  List<Duration> get antecedencias => [
    for (final minutos in avisosMinutos) Duration(minutes: minutos),
  ];

  Configuracao copyWith({List<int>? avisosMinutos, ModoRelogio? modo}) {
    return Configuracao(
      avisosMinutos: avisosMinutos ?? this.avisosMinutos,
      modo: modo ?? this.modo,
    );
  }

  Map<String, dynamic> toJson() {
    return {'avisosMinutos': avisosMinutos, 'modo': modo.name};
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
    );
  }
}
