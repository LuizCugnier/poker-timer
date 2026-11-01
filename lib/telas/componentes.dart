import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tema_relogio.dart';
import 'configuracoes/configuracao_notifier.dart';

// Diálogo de confirmação (ESPECIFICACAO 5.4). Trechos entre **asteriscos** no texto
// saem destacados (valores do nível, por exemplo).
Future<bool> confirmar(
  BuildContext context, {
  required IconData icone,
  required String titulo,
  required String texto,
  String botaoConfirmar = 'Confirmar',
  String botaoCancelar = 'Cancelar',
  bool isPerigo = false,
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (context) {
      final esquema = Theme.of(context).colorScheme;
      final estiloTexto = Theme.of(context).dialogTheme.contentTextStyle;
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: EspacosRelogio.larguraDialogo,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              EspacosRelogio.paddingDialogo,
              EspacosRelogio.paddingDialogo,
              EspacosRelogio.paddingDialogo,
              EspacosRelogio.paddingDialogoBase,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: EspacosRelogio.circuloIconeDialogo,
                  height: EspacosRelogio.circuloIconeDialogo,
                  decoration: BoxDecoration(
                    color: esquema.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icone,
                    size: TiposRelogio.iconeDialogo,
                    color: esquema.primary,
                  ),
                ),
                const SizedBox(height: EspacosRelogio.gapGrande),
                Text(
                  titulo,
                  style: Theme.of(context).dialogTheme.titleTextStyle,
                ),
                const SizedBox(height: EspacosRelogio.gapMedio),
                // Texto longo (como o da permissão) rola em vez de estourar o diálogo.
                Flexible(
                  child: SingleChildScrollView(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          for (final (i, trecho) in texto.split('**').indexed)
                            TextSpan(
                              text: trecho,
                              style: i.isOdd
                                  ? TextStyle(
                                      color: esquema.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: TiposRelogio.numeros,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      style: estiloTexto,
                    ),
                  ),
                ),
                const SizedBox(height: EspacosRelogio.paddingDialogoBase),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            EspacosRelogio.alturaBotaoDialogo,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(botaoCancelar),
                      ),
                    ),
                    const SizedBox(width: EspacosRelogio.gapMedio),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            EspacosRelogio.alturaBotaoDialogo,
                          ),
                          backgroundColor: isPerigo ? esquema.error : null,
                          foregroundColor: isPerigo ? esquema.onError : null,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(botaoConfirmar),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return resposta == true && context.mounted;
}

// Campo com o rótulo em maiúsculas acima (editores de nível e de ficha).
class CampoRotulado extends StatelessWidget {
  const CampoRotulado({
    super.key,
    required this.rotulo,
    required this.controle,
    this.validar,
    this.isNumero = true,
    this.autofocus = false,
    this.isHabilitado = true,
  });

  final String rotulo;
  final TextEditingController controle;
  final FormFieldValidator<String>? validar;
  final bool isNumero;
  final bool autofocus;
  // Desabilitado: mostra o valor, apagado, sem deixar editar.
  final bool isHabilitado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            fontSize: TiposRelogio.rotuloCampo,
            fontWeight: FontWeight.w600,
            letterSpacing: TiposRelogio.em(TiposRelogio.rotuloCampo, 0.10),
            color: esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EspacosRelogio.gapPequeno),
        TextFormField(
          controller: controle,
          autofocus: autofocus,
          enabled: isHabilitado,
          keyboardType: isNumero ? TextInputType.number : TextInputType.text,
          style: TextStyle(
            fontSize: TiposRelogio.campo,
            fontWeight: FontWeight.w600,
            color: isHabilitado ? esquema.onSurface : esquema.onSurfaceVariant,
            fontFeatures: TiposRelogio.numeros,
          ),
          validator: validar,
        ),
      ],
    );
  }
}

// Opção de uma escolha (modo de exibição, tipo de divisão): preenchida quando
// escolhida, contornada quando não.
class BotaoOpcao extends StatelessWidget {
  const BotaoOpcao({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.isSelecionado,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final bool isSelecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    const tamanho = Size.fromHeight(EspacosRelogio.alturaSegmento);
    return isSelecionado
        ? FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: tamanho),
            onPressed: aoTocar,
            icon: Icon(icone),
            label: Text(rotulo),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: tamanho),
            onPressed: aoTocar,
            icon: Icon(icone),
            label: Text(rotulo),
          );
  }
}

// Conteúdo das telas secundárias: centralizado, com no máximo 880 de largura.
class ConteudoCentralizado extends StatelessWidget {
  const ConteudoCentralizado({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: EspacosRelogio.larguraConteudo,
        ),
        child: child,
      ),
    );
  }
}

// Bolinha da ficha: anel externo, cor escolhida e, por padrão, o tracejado interno.
class BolinhaFicha extends ConsumerWidget {
  const BolinhaFicha({
    super.key,
    required this.cor,
    this.tamanho = EspacosRelogio.bolinhaFicha,
    this.isTracejada = true,
  });

  final int cor;
  final double tamanho;
  final bool isTracejada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corFicha = Color(cor);
    return SizedBox.square(
      dimension: tamanho,
      child: CustomPaint(
        painter: _PintorBolinha(
          cor: corFicha,
          anel: ref.watch(coresProvider).bordaFicha,
          tracejado: isTracejada ? CoresRelogio.tracejadoPara(corFicha) : null,
        ),
      ),
    );
  }
}

class _PintorBolinha extends CustomPainter {
  _PintorBolinha({required this.cor, required this.anel, this.tracejado});

  final Color cor;
  final Color anel;
  final Color? tracejado;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.shortestSide / 2;
    canvas.drawCircle(centro, raio, Paint()..color = cor);
    canvas.drawCircle(
      centro,
      raio - EspacosRelogio.anelFicha / 2,
      Paint()
        ..color = anel
        ..style = PaintingStyle.stroke
        ..strokeWidth = EspacosRelogio.anelFicha,
    );

    final corTracejado = tracejado;
    if (corTracejado == null) return;
    final raioTracejado =
        raio -
        EspacosRelogio.anelFicha -
        EspacosRelogio.recuoTracejado -
        EspacosRelogio.tracejado / 2;
    final circunferencia = 2 * math.pi * raioTracejado;
    final tracos =
        (circunferencia /
                (EspacosRelogio.tracoTracejado + EspacosRelogio.vaoTracejado))
            .floor();
    final passo = 2 * math.pi / tracos;
    final arco =
        passo *
        EspacosRelogio.tracoTracejado /
        (EspacosRelogio.tracoTracejado + EspacosRelogio.vaoTracejado);
    final pincel = Paint()
      ..color = corTracejado
      ..style = PaintingStyle.stroke
      ..strokeWidth = EspacosRelogio.tracejado;
    final area = Rect.fromCircle(center: centro, radius: raioTracejado);
    for (var i = 0; i < tracos; i++) {
      canvas.drawArc(area, i * passo, arco, false, pincel);
    }
  }

  @override
  bool shouldRepaint(_PintorBolinha antigo) =>
      antigo.cor != cor || antigo.anel != anel || antigo.tracejado != tracejado;
}
