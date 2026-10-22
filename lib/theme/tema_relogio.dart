// Tema do Relógio de Poker: dois modos (alto contraste e mesa de cassino).
// Fonte: Inter (empacotada em assets/fonts, declarada no pubspec como "Inter").
// Todos os números usam algarismos tabulares: TiposRelogio.numeros.

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

enum ModoRelogio { altoContraste, mesaCassino }

@immutable
class CoresRelogio {
  const CoresRelogio({
    required this.fundo,
    required this.fundoLateral,
    required this.bordaLateral,
    required this.fundoUltimoMinuto,
    required this.superficie,
    required this.superficieAlta,
    required this.linha,
    required this.texto,
    required this.textoSecundario,
    required this.textoProximo,
    required this.destaque,
    required this.pausado,
    required this.ultimoMinuto,
    required this.intervalo,
    required this.fundoIntervalo,
    required this.primaria,
    required this.naPrimaria,
    required this.controles,
    required this.bordaControle,
    required this.playBorda,
    required this.playIcone,
    required this.bordaFicha,
  });

  final Color fundo; // área principal
  final Color fundoLateral; // coluna de fichas + play
  final Color bordaLateral; // filete da coluna (2 dp)
  final Color fundoUltimoMinuto; // fundo com <= 60 s (fade com `fundo`)
  final Color superficie; // cards, fundo do play rodando
  final Color superficieAlta; // diálogos, campos
  final Color linha; // divisórias
  final Color texto; // tempo, textos principais
  final Color textoSecundario; // ante, rótulos
  final Color textoProximo; // valores do próximo nível
  final Color destaque; // nível, blinds, rótulo FICHAS
  final Color pausado; // tempo pausado / fim da estrutura
  final Color ultimoMinuto; // tempo <= 60 s; ações de perigo
  final Color intervalo; // INTERVALO
  final Color fundoIntervalo; // linha de intervalo no editor
  final Color primaria; // selo, play pausado, botões preenchidos
  final Color naPrimaria; // texto/ícone sobre `primaria`
  final Color controles; // ícones dos controles secundários
  final Color bordaControle; // contorno dos controles
  final Color playBorda; // contorno do play rodando
  final Color playIcone; // ícone/texto do play rodando
  final Color bordaFicha; // anel externo da bolinha

  static const Color tracejadoFichaClara = Color(0x59000000); // preto 35%
  static const Color tracejadoFichaEscura = Color(0xBFFFFFFF); // branco 75%
  static const Color scrim = Color(0xB3000000); // preto 70%

  static const altoContraste = CoresRelogio(
    fundo: Color(0xFF0B0B0D),
    fundoLateral: Color(0xFF131417),
    bordaLateral: Color(0xFF1E1F23),
    fundoUltimoMinuto: Color(0xFF240E0D),
    superficie: Color(0xFF17181B),
    superficieAlta: Color(0xFF1F2024),
    linha: Color(0xFF24252A),
    texto: Color(0xFFEDEAE3),
    textoSecundario: Color(0xFF9A978F),
    textoProximo: Color(0xFFD6D3CB),
    destaque: Color(0xFFEDEAE3),
    pausado: Color(0xFF6A6863),
    ultimoMinuto: Color(0xFFFF5A4E),
    intervalo: Color(0xFF7CC4FF),
    fundoIntervalo: Color(0xFF121A22),
    primaria: Color(0xFFF5C451),
    naPrimaria: Color(0xFF0B0B0D),
    controles: Color(0xFF75736D),
    bordaControle: Color(0xFF26272C),
    playBorda: Color(0xFF3A3B41),
    playIcone: Color(0xFFBDBAB2),
    bordaFicha: Color(0xFF5C5D63),
  );

