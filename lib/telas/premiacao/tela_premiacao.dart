import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../logica/premiacao.dart';
import '../../logica/validacao.dart';
import '../../modelos/premiacao.dart';
import '../../theme/tema_relogio.dart';
import '../componentes.dart';
import 'premiacao_notifier.dart';

// Editor da premiação (ESPECIFICACAO 5.5). Rascunho local: nada é salvo até tocar
// em Salvar, porque os campos dependem uns dos outros (a soma passa por valores
// errados enquanto se digita).
class TelaPremiacao extends ConsumerStatefulWidget {
  const TelaPremiacao({super.key});

  @override
  ConsumerState<TelaPremiacao> createState() => _TelaPremiacaoState();
}

class _TelaPremiacaoState extends ConsumerState<TelaPremiacao> {
  final _form = GlobalKey<FormState>();
  late final _salva = ref.read(premiacaoProvider);
  late final _total = _controle(_salva == null ? '' : '${_salva.total}');
  late var _tipo = _salva?.tipo ?? TipoDivisao.porcentagem;
  late final _valores = [
    for (final valor in _salva?.valores ?? const [50, 30, 20])
      _controle('$valor'),
  ];
  late final String _inicial;

  TextEditingController _controle(String texto) =>
      TextEditingController(text: texto)..addListener(() => setState(() {}));

  // O listener também dispara quando só o cursor muda; comparar o texto evita
  // pedir confirmação ao sair sem ter mudado nada.
  String _assinatura() =>
      '${_total.text}|${_tipo.name}|${_valores.map((c) => c.text).join(',')}';

  @override
  void initState() {
    super.initState();
    _inicial = _assinatura();
  }

  @override
  void dispose() {
    _total.dispose();
    for (final valor in _valores) {
      valor.dispose();
    }
    super.dispose();
  }

  // null enquanto algum campo não for um número.
  Premiacao? _rascunho() {
    final total = int.tryParse(_total.text.trim());
    final valores = [for (final c in _valores) int.tryParse(c.text.trim())];
    if (total == null || valores.contains(null)) return null;
    return Premiacao(
      total: total,
      tipo: _tipo,
      valores: [for (final valor in valores) valor!],
      jackpot: _salva?.jackpot ?? 0,
    );
  }

  void _mudarPremiados(int quantidade) {
    setState(() {
      while (_valores.length < quantidade) {
        _valores.add(_controle(''));
      }
      while (_valores.length > quantidade) {
        _valores.removeLast().dispose();
      }
    });
  }

  // Converte os valores para o novo tipo quando a premiação atual é válida;
  // senão, mantém o que foi digitado para o usuário corrigir.
  void _mudarTipo(TipoDivisao tipo) {
    if (tipo == _tipo) return;
    final rascunho = _rascunho();
    if (rascunho != null && validarPremiacao(rascunho) == null) {
      final convertidos = tipo == TipoDivisao.fixo
          ? calcularPremios(rascunho)
          : converterParaPorcentagem(rascunho.total, rascunho.valores);
      for (final (i, valor) in convertidos.indexed) {
        _valores[i].text = '$valor';
      }
    }
    setState(() => _tipo = tipo);
  }

  void _salvar() {
    final rascunho = _rascunho();
    if (!_form.currentState!.validate() ||
        rascunho == null ||
        validarPremiacao(rascunho) != null) {
      return;
    }
    ref.read(premiacaoProvider.notifier).salvar(rascunho);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Premiação salva.')));
    Navigator.pop(context);
  }

  Future<void> _remover() async {
    if (await confirmar(
          context,
          icone: Icons.delete_outline,
          titulo: 'Remover a premiação?',
          texto: 'Os prêmios deixam de aparecer na tela do relógio.',
          botaoConfirmar: 'Remover',
          isPerigo: true,
        ) &&
        mounted) {
      ref.read(premiacaoProvider.notifier).remover();
      Navigator.pop(context);
    }
  }

