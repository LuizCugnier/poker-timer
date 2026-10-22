import 'nivel.dart';

class Estrutura {
  const Estrutura({required this.nome, required this.niveis});

  final String nome;
  final List<Nivel> niveis;

  Estrutura copyWith({String? nome, List<Nivel>? niveis}) {
    return Estrutura(nome: nome ?? this.nome, niveis: niveis ?? this.niveis);
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'niveis': niveis.map((nivel) => nivel.toJson()).toList(),
    };
  }

  factory Estrutura.fromJson(Map<String, dynamic> json) {
    return Estrutura(
      nome: json['nome'] as String,
      niveis: (json['niveis'] as List)
          .map((nivel) => Nivel.fromJson(nivel as Map<String, dynamic>))
          .toList(),
    );
  }

  static const padrao = Estrutura(
    nome: 'Home game',
    niveis: [
      Nivel(smallBlind: 25, bigBlind: 50, duracao: Duration(minutes: 20)),
      Nivel(smallBlind: 50, bigBlind: 100, duracao: Duration(minutes: 20)),
      Nivel(smallBlind: 75, bigBlind: 150, duracao: Duration(minutes: 20)),
      Nivel(smallBlind: 100, bigBlind: 200, duracao: Duration(minutes: 20)),
      Nivel.intervalo(Duration(minutes: 10)),
      Nivel(smallBlind: 150, bigBlind: 300, duracao: Duration(minutes: 20)),
      Nivel(smallBlind: 200, bigBlind: 400, duracao: Duration(minutes: 20)),
      Nivel(smallBlind: 300, bigBlind: 600, duracao: Duration(minutes: 20)),
      Nivel(smallBlind: 400, bigBlind: 800, duracao: Duration(minutes: 20)),
      Nivel.intervalo(Duration(minutes: 10)),
      Nivel(
        smallBlind: 500,
        bigBlind: 1000,
        ante: 100,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 600,
        bigBlind: 1200,
        ante: 200,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 800,
        bigBlind: 1600,
        ante: 200,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 1000,
        bigBlind: 2000,
        ante: 300,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 1500,
        bigBlind: 3000,
        ante: 400,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 2000,
        bigBlind: 4000,
        ante: 500,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 3000,
        bigBlind: 6000,
        ante: 1000,
        duracao: Duration(minutes: 20),
      ),
      Nivel(
        smallBlind: 4000,
        bigBlind: 8000,
        ante: 1000,
        duracao: Duration(minutes: 20),
      ),
    ],
  );
}