  static const mesaCassino = CoresRelogio(
    fundo: Color(0xFF0E2A21),
    fundoLateral: Color(0xFF0A211A),
    bordaLateral: Color(0xFF5E5232),
    fundoUltimoMinuto: Color(0xFF3A1714),
    superficie: Color(0xFF12352A),
    superficieAlta: Color(0xFF184236),
    linha: Color(0xFF234B3D),
    texto: Color(0xFFF1EBDD),
    textoSecundario: Color(0xFFA9BBB0),
    textoProximo: Color(0xFFE4DCCB),
    destaque: Color(0xFFD9B86C),
    pausado: Color(0xFF6E8A7D),
    ultimoMinuto: Color(0xFFFF6B5B),
    intervalo: Color(0xFF9FD3EA),
    fundoIntervalo: Color(0xFF123A3A),
    primaria: Color(0xFFD9B86C),
    naPrimaria: Color(0xFF0E2A21),
    controles: Color(0xFF7F9A8C),
    bordaControle: Color(0xFF2C5446),
    playBorda: Color(0xFF8C7A4C),
    playIcone: Color(0xFFD9B86C),
    bordaFicha: Color(0xFF8C7A4C),
  );

  static CoresRelogio de(ModoRelogio modo) =>
      modo == ModoRelogio.mesaCassino ? mesaCassino : altoContraste;

  /// Cor do tracejado interno da bolinha, conforme a cor escolhida pelo usuário.
  static Color tracejadoPara(Color corFicha) =>
      corFicha.computeLuminance() > 0.3 ? tracejadoFichaClara : tracejadoFichaEscura;
}

class TiposRelogio {
  TiposRelogio._();

  static const String fonte = 'Inter';
  static const List<FontFeature> numeros = [FontFeature.tabularFigures()];

  // Tela principal
  static const double tempo = 300; // w800, height 1, letterSpacing -0.02em
  static const double tempoLongo = 232; // h:mm:ss
  static const double blinds = 116; // w700, -0.01em
  static const double blindsLongo = 104; // > 13 caracteres (use FittedBox.scaleDown)
  static const double intervaloTitulo = 104; // w800, +0.12em
  static const double ante = 44; // w600, +0.06em
  static const double nivel = 36; // w800, +0.08em
  static const double proximo = 30; // rótulo w500, valores w600
  static const double intervaloEm = 30; // rótulo w500, tempo w700
  static const double selo = 28; // w800, +0.10em
  static const double ficha = 38; // w700
  static const double rotuloFichas = 18; // w600, +0.16em
  static const double playTexto = 20; // w800, +0.14em
  static const double icone = 30;
  static const double iconePlay = 76;
  static const double iconeSelo = 32;

  // Telas secundárias
  static const double tituloTela = 32; // w700
  static const double itemLista = 24; // w600
  static const double subtexto = 18; // w500
  static const double botao = 20; // w700
  static const double dialogoTitulo = 34; // w700
  static const double dialogoTexto = 24; // w500

  /// Converte o espaçamento em "em" do design para o letterSpacing do Flutter.
  static double em(double tamanho, double fator) => tamanho * fator;

  static TextStyle numero(double tamanho, FontWeight peso, Color cor, {double espacoEm = 0}) =>
      TextStyle(
        fontFamily: fonte,
        fontSize: tamanho,
        fontWeight: peso,
        color: cor,
        height: 1,
        letterSpacing: em(tamanho, espacoEm),
        fontFeatures: numeros,
      );
}

class EspacosRelogio {
  EspacosRelogio._();

  static const double margemTopo = 36;
  static const double margemLados = 56;
  static const double margemBase = 24;
  static const double larguraLateral = 232;
  static const double paddingLateralTopo = 40;
  static const double paddingLateral = 28; // lados e base
  static const double gapFichas = 30;
  static const double bolinhaFicha = 50; // anel 2, recuo 5, tracejado 3
  static const double alturaTopo = 52;
  static const double alturaTempo = 280; // caixa fixa
  static const double alturaBlinds = 124; // caixa fixa
  static const double alturaAnte = 60; // caixa fixa (vazia sem ante)
  static const double alturaProximo = 40; // + 16 acima (filete)
  static const double botaoControle = 60;
  static const double gapControles = 12;
  static const double larguraPlay = 176;
  static const double alturaPlay = 148;
  static const double alturaSelo = 52;
}

class RaiosRelogio {
  RaiosRelogio._();

  static const double controle = 16;
  static const double play = 24;
  static const double card = 20;
  static const double dialogo = 28;
  static const double campo = 14;
  static const double pilula = 999;
}

class DuracoesRelogio {
  DuracoesRelogio._();

