import 'package:flutter/material.dart';

// Cores e tamanhos do app num só lugar: o design final troca só este arquivo.
abstract final class Tema {
  static const fundo = Color(0xFF0B0F0E);
  static const fundoLateral = Color(0xFF141A18);
  static const texto = Color(0xFFFFFFFF);
  static const textoSecundario = Color(0xFF8F9A96);
  static const pausado = Color(0xFF5E6865);
  static const ultimoMinuto = Color(0xFFFF5252);
  static const intervalo = Color(0xFF4FC3F7);
  static const controles = Color(0x8AFFFFFF);
  static const bordaFicha = Color(0x66FFFFFF);

  static const tamanhoNivel = 40.0;
  static const tamanhoBlinds = 110.0;
  static const tamanhoAnte = 48.0;
  static const tamanhoProximo = 36.0;
  static const tamanhoIntervalo = 28.0;
  static const tamanhoFicha = 30.0;
  static const diametroFicha = 44.0;
  static const larguraLateral = 220.0;
  static const tamanhoIcone = 44.0;
  static const tamanhoIconePrincipal = 72.0;

  static final tema = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: fundo,
    colorScheme: const ColorScheme.dark(surface: fundoLateral),
  );

  // Algarismos de largura fixa: o relógio não "treme" quando os dígitos mudam.
  static const algarismosFixos = [FontFeature.tabularFigures()];
}
