import 'estrutura.dart';

class Torneio {
  const Torneio({
    required this.estrutura,
    this.decorridoAcumulado = Duration.zero,
    this.rodandoDesde,
  });

  // Cópia da estrutura: editar a estrutura salva não mexe no torneio em andamento.
  final Estrutura estrutura;
  final Duration decorridoAcumulado;
  final DateTime? rodandoDesde;

  bool get isRodando => rodandoDesde != null;

  // rodandoDesde: null mantém o valor atual; para pausar, use pausar() da lógica do relógio.
  Torneio copyWith({
    Estrutura? estrutura,
    Duration? decorridoAcumulado,
    DateTime? rodandoDesde,
  }) {
    return Torneio(
      estrutura: estrutura ?? this.estrutura,
      decorridoAcumulado: decorridoAcumulado ?? this.decorridoAcumulado,
      rodandoDesde: rodandoDesde ?? this.rodandoDesde,
    );
  }

  // Instante absoluto em ms desde a época: não depende do fuso do aparelho.
  Map<String, dynamic> toJson() {
    return {
      'estrutura': estrutura.toJson(),
      'decorridoAcumuladoMs': decorridoAcumulado.inMilliseconds,
      'rodandoDesdeMs': rodandoDesde?.millisecondsSinceEpoch,
    };
  }

  factory Torneio.fromJson(Map<String, dynamic> json) {
    final rodandoDesdeMs = json['rodandoDesdeMs'] as int?;
    return Torneio(
      estrutura: Estrutura.fromJson(json['estrutura'] as Map<String, dynamic>),
      decorridoAcumulado: Duration(
        milliseconds: json['decorridoAcumuladoMs'] as int,
      ),
      rodandoDesde: rodandoDesdeMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(rodandoDesdeMs),
    );
  }
}