  Future<void> _sairSemSalvar() async {
    if (await confirmar(
          context,
          icone: Icons.undo,
          titulo: 'Sair sem salvar?',
          texto: 'As alterações na premiação serão perdidas.',
          botaoConfirmar: 'Sair',
          isPerigo: true,
        ) &&
        mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final estiloRotulo = TextStyle(
      fontSize: TiposRelogio.rotuloCampo,
      fontWeight: FontWeight.w600,
      letterSpacing: TiposRelogio.em(TiposRelogio.rotuloCampo, 0.10),
      color: esquema.onSurfaceVariant,
    );
    final isPorcentagem = _tipo == TipoDivisao.porcentagem;
    final rascunho = _rascunho();
    final premios = rascunho == null ? null : calcularPremios(rascunho);
    final erro = rascunho == null ? null : validarPremiacao(rascunho);
    final soma = rascunho == null ? null : somar(rascunho.valores);

    return PopScope(
      canPop: _assinatura() == _inicial,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sairSemSalvar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Premiação'),
          actions: [
            if (_salva != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover premiação',
                onPressed: _remover,
              ),
            const SizedBox(width: EspacosRelogio.gapPequeno),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
            const SizedBox(width: EspacosRelogio.margemTabela),
          ],
        ),
        body: ConteudoCentralizado(
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: EspacosRelogio.margemTabela,
              ),
              children: [
                _Cartao(
                  children: [
                    SizedBox(
                      width: EspacosRelogio.larguraCampoPremio,
                      child: CampoRotulado(
                        rotulo: 'Total da premiação',
                        controle: _total,
                        validar: (texto) => validarInteiro(texto, minimo: 1),
                      ),
                    ),
                    Text('DIVISÃO', style: estiloRotulo),
                    Row(
                      spacing: EspacosRelogio.gapMedio,
                      children: [
                        for (final (tipo, icone, rotulo) in const [
                          (
                            TipoDivisao.porcentagem,
                            Icons.percent_outlined,
                            'Porcentagem',
                          ),
                          (
                            TipoDivisao.fixo,
                            Icons.payments_outlined,
                            'Valor fixo',
                          ),
                        ])
                          Expanded(
                            child: BotaoOpcao(
                              icone: icone,
                              rotulo: rotulo,
                              isSelecionado: _tipo == tipo,
                              aoTocar: () => _mudarTipo(tipo),
                            ),
                          ),
                      ],
                    ),
                    Text('PREMIADOS', style: estiloRotulo),
                    Wrap(
                      spacing: EspacosRelogio.gapMedio,
                      runSpacing: EspacosRelogio.gapPequeno,
                      children: [
                        for (var n = 1; n <= Premiacao.maximoPremiados; n++)
                          SizedBox(
                            height: EspacosRelogio.alturaChip,
                            child: ChoiceChip(
                              label: Text('$n'),
                              selected: _valores.length == n,
                              onSelected: (_) => _mudarPremiados(n),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: EspacosRelogio.gapCards),
                _Cartao(
                  children: [
                    Wrap(
                      spacing: EspacosRelogio.gapGrande,
                      runSpacing: EspacosRelogio.gapGrande,
                      children: [
                        for (final (i, valor) in _valores.indexed)
                          SizedBox(
                            width: EspacosRelogio.larguraCampoPremio,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: EspacosRelogio.gapPequeno,
                              children: [
                                CampoRotulado(
                                  rotulo: isPorcentagem
                                      ? '${i + 1}º lugar (%)'
                                      : '${i + 1}º lugar',
                                  controle: valor,
                                  validar: (texto) =>
                                      validarInteiro(texto, minimo: 1),
                                ),
                                // Em porcentagem, o valor que a posição leva.
                                if (isPorcentagem)
                                  Text(
                                    premios == null
                                        ? ''
                                        : '= ${formatarValor(premios[i])}',
                                    style: TextStyle(
                                      fontSize: TiposRelogio.subtexto,
                                      fontWeight: FontWeight.w500,
                                      color: esquema.onSurfaceVariant,
                                      fontFeatures: TiposRelogio.numeros,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (soma != null)
                      Text(
                        erro ??
                            (isPorcentagem
                                ? 'Soma $soma%.'
                                : 'Soma ${formatarValor(soma)}.'),
                        style: TextStyle(
                          fontSize: TiposRelogio.subtexto,
                          fontWeight: FontWeight.w600,
                          color: erro == null
                              ? esquema.onSurfaceVariant
                              : esquema.error,
                          fontFeatures: TiposRelogio.numeros,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacosRelogio.paddingCardHorizontal,
          vertical: EspacosRelogio.paddingCardVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EspacosRelogio.gapGrande,
          children: children,
        ),
      ),
    );
  }
}
