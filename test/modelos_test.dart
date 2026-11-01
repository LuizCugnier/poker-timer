import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_timer/modelos/configuracao.dart';
import 'package:poker_timer/modelos/estrutura.dart';
import 'package:poker_timer/modelos/ficha.dart';
import 'package:poker_timer/modelos/nivel.dart';
import 'package:poker_timer/modelos/torneio.dart';

Map<String, dynamic> idaEVolta(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('Nivel', () {
    test('ida e volta pelo JSON', () {
      const original = Nivel(
        smallBlind: 100,
        bigBlind: 200,
        ante: 25,
        duracao: Duration(minutes: 15, seconds: 30),
      );
      final copia = Nivel.fromJson(idaEVolta(original.toJson()));

      expect(copia.smallBlind, 100);
      expect(copia.bigBlind, 200);
      expect(copia.ante, 25);
      expect(copia.duracao, const Duration(minutes: 15, seconds: 30));
      expect(copia.isIntervalo, isFalse);
    });

    test('intervalo ida e volta pelo JSON', () {
      const original = Nivel.intervalo(Duration(minutes: 10));
      final copia = Nivel.fromJson(idaEVolta(original.toJson()));

      expect(copia.isIntervalo, isTrue);
      expect(copia.duracao, const Duration(minutes: 10));
    });

    test('copyWith troca só o campo informado', () {
      const original = Nivel(
        smallBlind: 100,
        bigBlind: 200,
        ante: 25,
        duracao: Duration(minutes: 15),
      );
      final copia = original.copyWith(bigBlind: 400);

      expect(copia.bigBlind, 400);
      expect(copia.smallBlind, 100);
      expect(copia.ante, 25);
      expect(copia.duracao, const Duration(minutes: 15));
      expect(copia.isIntervalo, isFalse);
    });
  });

  group('Estrutura', () {
    const estrutura = Estrutura(
      nome: 'Rápida',
      niveis: [
        Nivel(smallBlind: 25, bigBlind: 50, duracao: Duration(minutes: 10)),
        Nivel.intervalo(Duration(minutes: 5)),
      ],
    );

    test('ida e volta pelo JSON', () {
      final copia = Estrutura.fromJson(idaEVolta(estrutura.toJson()));

      expect(copia.nome, 'Rápida');
      expect(copia.niveis, hasLength(2));
      expect(copia.niveis[0].bigBlind, 50);
      expect(copia.niveis[1].isIntervalo, isTrue);
    });

    test('copyWith troca só o campo informado', () {
      final copia = estrutura.copyWith(nome: 'Turbo');

      expect(copia.nome, 'Turbo');
      expect(copia.niveis, hasLength(2));
    });

    test('estrutura padrão é coerente', () {
      final niveis = Estrutura.padrao.niveis;
      expect(niveis, isNotEmpty);
      expect(niveis.first.isIntervalo, isFalse);
      expect(niveis.last.isIntervalo, isFalse);

      final jogo = niveis.where((n) => !n.isIntervalo).toList();
      for (var i = 1; i < jogo.length; i++) {
        expect(jogo[i].bigBlind, greaterThan(jogo[i - 1].bigBlind));
      }
      for (final n in niveis) {
        expect(n.duracao, greaterThan(Duration.zero));
      }
    });
  });

  group('Ficha', () {
    const ficha = Ficha(valor: 500, cor: 0xFF388E3C, rotulo: 'Verde');

    test('ida e volta pelo JSON', () {
      final copia = Ficha.fromJson(idaEVolta(ficha.toJson()));

      expect(copia.valor, 500);
      expect(copia.cor, 0xFF388E3C);
      expect(copia.rotulo, 'Verde');
    });

    test('copyWith troca só o campo informado', () {
      final copia = ficha.copyWith(valor: 1000);

      expect(copia.valor, 1000);
      expect(copia.cor, 0xFF388E3C);
      expect(copia.rotulo, 'Verde');
    });

    test('fichas padrão têm valores crescentes', () {
      for (var i = 1; i < fichasPadrao.length; i++) {
        expect(fichasPadrao[i].valor, greaterThan(fichasPadrao[i - 1].valor));
      }
    });
  });

  group('Torneio', () {
    const estrutura = Estrutura(
      nome: 'Rápida',
      niveis: [
        Nivel(smallBlind: 25, bigBlind: 50, duracao: Duration(minutes: 10)),
      ],
    );
    final inicio = DateTime(2026, 10, 21, 20, 30);

    test('pausado ida e volta pelo JSON', () {
      const original = Torneio(
        estrutura: estrutura,
        decorridoAcumulado: Duration(minutes: 3, seconds: 20),
      );
      final copia = Torneio.fromJson(idaEVolta(original.toJson()));

      expect(copia.estrutura.nome, 'Rápida');
      expect(copia.estrutura.niveis, hasLength(1));
      expect(copia.decorridoAcumulado, const Duration(minutes: 3, seconds: 20));
      expect(copia.rodandoDesde, isNull);
      expect(copia.isRodando, isFalse);
    });

    test('rodando ida e volta pelo JSON', () {
      final original = Torneio(
        estrutura: estrutura,
        decorridoAcumulado: const Duration(minutes: 3),
        rodandoDesde: inicio,
      );
      final copia = Torneio.fromJson(idaEVolta(original.toJson()));

      expect(copia.rodandoDesde, inicio);
      expect(copia.isRodando, isTrue);
    });

    test('copyWith troca só o campo informado', () {
      final original = Torneio(
        estrutura: estrutura,
        decorridoAcumulado: const Duration(minutes: 3),
        rodandoDesde: inicio,
      );
      final copia = original.copyWith(
        decorridoAcumulado: const Duration(minutes: 7),
      );

      expect(copia.decorridoAcumulado, const Duration(minutes: 7));
      expect(copia.rodandoDesde, inicio);
      expect(copia.estrutura.nome, 'Rápida');
    });
  });

  group('Configuracao', () {
    test('padrão avisa 1 minuto antes', () {
      expect(const Configuracao().antecedencias, [const Duration(minutes: 1)]);
    });

    test('ida e volta pelo JSON', () {
      const original = Configuracao(avisosMinutos: [1, 5, 10]);
      final copia = Configuracao.fromJson(idaEVolta(original.toJson()));
      expect(copia.avisosMinutos, [1, 5, 10]);
    });

    test('aviso na metade vai e volta pelo JSON', () {
      const original = Configuracao(isAvisoMetade: true);
      final copia = Configuracao.fromJson(idaEVolta(original.toJson()));
      expect(copia.isAvisoMetade, isTrue);
    });

    test(
      'configuração salva antes do aviso na metade abre com ele desligado',
      () {
        final copia = Configuracao.fromJson({
          'avisosMinutos': [1],
        });
        expect(copia.isAvisoMetade, isFalse);
      },
    );

    test('time bank vai e volta pelo JSON em segundos', () {
      const original = Configuracao(timeBank: Duration(seconds: 45));
      final json = idaEVolta(original.toJson());
      expect(json['timeBank'], 45);
      expect(Configuracao.fromJson(json).timeBank, const Duration(seconds: 45));
    });

    test('configuração salva antes do time bank abre com 30 s', () {
      final copia = Configuracao.fromJson({
        'avisosMinutos': [1],
      });
      expect(copia.timeBank, const Duration(seconds: 30));
    });

    test('sem avisos também é válido', () {
      const original = Configuracao(avisosMinutos: []);
      final copia = Configuracao.fromJson(idaEVolta(original.toJson()));
      expect(copia.antecedencias, isEmpty);
    });
  });
}