  /// Fade de ida e volta entre `fundo` e `fundoUltimoMinuto` (AnimatedContainer).
  static const Duration pulsoUltimoMinuto = Duration(milliseconds: 1500);

  /// Troca de cor ao pausar, entrar em intervalo etc. (AnimatedDefaultTextStyle).
  static const Duration troca = Duration(milliseconds: 200);
}

/// Tema Material 3 das telas secundárias (configurações, editores, diálogos).
ThemeData temaRelogio(ModoRelogio modo) {
  final c = CoresRelogio.de(modo);
  final esquema = ColorScheme(
    brightness: Brightness.dark,
    primary: c.primaria,
    onPrimary: c.naPrimaria,
    secondary: c.destaque,
    onSecondary: c.naPrimaria,
    tertiary: c.intervalo,
    onTertiary: c.fundo,
    error: c.ultimoMinuto,
    onError: c.fundo,
    surface: c.fundo,
    onSurface: c.texto,
    onSurfaceVariant: c.textoSecundario,
    surfaceContainerLow: c.fundoLateral,
    surfaceContainer: c.superficie,
    surfaceContainerHigh: c.superficieAlta,
    surfaceContainerHighest: c.superficieAlta,
    outline: c.bordaControle,
    outlineVariant: c.linha,
    scrim: CoresRelogio.scrim,
  );

  const pilula = StadiumBorder();
  const textoBotao = TextStyle(
    fontFamily: TiposRelogio.fonte,
    fontSize: TiposRelogio.botao,
    fontWeight: FontWeight.w700,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: TiposRelogio.fonte,
    scaffoldBackgroundColor: c.fundo,
    dividerColor: c.linha,
    iconTheme: IconThemeData(color: c.controles, size: TiposRelogio.icone),
    appBarTheme: AppBarTheme(
      backgroundColor: c.fundo,
      foregroundColor: c.texto,
      toolbarHeight: 96,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: TiposRelogio.fonte,
        fontSize: TiposRelogio.tituloTela,
        fontWeight: FontWeight.w700,
        color: c.texto,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaiosRelogio.card)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      iconColor: c.destaque,
      titleTextStyle: TextStyle(
        fontFamily: TiposRelogio.fonte,
        fontSize: TiposRelogio.itemLista,
        fontWeight: FontWeight.w600,
        color: c.texto,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: TiposRelogio.fonte,
        fontSize: TiposRelogio.subtexto,
        fontWeight: FontWeight.w500,
        color: c.textoSecundario,
        fontFeatures: TiposRelogio.numeros,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primaria,
        foregroundColor: c.naPrimaria,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: pilula,
        textStyle: textoBotao,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.texto,
        side: BorderSide(color: c.bordaControle, width: 2),
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 26),
        shape: pilula,
        textStyle: textoBotao,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.texto,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: pilula,
        textStyle: textoBotao,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: c.primaria,
      checkmarkColor: c.naPrimaria,
      side: BorderSide(color: c.bordaControle, width: 2),
      shape: pilula,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      labelStyle: textoBotao.copyWith(color: c.texto),
      secondaryLabelStyle: textoBotao.copyWith(color: c.naPrimaria),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: c.primaria,
        selectedForegroundColor: c.naPrimaria,
        foregroundColor: c.texto,
        side: BorderSide(color: c.bordaControle, width: 2),
        minimumSize: const Size(0, 64),
        textStyle: textoBotao,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.fundo,
      labelStyle: TextStyle(color: c.textoSecundario, fontSize: 16, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaiosRelogio.campo),
        borderSide: BorderSide(color: c.bordaControle, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaiosRelogio.campo),
        borderSide: BorderSide(color: c.primaria, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.superficieAlta,
      barrierColor: CoresRelogio.scrim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaiosRelogio.dialogo)),
      titleTextStyle: TextStyle(
        fontFamily: TiposRelogio.fonte,
        fontSize: TiposRelogio.dialogoTitulo,
        fontWeight: FontWeight.w700,
        color: c.texto,
      ),
      contentTextStyle: TextStyle(
        fontFamily: TiposRelogio.fonte,
        fontSize: TiposRelogio.dialogoTexto,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: c.textoSecundario,
      ),
    ),
  );
}
